Code.require_file "../test_helper.exs", __FILE__

defmodule AmritaFacts do
  use Amrita.Sweet

  fact "it should run like a test" do
    assert "1" == ""
  end

  facts "a group of facts" do
    fact "it should run like a nested test" do
      assert "2" == "3"
    end

    fact "it should run like another nested test" do
      assert "2" == "3"
    end
  end

end
