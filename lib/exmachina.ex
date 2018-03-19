defmodule ExMachina do
  @behaviour :gen_statem

  # Client API
  def start_link(fsm_object, timeout) do
    :gen_statem.start({:global, fsm_object.name}, __MODULE__, [{fsm_object, timeout}], [])
  end

  defp locate_process(key) do
    # Check for a client first...
    case :gproc.whereis_name({:n, :l, {:efsm, key}}) do
      :undefined ->
        {:none, nil, key}
      pid->
        {:ok, pid, key}
    end
  end

  def check_gproc(fsm_name)  do
    case locate_process(fsm_name) do
      {:none, nil, fsm_name} ->
        IO.puts "FSM not registered : #{fsm_name}"
          # Register it as running before kicking off the process!
          :gproc.reg({:n, :l, {:efsm, fsm_name}})
        {:ok, pid, _fsm_name} ->
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
                         {:ok, fsm_object.initial_state, new_fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}                
          _   -> IO.puts "Error initializing FSM"                      
                 {:error, fsm_object.initial_state, fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}
        end
  end

  @impl true
  def terminate(_reason, _state, data) do
    IO.puts("Terminate : #{data.name}")
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

  # ...
  ### Client API
  # ...
  def handle_event({:call, from}, :get_data, state, fsm_object) do
    {:next_state, state, fsm_object, [{:reply, from, fsm_object}]}
  end

  def handle_event({:call, from}, :get_state, state, fsm_object) do
    {:next_state, state, fsm_object, [{:reply, from, state}]}
  end

  def handle_event(:info, info_data, state, fsm_object) do    
    apply(fsm_object.module_logic, fsm_object.info_handler, [fsm_object.data, info_data])
      |> case do
           {:ok, data} -> #Update fsm state data
                          {:next_state, state, fsm_object |> Map.put(:data, data), [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]} 
                                                         
            _ -> IO.puts "Error handling info event"
                 {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}             
    end    
  end

  @impl :gen_statem
  def handle_event(:cast, {:input_event, input_value}, state, fsm_object) do
    #[1] Map input to fsm event
    {input_mapped_value, data} = apply(fsm_object.module_logic, fsm_object.input_maping_function, [state, input_value, fsm_object.data])
    
    #[2] Update fsm state data
    fsm_object = fsm_object
                   |> Map.put(:data, data)

    #[3] Determine what the next state is from the transition table                
    (for transition <- fsm_object.transition_table,((input_mapped_value == transition.input_value) && (state == transition.current_state)),do: {transition.next_state, transition.timeout})
      |> List.first
      |> case do
           nil        -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
           {next_state, timeout} -> {:next_state, next_state, fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}
         end    
  end

  # Event Driven Timeout
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

  # Time driven timeout
  def handle_event(:state_timeout, :stop_after_timeout, state, %FSMCore{type: :time_driven} = fsm_object) do
    #[1] Process current state
    apply(fsm_object.module_logic, fsm_object.state_process, [state, fsm_object.data])
      |> case do
           {:error, _data} -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
           {result_value, data} -> fsm_object = fsm_object |> Map.put(:data, data)

                          #[3] Determine what the next state is from the transition table                
                          (for transition <- fsm_object.transition_table,((result_value == transition.process_result) && (state == transition.current_state)), do: {transition.next_state, transition.timeout})
                          |> List.first
                          |> case do
                              nil        -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
                              {next_state, timeout} -> {:next_state, next_state, fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}
                          end
                            
        end         
  end
end

