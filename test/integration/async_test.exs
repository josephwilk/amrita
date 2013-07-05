Code.require_file "../../test_helper.exs", __FILE__

defmodule AsyncFacts do
  use Amrita.Sweet, async: true

  fact "testing async" do
    1 |> 1
  end

end