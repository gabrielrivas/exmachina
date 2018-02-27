defmodule Transition do
  defstruct current_state: nil,
            module_logic: nil,     
            input_value: nil,            
            next_state: nil,
            on_event: nil, 
            timeout: 0

  def new() do
    %Transition{}
  end          
end 
