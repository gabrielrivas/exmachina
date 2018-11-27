defmodule CatTest do
  use ExUnit.Case

  @sleep_time 1000

  setup do
    Code.require_file("test/cat_fsm/cat_logic.ex") 
  end 

  test "exmachina_cat_test" do
    fsm_data = CatData.new() 
                 |> Map.put(:name, "Kitty") 
                 |> Map.put(:age, 5)

    transitions = [Transition.new()
                    |> Map.put(:current_state, :sleep)
                    |> Map.put(:input_value, :wake_up) 
                    |> Map.put(:next_state, :meow)      
                    |> Map.put(:timeout, @sleep_time),
                  Transition.new()
                    |> Map.put(:current_state, :meow) 
                    |> Map.put(:input_value, :human_gives_food)
                    |> Map.put(:next_state, :eat)
                    |> Map.put(:timeout, @sleep_time),
                  Transition.new()
                    |> Map.put(:current_state, :meow) 
                    |> Map.put(:input_value, :human_gives_a_toy)
                    |> Map.put(:next_state, :play)
                    |> Map.put(:timeout, @sleep_time),                    
                  Transition.new()
                    |> Map.put(:current_state, :meow)
                    |> Map.put(:input_value, :no_response_from_human) 
                    |> Map.put(:next_state, :meow)
                    |> Map.put(:timeout, @sleep_time),
                  Transition.new()
                    |> Map.put(:current_state, :play)
                    |> Map.put(:input_value, :tired_or_bored) 
                    |> Map.put(:next_state, :sleep)
                    |> Map.put(:timeout, @sleep_time),   
                  Transition.new()
                    |> Map.put(:current_state, :eat)
                    |> Map.put(:input_value, :belly_full) 
                    |> Map.put(:next_state, :sleep)
                    |> Map.put(:timeout, @sleep_time),
                  Transition.new()
                    |> Map.put(:current_state, :meow)
                    |> Map.put(:input_value, nil) 
                    |> Map.put(:next_state, :sleep)
                    |> Map.put(:on_event, :timeout)
                    |> Map.put(:timeout, @open_time),     
                  Transition.new()
                    |> Map.put(:current_state, :eat)
                    |> Map.put(:input_value, nil) 
                    |> Map.put(:next_state, :sleep)
                    |> Map.put(:on_event, :timeout)
                    |> Map.put(:timeout, @open_time),
                  Transition.new()
                    |> Map.put(:current_state, :play)
                    |> Map.put(:input_value, nil) 
                    |> Map.put(:next_state, :sleep)
                    |> Map.put(:on_event, :timeout)
                    |> Map.put(:timeout, @open_time)                                                                                               
                  ]   
                   
    test_fsm = FSMCore.new
              |> Map.put(:name, "mycat")
              |> Map.put(:type, :event_driven)
              |> Map.put(:states, [:sleep, :meow, :play, :eat])
              |> Map.put(:initial_state, :sleep)
              |> Map.put(:data, fsm_data)
              |> Map.put(:module_logic, CatLogic)
              |> Map.put(:initialization_function, :initialization)
              |> Map.put(:info_handler, :info_handler)
              |> Map.put(:input_maping_function, :process_input)
              |> Map.put(:reset_function, :reset_logic)
              |> Map.put(:transition_table, transitions)
              |> Map.put(:timeout, @sleep_time) 
                   
    #Create a new kitty instance
    {:ok, mycat} = ExMachina.start_link(test_fsm, @sleep_time)   

    #It will be sleeping by default                  
    assert ExMachina.call("mycat", :get_state) == :sleep

    #Wake up kitty!
    ExMachina.cast("mycat", {:input_event, :wake_up})
    assert ExMachina.call("mycat", :get_state) == :meow
    
    #So long doing nothing, go back to sleep 
    :timer.sleep(1500)

    assert ExMachina.call("mycat", :get_state) == :sleep
   
    #Wake up again kitty
    ExMachina.cast("mycat", {:input_event, :wake_up})
    assert ExMachina.call("mycat", :get_state) == :meow

    #Time to play for kitty
    ExMachina.cast("mycat", {:input_event, :human_gives_a_toy})
    :timer.sleep(500) 
    assert ExMachina.call("mycat", :get_state) == :play

    #Kitty just got tired of playing
    ExMachina.cast("mycat", {:input_event, :tired_or_bored})

    #So long doing nothing, go back to sleep 
    :timer.sleep(1500)

    assert ExMachina.call("mycat", :get_state) == :sleep   
  end
end
