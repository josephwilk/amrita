Code.require_file "../test_helper.exs", __FILE__

defmodule AmritaFacts do
  use Amrita.Sweet

  fact "it should be awesome" do
    assert "1" == ""
  end
end
