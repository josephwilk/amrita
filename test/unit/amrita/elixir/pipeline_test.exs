Code.require_file "../../../../test_helper.exs", __FILE__

defmodule PipelineFacts do
  use Amrita.Sweet
  import Support

  fact "|> defaults to comparison for 2 tuples" do
    { 1, 2, 3 } |> { 1, 2, 3 }

    fail :collection do
      { 1, 2, 3 } |> { 1, 2, 4 }
    end

  end

end

