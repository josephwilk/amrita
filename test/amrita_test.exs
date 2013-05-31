Code.require_file "../test_helper.exs", __FILE__

defmodule AmritaFacts do
  use Amrita.Sweet

  fact "it should run like a test" do
    assert "1" == ""
  end


  fact "addition" do
    assert 1 + 1 == 2
  end

  facts "about subtraction" do
    fact "postive numbers" do
      assert 2 - 2 == 0
    end

    fact "negative numbers" do
      assert -2 - -2 == 0
    end
  end

end
