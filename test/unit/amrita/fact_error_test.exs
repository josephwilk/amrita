Code.require_file "../../../test_helper.exs", __FILE__

defmodule FactErrorFacts do
  use Amrita.Sweet

  facts "about error messages" do
    fact "message contains predicate with expected value" do
      error = Amrita.FactError.new(expected: "fun", actual: "not-fun", predicate: "contains")

      error.message |> contains "not-fun |> contains(fun)"
    end

    fact "actual gets inspected when its not a string" do
      error = Amrita.FactError.new(actual: nil, predicate: "truthy")

      error.message |> contains "nil |> truthy"
    end
  end

end
