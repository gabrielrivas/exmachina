defmodule CatData do
  defstruct name: nil,  
            age: 0

  def new() do
    %CatData{}
  end          
end

defmodule CatLogic do
  def initialization(%CatData{} = data) do
    IO.puts("Hello : #{data.name}!!")
    {:ok, data}
  end

  def info_handler(%CatData{} = data, message) do
    IO.puts("Called info : #{message}")
    {:ok, data}
  end

  def process_input(:sleep, :wake_up, %CatData{} = data) do
    IO.puts("#{data.name} woke up !")
    {:wake_up, data}
  end

  def process_input(:meow, :human_gives_food, %CatData{} = data) do
    IO.puts("#{data.name} is eating now!")
    {:human_gives_food, data}
  end

  def process_input(:meow, :human_gives_a_toy, %CatData{} = data) do
    IO.puts("#{data.name} is playing now!")
    {:human_gives_a_toy, data}
  end

  def process_input(:meow, :no_response_from_human, %CatData{} = data) do
    IO.puts("#{data.name} keeps meowing!")
    {:no_response_from_human, data}
  end

  def process_input(:eat, :belly_full, %CatData{} = data) do
    IO.puts("#{data.name} if full !")
    {:belly_full, data}
  end

  def process_input(:play, :tired_or_bored, %CatData{} = data) do
    IO.puts("#{data.name} is tired / bored :( ")
    {:tired_or_bored, data}
  end

  def process_input( _ , _, _) do
    IO.puts ("The cat is ignoring this !!")
  end  

  def reset_logic(%CatData{} = data) do
     IO.puts("#{data.name} is going to sleep ")
    {:ok, data}
  end  
end
