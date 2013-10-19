Code.require_file "../../test_helper.exs", __FILE__

defmodule Integration.Syntax.Describe do
  use Amrita.Sweet

  import Support

  describe "we can use describe in place of facts" do
    it "works like fact" do
      10 |> 10

      fail do
        1 |> 10
      end
    end
  end

  context "we can use context in place of facts" do
    specify "specify works like fact" do
      10 |> 10
    end
  end
end
