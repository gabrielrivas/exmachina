defmodule DoorCodeTest do
  use ExUnit.Case

  @code [1, 2, 3]
  @open_time 1000

  setup do
    Code.require_file("test/door_code_test/door_logic.ex") 
  end 

  test "exmachina_doorcode" do
    fsm_data = DoorData.new() 
                 |> Map.put(:code, @code) 
                 |> Map.put(:remaining, @code) 
                 |> Map.put(:unlock_time, @open_time)

    transitions = [Transition.new()
                    |> Map.put(:current_state, :locked)
                    |> Map.put(:input_value, :not_equal) 
                    |> Map.put(:next_state, :locked)
                    |> Map.put(:next_state, :locked)      
                    |> Map.put(:timeout, @open_time),
                  Transition.new()
                    |> Map.put(:current_state, :locked) 
                    |> Map.put(:input_value, :equal_and_rest)
                    |> Map.put(:next_state, :locked)
                    |> Map.put(:timeout, @open_time),
                  Transition.new()
                    |> Map.put(:current_state, :locked)
                    |> Map.put(:input_value, :equal) 
                    |> Map.put(:next_state, :open)
                    |> Map.put(:timeout, @open_time),
                  Transition.new()
                    |> Map.put(:current_state, :open)
                    |> Map.put(:input_value, nil) 
                    |> Map.put(:next_state, :locked)
                    |> Map.put(:on_event, :timeout)
                    |> Map.put(:timeout, @open_time),
                  ]   
                   
    test_fsm = FSMCore.new
              |> Map.put(:states, [:locked, :open])
              |> Map.put(:data, fsm_data)
              |> Map.put(:module_logic, DoorLogic)
              |> Map.put(:initialization_function, :initialization)
              |> Map.put(:info_handler, :info_handler)
              |> Map.put(:input_maping_function, :check_code)
              |> Map.put(:reset_function, :reset_logic)
              |> Map.put(:transition_table, transitions)
              |> Map.put(:timeout, @open_time) 
                   

    {:ok, door} = ExMachina.start_link(test_fsm, :locked, @open_time)                     

    #Test info handler
    send(door, "Some input message !!!")

    assert :gen_statem.call(door, :get_state) == :locked

    :gen_statem.cast(door, {:input_event, 1})
    :timer.sleep(1500)

    :gen_statem.cast(door, {:input_event, 1})
    assert :gen_statem.call(door, :get_state) == :locked

    :gen_statem.cast(door, {:input_event, 2})
    assert :gen_statem.call(door, :get_state) == :locked

    :gen_statem.cast(door, {:input_event, 3})

    # Verify that it is unlocked after the correct code is entered
    assert :gen_statem.call(door, :get_state) == :open
    :timer.sleep(5000)

    # Verify that it is locked again after the specified time
    assert :gen_statem.call(door, :get_state) == :locked


    send(door, "Another input message !!!")

    assert :gen_statem.call(door, :get_state) == :locked

    :gen_statem.cast(door, {:input_event, 1})
    :timer.sleep(1500)

    :gen_statem.cast(door, {:input_event, 1})
    assert :gen_statem.call(door, :get_state) == :locked

    :gen_statem.cast(door, {:input_event, 2})
    assert :gen_statem.call(door, :get_state) == :locked

    :gen_statem.cast(door, {:input_event, 3})

    # Verify that it is unlocked after the correct code is entered
    assert :gen_statem.call(door, :get_state) == :open
    :timer.sleep(5000)

    # Verify that it is locked again after the specified time
    assert :gen_statem.call(door, :get_state) == :locked    
  end
end
