Code.require_file "../test_helper.exs", __DIR__

defmodule Integration.CallbackFacts do
  use Amrita.Sweet

  setup do
    { :ok, ping: :hello }
  end

  fact "passed data from setup", meta do
    meta[:ping] |> :hello
  end

  facts "within a facts group" do
    future_fact "passed data from setup", meta do
      meta[:ping] |> :hello
    end
  end

end