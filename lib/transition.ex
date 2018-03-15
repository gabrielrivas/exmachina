defmodule Transition do
  defstruct current_state: nil,    
            input_value: nil,
            process_result: nil,            
            next_state: nil,
            on_event: nil, 
            timeout: 0

  def new() do
    %Transition{}
  end          
end 
