Code.require_file "../test_helper.exs", __FILE__

defmodule AmritaTest do
  use ExUnit.Case
  import :all, Amrita.Sweet

  fact "it should be awesome" do
    assert "1" == ""
  end
end
