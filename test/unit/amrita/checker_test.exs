Code.require_file "../../../test_helper.exs", __FILE__

defmodule CheckerFacts do
  use Amrita.Sweet

  facts "converting predicates into strings" do
    fact "atom arguments are rendered in string" do
      checker_as_string = Amrita.Checker.to_s {:equals, 2}, :pants
      checker_as_string |> "equals(:pants)"
    end
  end

end
