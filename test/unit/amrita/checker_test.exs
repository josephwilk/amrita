Code.require_file "../../../test_helper.exs", __FILE__

defmodule CheckerFacts do
  use Amrita.Sweet

  facts "converting predicates into strings" do
    fact "atom argument is rendered" do
      checker_as_string = Amrita.Checker.to_s { :equals, 2 }, :pants
      checker_as_string |> "equals(:pants)"
    end

    future_fact "string argument is rendered" do
      checker_as_string = Amrita.Checker.to_s { :equals, 2 }, "pants"
      checker_as_string |> "equals(\"pants\")"
    end

    fact "nil argument is rendered" do
      checker_as_string = Amrita.Checker.to_s { :equals, 2 }, nil
      checker_as_string |> "equals(nil)"
    end

    fact "arity 1 renders just predicate" do
      checker_as_string = Amrita.Checker.to_s { :truthy, 1 }, nil
      checker_as_string |> "truthy"
    end

  end
end
