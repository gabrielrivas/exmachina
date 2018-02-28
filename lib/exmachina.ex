defmodule ExMachina do
  @behaviour :gen_statem

  @name :exmachina

  # Client API
  def start_link(fsm_object, initial_state, timeout) do
    :gen_statem.start({:local,@name}, __MODULE__, [{fsm_object, initial_state, timeout}], [])
  end

  # Callbacks
  def callback_mode do
    :handle_event_function
  end

  def init([{fsm_object, initial_state, timeout}]) do 
    {status, data} = apply(fsm_object.module_logic, fsm_object.initialization_function, [fsm_object.data])
    
    case status do
      :ok -> #Update fsm state data
             new_fsm_object = fsm_object |> Map.put(:data, data)
             {:ok, initial_state, new_fsm_object, [{:timeout, timeout, :stop_after_timeout}]}                
      _   -> IO.puts "Error initializing FSM"                      
             {:error, initial_state, fsm_object, [{:timeout, timeout, :stop_after_timeout}]}
    end
  end

  def terminate(_reason, _state, _data) do
    :void
  end

  def get_state(pid) do
    :gen_statem.call(@name, {:get_state})
  end

  # ...
  ### Client API
  # ...
  def input_event(input_value) do
    :gen_statem.cast(@name, {:input_event, input_value})
  end

  def handle_event({:call, from}, :get_state, state, fsm_object) do
    IO.puts(" *********** In state : #{state}")
    {:next_state, state, fsm_object, [{:reply, from, state}]}
  end

  def handle_event(:info, info_data, state, fsm_object) do
    {status, data} = apply(fsm_object.module_logic, fsm_object.info_handler, [fsm_object.data, info_data])
    
    new_fsm_object = case status do
      :ok -> #Update fsm state data
             fsm_object |> Map.put(:data, data)                            
      _ -> IO.puts "Error handling info event"                                 
    end

    {:next_state, state, new_fsm_object, [{:timeout, data.timeout, :wait_unlock_time}]}
  end

  @impl :gen_statem
  def handle_event(:cast, {:input_event, input_value}, state, fsm_object) do
    #[1] Map input to fsm event
    {input_mapped_value, data} = apply(fsm_object.module_logic, fsm_object.input_maping_function, [state, input_value, fsm_object.data])
    
    #[2] Update fsm state data
    fsm_object = fsm_object
                   |> Map.put(:data, data)

    #[3] Determine what the next state is from the transition table                
    (for transition <- fsm_object.transition_table,((input_mapped_value == transition.input_value) && (state == transition.current_state)),do: transition.next_state)
      |> List.first
      |> case do
           nil        -> {:next_state, state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
           next_state -> {:next_state, next_state, fsm_object, [{:state_timeout, fsm_object.timeout, :stop_after_timeout}]}
         end    
  end

  # Event Timeout Events
  def handle_event(:state_timeout, :stop_after_timeout, state, fsm_object) do
    IO.puts("State * #{inspect state} * timed out")
    reset_data = apply(fsm_object.module_logic, fsm_object.reset_function, [fsm_object.data])
    
    fsm_object = fsm_object
      |> Map.put(:data, reset_data)

    {:next_state, :locked, fsm_object, []}
  end
end
