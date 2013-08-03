Code.require_file "../../../../test_helper.exs", __FILE__

defmodule VersionFacts do
  use Amrita.Sweet

  alias Amrita.Elixir.Version, as: Version

  #Note fact "name", provided:[]
  #Does not work in this example as each below gets wrapped and catches missed form

  fact "older_than" do
    provided [System.version |> "0.9.2"] do
    Version.less_than_or_equal?([0,9,1])  |> falsey
    Version.less_than_or_equal?([0,9,2])  |> truthy
    Version.less_than_or_equal?([1,0,0])  |> truthy
    Version.less_than_or_equal?([0,10,0]) |> truthy
  end
  end
end