defmodule FSMCore do
  defstruct type: nil,
            states: nil,            
            data: nil,
            module_logic: nil,                 
            initialization_function: nil,
            input_maping_function: nil,
            info_handler: nil,
            reset_function: nil,            
            output: nil,
            transition_table: nil,
            timeout: 0

  def new() do
    %FSMCore{}
  end               
end
