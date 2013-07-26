Code.require_file "../test_helper.exs", __DIR__

defmodule ScopingFacts do
  use Amrita.Sweet
  import Support

  def echo, do:   1

  fact "echo 1", do: echo |> 1
  
  facts "echo nested" do
    def echo, do: 2
    
    future_fact "echo 2", do: echo |> 2
  end

end
