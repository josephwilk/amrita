Code.require_file "../../../test_helper.exs", __FILE__

defmodule MocksFacts do
  use Amrita.Sweet

  facts "about parsing valid prerequisites" do
    fact "returns a dict indexed by module with {module, function, argument, return_value}" do
      hash = Amrita.Mocks.Provided.Parse.prerequisites(quote do: [Funk.monkey(4) |> 10])
      mocks = Dict.fetch!(hash, Funk)
      mock = Enum.at(mocks, 0)

      mock |> equals {Funk, :monkey, [4], 10}
    end

    fact "returns an empty dict when there are no prerequeistes" do
      Amrita.Mocks.Provided.Parse.prerequisites(quote do: []) |> equals HashDict.new []
    end
  end

  facts "about parsing invalid prerequisites" do
    fact "raises a parse exception" do
      fn ->
        Amrita.Mocks.Provided.Parse.prerequisites(quote do: [monkey(4) |> 10])
      end |> raises Amrita.Mocks.Provided.Parse.Error

      fn ->
        Amrita.Mocks.Provided.Parse.prerequisites(quote do: [4 |> 10])
      end |> raises Amrita.Mocks.Provided.Parse.Error

      fn ->
        Amrita.Mocks.Provided.Parse.prerequisites(quote do: [10])
      end |> raises Amrita.Mocks.Provided.Parse.Error
    end
  end

end