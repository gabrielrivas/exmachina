defmodule FSMCore do
  defstruct type: nil,
            states: nil,
            initial_state: nil,            
            data: nil,
            module_logic: nil,                 
            initialization_function: nil,
            input_maping_function: nil,
            state_process: nil,
            info_handler: nil,
            reset_function: nil,            
            output: nil,
            transition_table: nil,
            timeout: 0

  def new() do
    %FSMCore{}
  end     
  
  def get_types, do: [:event_driven, :time_driven] 
end
