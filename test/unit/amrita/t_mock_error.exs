Code.require_file "../../../test_helper.exs", __ENV__.file

defmodule MockErrorFacts do
  use Amrita.Sweet
  alias Amrita.Mocks.Provided, as: Provided

  facts "about mock error messages" do
    fact "message contains actual call" do
      error = Provided.Error.new(module: Amrita,
                                 fun: :pants,
                                 args: [:hatter],
                                 history: [{Amrita, :pants, [:platter]}])
      error = Amrita.MockError.new(mock_fail: true, errors: [error])

      error.message |> contains "Amrita.pants(:platter)"
    end

    fact "message contains expected call" do
      error = Provided.Error.new(module: Amrita,
                                 fun: :pants,
                                 args: [:hatter],
                                 history: [{Amrita, :pants, [:platter]}])
      error = Amrita.MockError.new(mock_fail: true, errors: [error])

      error.message |> contains "Amrita.pants(:hatter)"
    end

  end
end