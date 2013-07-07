Code.require_file "../../../../test_helper.exs", __FILE__

defmodule VersionFacts do
  use Amrita.Sweet
  use Amrita.Mocks

  fact "older_than", provided: [System.version |> "0.9.2"] do
    Amrita.Elixir.Version.less_than_or_equal?([0,9,1]) |> falsey
    Amrita.Elixir.Version.less_than_or_equal?([0,9,2]) |> truthy
    Amrita.Elixir.Version.less_than_or_equal?([1,0,0]) |> truthy
    Amrita.Elixir.Version.less_than_or_equal?([0,10,0]) |> truthy
  end
end