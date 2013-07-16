defmodule Mix.Tasks.Amrita do
  use Mix.Task

  @shortdoc "Run Amrita tests"

  @moduledoc """
  Run Amrita tests
  """
  def run(args) do
    Mix.Task.run(:test, args)
  end
end