Code.require_file "../../test_helper.exs", __FILE__

defmodule Integration.CheckerFacts do
  use Amrita.Sweet
  import Support

  defchecker thousand(actual) do
    actual |> equals 1000
  end

   facts "about checkers with no expected argument" do
     fact "supports ! and positive form" do
       1000 |> thousand
       1001 |> ! thousand

       fail do
         1001 |> thousand
         1000 |> ! thousand
       end
     end
   end

  defchecker valid(actual, expected) do
    actual |> equals expected
  end

  facts "about checkers with an expected argument" do
    fact "supports ! and postive form" do
      100 |> valid 100
      100 |> ! valid 101

      fail do
        100 |> valid 101
        100 |> ! valid 100
      end
    end
  end

end