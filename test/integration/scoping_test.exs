Code.require_file "../test_helper.exs", __DIR__

defmodule ScopingFacts do
  use Amrita.Sweet

  def echo, do: 3

  fact "function define at root are accessible in a fact" do
    echo |> 3
  end

  facts "within a facts grouping" do
    def echo, do: 2

    fact "local function takes precedent over parent function" do
      echo |> 2
    end
  end

  facts "another facts grouping" do
    def echo, do: 1

    fact "local function again takes precedent over parent function and other local function" do
      echo |> 1
    end

  end

end


