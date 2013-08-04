Code.require_file "../../../test_helper.exs", __FILE__

defmodule CheckerFacts do
  use Amrita.Sweet

  facts "converting predicates into strings" do
    fact "atom argument is rendered" do
      checker_as_string = Amrita.Checkers.to_s { :equals, 2 }, :pants
      checker_as_string |> "equals(:pants)"
    end

    fact "string argument is rendered" do
      checker_as_string = Amrita.Checkers.to_s { :equals, 2 }, "pants"
      checker_as_string |> "equals(\"pants\")"
    end

    fact "nil argument is rendered" do
      checker_as_string = Amrita.Checkers.to_s { :equals, 2 }, nil
      checker_as_string |> "equals(nil)"
    end

    fact "arity 1 renders just predicate" do
      checker_as_string = Amrita.Checkers.to_s { :truthy, 1 }, nil
      checker_as_string |> "truthy"
    end

  end

  facts "converts negated predicates into strings" do
    fact "contains both predicate and negation symbol" do
      checker_as_string = Amrita.Checkers.to_s :!, {:pants, {:equals, 1}}
      checker_as_string |> "! equals(:pants)"
    end
  end

end
