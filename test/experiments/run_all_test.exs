Code.require_file "../../test_helper.exs", __FILE__

defmodule RunAllFacts do
  use Amrita.Sweet
  import Support


  fact "run all asserts", meta do
    10 |> 11

    9 |> 6

    3 |> 3
  end

end
