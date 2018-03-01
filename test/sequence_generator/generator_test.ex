defmodule GeneratorTest do
    use ExUnit.Case

    @period_time 1000
  
    setup do
      Code.require_file("test/sequence_generator/generator_logic.ex") 
    end 
  
    test "exmachina_generator" do

      transitions = [Transition.new()
                      |> Map.put(:current_state, :s1) 
                      |> Map.put(:next_state, :s2)   
                      |> Map.put(:timeout, @period_time),
                    Transition.new()
                      |> Map.put(:current_state, :s2) 
                      |> Map.put(:next_state, :s3)   
                      |> Map.put(:timeout, @period_time),
                    Transition.new()
                      |> Map.put(:current_state, :s3) 
                      |> Map.put(:next_state, :s4)   
                      |> Map.put(:timeout, @period_time),
                    Transition.new()
                    |> Map.put(:current_state, :s4) 
                    |> Map.put(:next_state, :s5)   
                    |> Map.put(:timeout, @period_time),
                    Transition.new()
                    |> Map.put(:current_state, :s5) 
                    |> Map.put(:next_state, :s6)   
                    |> Map.put(:timeout, @period_time),
                    Transition.new()
                    |> Map.put(:current_state, :s6) 
                    |> Map.put(:next_state, :s7)   
                    |> Map.put(:timeout, @period_time),
                    Transition.new()
                    |> Map.put(:current_state, :s7) 
                    |> Map.put(:next_state, :s8)   
                    |> Map.put(:timeout, @period_time),
                    Transition.new()
                    |> Map.put(:current_state, :s8) 
                    |> Map.put(:next_state, :s9)   
                    |> Map.put(:timeout, @period_time),
                    Transition.new()
                    |> Map.put(:current_state, :s9) 
                    |> Map.put(:next_state, :s1)   
                    |> Map.put(:timeout, @period_time),                                                                                                    
                    ]   
                     
      test_fsm = FSMCore.new
                |> Map.put(:type, :time_driven)
                |> Map.put(:states, [:s1, :s2, :s3, :s4, :S5, :s6, :s7, :s8, :s9])
                |> Map.put(:initial_state, :s1)
                |> Map.put(:data, "tester")
                |> Map.put(:module_logic, GeneratorLogic)
                |> Map.put(:initialization_function, :initialization)
                |> Map.put(:state_process, :state_process)
                |> Map.put(:info_handler, :info_handler)
                |> Map.put(:transition_table, transitions)
                |> Map.put(:timeout, @period_time) 
                     
  
      {:ok, gen} = ExMachina.start_link(test_fsm, @period_time)                     
  
      #Test info handler
      send(gen, "Some input message !!!")
  
      
      #:gen_statem.call(gen, :restart) 
      :timer.sleep(10000)
      :gen_statem.stop(gen)
    end
  end
  