Code.require_file "../../../test_helper.exs", __FILE__

defmodule FactErrorFacts do
  use Amrita.Sweet

  facts "About error messages" do
    fact "message contains predicate with expected value" do
      error = Amrita.FactError.new(expected: "1", actual: "2", predicate: "contains")

      error.message |> contains "2 => contains(1)"
    end
  end

end
