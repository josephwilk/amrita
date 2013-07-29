Code.require_file "../../test_helper.exs", __FILE__

defmodule Integration.CheckerFacts do
  use Amrita.Sweet
  import Support

  defchecker thousand(actual) do
    actual |> 1000
  end
  
  fact "does something" do
    1000 |> thousand
    10 |> ! thousand
    
    fail :custom_checker do
      100 |> thousand
      1000 |> ! thousand
    end
  end

end