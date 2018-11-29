defmodule ExMachina do
  @behaviour :gen_statem

  @doc """
  Starts a gen_statem process that is linked to the calling process.
  Args:
  -fsm_object : Populated FSMCore object.
  -timeout : Maximum time remain on a state.
  Returns {:ok, pid, key}
  """
  def start_link(fsm_object, timeout) do
    :gen_statem.start_link({:global, fsm_object.name}, __MODULE__, [{fsm_object, timeout}], [])
  end

  @doc """
  Locate process by name
  Args:
  -key : Name used to find out if a process is registered in gproc.
  Returns:
  - :none : When process is found
  - pid value : When process is not found
  """
  def check_gproc(fsm_name)  do
    case :gproc.whereis_name({:n, :l, {:efsm, fsm_name}}) do
      :undefined ->
        :none
      pid ->
        pid
    end   
  end 

  # Callbacks
  @impl true
  def callback_mode do
    :handle_event_function
  end
  
  @impl true
  def code_change(_vsn, state, data, _extra) do
    {:ok, state, data}
  end

  def stop(fsm_name) do
    :gen_statem.stop(check_gproc(fsm_name))
  end

  @impl true
  def init([{fsm_object, timeout}]) do  
    apply(fsm_object.module_logic, fsm_object.initialization_function, [fsm_object.data])
      |> case do
           {:ok, data}-> #Update fsm state data
                         new_fsm_object = fsm_object |> Map.put(:data, data)
                         check_gproc(new_fsm_object.name)
                           |> case do 
                                :none -> :gproc.reg({:n, :l, {:efsm, new_fsm_object.name}})
                                _     -> IO.puts("FSM Already registered")
                              end  
                         {:ok, fsm_object.initial_state, new_fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}                
          _   -> IO.puts "Error initializing FSM"                      
                 {:error, fsm_object.initial_state, fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}
        end
  end

  @impl true
  def terminate(_reason, _state, _data) do
    :ok
  end
  
  def call(fsm_name, args) do
    check_gproc(fsm_name) |>
      :gen_statem.call(args)
  end

  def cast(fsm_name, args) do
    check_gproc(fsm_name) |>
      :gen_statem.cast(args)
  end

  @doc """
  Gets FSM process data
  """
  def handle_event({:call, from}, :get_data, state, fsm_object) do
    {:next_state, state, fsm_object, [{:reply, from, fsm_object.data}]}
  end

  @doc """
  Gets FSM process current state
  """
  def handle_event({:call, from}, :get_state, state, fsm_object) do
    {:next_state, state, fsm_object, [{:reply, from, state}]}
  end

  @doc """
  Info event handler
  """
  def handle_event(:info, info_data, state, fsm_object) do    
    apply(fsm_object.module_logic, fsm_object.info_handler, [fsm_object.data, info_data])
      |> case do
           {:ok, data} -> #Update fsm state data
                          {:next_state, state, fsm_object |> Map.put(:data, data), [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]} 
                                                         
            _ -> IO.puts "Error handling info event"
                 {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}             
    end    
  end

  @doc """
  Input event handler for the FSM process. 
  """
  @impl :gen_statem
  def handle_event(:cast, {:input_event, input_value}, state, fsm_object) do
    #Map input to fsm event
    {input_mapped_value, data} = apply(fsm_object.module_logic, fsm_object.input_maping_function, [state, input_value, fsm_object.data])
    
    #Update fsm state data
    fsm_object = fsm_object
                   |> Map.put(:data, data)

    #Determine what the next state is from the transition table                
    (for transition <- fsm_object.transition_table,((input_mapped_value == transition.input_value) && (state == transition.current_state)),do: {transition.next_state, transition.timeout})
      |> List.first
      |> case do
           nil        -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
           {next_state, timeout} -> {:next_state, next_state, fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}
         end    
  end

  @doc """
  Event Driven Timeout 
  On event driven FSM processes, this will be triggered when stayin on a state for too long (timeout).
  """
  def handle_event(:state_timeout, :stop_after_timeout, state, %FSMCore{type: :event_driven} = fsm_object) do
    # On state timeout apply function to re-initialize data
    fsm_object = apply(fsm_object.module_logic, fsm_object.reset_function, [fsm_object.data])
      |> case do
           {:ok, reset_data} ->  fsm_object |> Map.put(:data, reset_data)
                                   
           _ -> IO.puts("Error reinitializing data")
                fsm_object
         end  

    (for transition <- fsm_object.transition_table,((transition.on_event == :timeout) && (state == transition.current_state)),do: transition.next_state)
      |> List.first
      |> case do
           nil        -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
           next_state -> {:next_state, next_state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
         end  
  end

  @doc """
  Time Driven Timeout 
  This event will be triggered periodically and will make the FSM process transition to the next state at every :timeout
  """
  def handle_event(:state_timeout, :stop_after_timeout, state, %FSMCore{type: :time_driven} = fsm_object) do
    #Process current state
    apply(fsm_object.module_logic, fsm_object.state_process, [state, fsm_object.data])
      |> case do
           {:error, _data} -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
           {result_value, data} -> fsm_object = fsm_object |> Map.put(:data, data)

                          #Determine what the next state is from the transition table                
                          (for transition <- fsm_object.transition_table,((result_value == transition.process_result) && (state == transition.current_state)), do: {transition.next_state, transition.timeout})
                          |> List.first
                          |> case do
                              nil        -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
                              {next_state, timeout} -> {:next_state, next_state, fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}
                          end
                            
        end         
  end
end

