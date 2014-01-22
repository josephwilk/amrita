Code.require_file "../../test_helper.exs", __ENV__.file

defmodule Integration.AsyncFacts do
  use Amrita.Sweet, async: true

  fact "testing async" do
    1 |> 1
  end

end