Code.require_file "../../../test_helper.exs", __FILE__

defmodule MocksFacts do
  use Amrita.Sweet

  defp find_mocks(prerequisites, module, fun) do
    mocks_by_module = Dict.fetch!(prerequisites, module)
    Dict.fetch!(mocks_by_module, fun)
  end

  facts "about parsing valid prerequisites" do
    fact "returns a dict indexed by module and function with {module, function, argument, return_value}" do
      prerequisites = Amrita.Mocks.Provided.Parse.prerequisites(quote do: [Funk.monkey(4) |> 10])
      mocks = find_mocks(prerequisites, Funk, :monkey)

      mocks |> contains {Funk, :monkey, [4], 10}
    end

    fact "stores mocks with same module and function together" do
      prerequisites = Amrita.Mocks.Provided.Parse.prerequisites(quote do: [Funk.monkey(4) |> 10, Funk.monkey(5) |> 11])
      mocks = find_mocks(prerequisites, Funk, :monkey)

      mocks |> contains {Funk, :monkey, [4], 10}
      mocks |> contains {Funk, :monkey, [5], 11}
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
        Amrita.Mocks.Provided.Parse.prerequisites(quote do: [monkey(4)])
      end |> raises Amrita.Mocks.Provided.Parse.Error

      fn ->
        Amrita.Mocks.Provided.Parse.prerequisites(quote do: [4 |> 10])
      end |> raises Amrita.Mocks.Provided.Parse.Error

      fn ->
        Amrita.Mocks.Provided.Parse.prerequisites(quote do: [10])
      end |> raises Amrita.Mocks.Provided.Parse.Error
    end
  end

  facts "about resolving mock arguments" do
    fact "anything resolves to _" do
      prerequisites = Amrita.Mocks.Provided.Parse.prerequisites(quote do: [Funk.monkey(anything) |> 10])
      resolved_prerequisites = Amrita.Mocks.Provided.__resolve_args__(prerequisites, __MODULE__, __ENV__)

      mocks = find_mocks(resolved_prerequisites, Funk, :monkey)

      mocks |> equals [{Funk, :monkey, [:_], 10}]
    end
  end

end