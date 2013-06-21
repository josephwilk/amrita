Code.require_file "../test_helper.exs", __DIR__

defmodule MocksTest do
  use Amrita.Sweet
  use Amrita.Mock

  defmodule Polite do
    def swear? do
      false
    end

    def message do
      "oh swizzlesticks"
    end
  end

  fact "check unstubbed module was preserved after stub" do
    Polite.swear? |> falsey
    Polite.message |> "oh swizzlesticks"
  end

  fact "simple mock on existing module" do
    provided [MocksTest.Polite.swear? |> true] do
      Polite.swear? |> truthy
    end
  end

  fact "check again that unstubbed module was preserved after stub" do
    Polite.swear? |> falsey
    Polite.message |> "oh swizzlesticks"
  end
end
