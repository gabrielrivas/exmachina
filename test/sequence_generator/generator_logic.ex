  defmodule GeneratorLogic do
    def initialization(data) do
      IO.puts("Called initialzation !!!")
      {:ok, data}
    end
  
    def info_handler(data, message) do
      IO.puts("Called info : #{message}")
      {:ok, data}
    end
  
    def state_process(:s1, data) do
      IO.puts "Hello #{data} from S1"
      {:ok, data}          
    end
  
    def state_process(:s2, data) do
        IO.puts "Hello #{data} from S2"
        {:ok, data}          
    end

    def state_process(:s3, data) do
        IO.puts "Hello #{data} from S3"
        {:ok, data}                  
    end

    def state_process(:s4, data) do
        IO.puts "Hello #{data} from S4"
        {:ok, data}                  
    end

    def state_process(:s5, data) do
        IO.puts "Hello #{data} from S5"
        {:ok, data}                  
    end

    def state_process(:s6, data) do
        IO.puts "Hello #{data} from S6"
        {:ok, data}                  
    end

    def state_process(:s7, data) do
        IO.puts "Hello #{data} from S7"
        {:ok, data}                  
    end

    def state_process(:s8, data) do
        IO.puts "Hello #{data} from S8"
        {:ok, data}                  
    end

    def state_process(:s9, data) do
        IO.puts "Hello #{data} from S9" 
        {:ok, data}                 
    end    

    def state_process(_, data) do
        IO.puts "Nothing to do here"  
        {:ok, data}                
    end

    def reset_logic(data) do
      {:ok, data}
    end     
  end
  