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

  facts "about mock error messages" do
    fact "message contains actual call" do
      error = Amrita.Mocks.Provided.Error.new(module: Amrita,
                                              fun: :pants,
                                              args: [:hatter],
                                              history: [{Amrita, :pants, [:platter]}])
      error = Amrita.FactError.new(mock_fail: true, errors: [error])

      error.message |> contains "Amrita.pants(:platter)"
    end

    fact "message contains expected call" do
      error = Amrita.Mocks.Provided.Error.new(module: Amrita,
                                              fun: :pants,
                                              args: [:hatter],
                                              history: [{Amrita, :pants, [:platter]}])
      error = Amrita.FactError.new(mock_fail: true, errors: [error])

      error.message |> contains "Amrita.pants(:hatter)"
    end

  end

end
