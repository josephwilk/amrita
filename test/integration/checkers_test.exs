Code.require_file "../../test_helper.exs", __FILE__

defmodule CustomCheckers do
  use Amrita.Sweet
  
  defchecker thousand(actual) do
    actual |> equals 1000
  end

  defchecker valid(actual, expected) do
    actual |> equals expected
  end
end

defmodule Integration.CheckerFacts do
  use Amrita.Sweet
  import Support

   facts "about checkers with no expected argument" do
     import CustomCheckers
   
     fact "supports ! and positive form" do
       1000 |> thousand
       1001 |> ! thousand

       fail do
         1001 |> thousand
         1000 |> ! thousand
       end
     end
   end


  facts "about checkers with an expected argument" do
    import CustomCheckers
    
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