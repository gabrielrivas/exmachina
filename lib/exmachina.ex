defmodule ExMachina do
  @behaviour :gen_statem

  @name :exmachina

  # Client API
  def start_link(fsm_object, timeout) do
    :gen_statem.start({:global, via_tuple(fsm_object.name)}, __MODULE__, [{fsm_object, timeout}], [])
  end

  defp via_tuple(fsm_name) do
    {:via, :gproc, {:n, :g, {:exfsm, fsm_name}}}
  end

  # Callbacks
  def callback_mode do
    :handle_event_function
  end

  def code_change(_vsn, state, data, _extra) do
    {:ok, state, data}
  end

  def init([{fsm_object, timeout}]) do  
    apply(fsm_object.module_logic, fsm_object.initialization_function, [fsm_object.data])
      |> case do
           {:ok, data}-> #Update fsm state data
                         new_fsm_object = fsm_object |> Map.put(:data, data)
                         {:ok, fsm_object.initial_state, new_fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}                
          _   -> IO.puts "Error initializing FSM"                      
                 {:error, fsm_object.initial_state, fsm_object, [{:state_timeout, timeout, :stop_after_timeout}]}
        end
  end

  def terminate(_reason, _state, _data) do
    :void
  end

  def get_state(fsm_name) do
    :gen_statem.call(via_tuple(fsm_name), {:get_state})
  end

  def restart(fsm_name) do
    :gen_statem.call(via_tuple(fsm_name), {:restart})
  end

  def stop(fsm_name) do
    :gen_statem.stop(via_tuple(fsm_name))
  end

  def handle_event({:call, _from}, :restart, state, fsm_object) do
    {:next_state, fsm_object.initial_state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
  end

  # ...
  ### Client API
  # ...
  def input_event(fsm_name, input_value) do
    :gen_statem.cast(via_tuple(fsm_name), {:input_event, input_value})
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
    reset_data = apply(fsm_object.module_logic, fsm_object.reset_function, [fsm_object.data])
    
    fsm_object = fsm_object
      |> Map.put(:data, reset_data)

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
           {:error, data} -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
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

