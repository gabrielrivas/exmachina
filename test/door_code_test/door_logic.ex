defmodule DoorData do
  defstruct code: nil,
            remaining: nil,     
            unlock_time: 0

  def new() do
    %DoorData{}
  end          
end

defmodule DoorLogic do
  def initialization(%DoorData{} = data) do
    IO.puts("Called initialzation !!!")
    {:ok, data}
  end

  def info_handler(%DoorData{} = data, message) do
    IO.puts("Called info : #{message}")
    {:ok, data}
  end

  def check_code(:locked, digit, %DoorData{} = data) do
    case data.remaining do
      [digit] ->
        IO.puts "[#{digit}] Correct code.  Unlocked for #{data.unlock_time}"
        
        {:equal, data |> Map.put(:remaining, data.code)}
      [digit|rest] ->
        IO.puts "[#{digit}] Correct digit but not yet complete."
        
        {:equal_and_rest, data |> Map.put(:remaining, rest)}
      _ ->
        IO.puts "[#{digit}] Wrong digit, locking."
        
        {:not_equal, data |> Map.put(:remaining, data.code)}
    end
  end

  def check_code( _ , _digit, _data) do
    IO.puts ("Nothing to do on this transition!")
  end  

  def reset_logic(%DoorData{} = data) do
    data |> Map.put(:remaining, data.code)
  end  
end
