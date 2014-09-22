Code.require_file "../../../test_helper.exs", __ENV__.file

defmodule FactErrorFacts do
  use Amrita.Sweet

  facts "about error messages" do
    fact "message contains predicate with expected value" do
      error = %Amrita.FactError{expected: "fun", actual: "not-fun", predicate: "contains"}

      Amrita.FactError.message(error) |> contains "not-fun |> contains(\"fun\")"
    end

    fact "actual gets inspected when its not a string" do
      error = %Amrita.FactError{actual: nil, predicate: "truthy"}

      Amrita.FactError.message(error) |> contains "nil |> truthy"
    end
  end

end
