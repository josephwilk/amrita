defmodule Mix.Tasks.Amrita do
  use Mix.Task

  @shortdoc "Run Amrita tests"
  @recursive true

  def run(args) do
    { opts, files } = OptionParser.parse(args, switches: @switches)

    unless System.get_env("MIX_ENV") do
      Mix.env(:test)
    end

    Mix.Task.run "app.start", args

    project = Mix.project

    :application.load(:ex_unit)
    ExUnit.configure(Dict.take(opts, [:trace, :max_cases, :color]))

    test_paths = project[:test_paths] || ["test"]
    Enum.each(test_paths, require_test_helper(&1))

    test_paths   = if files == [], do: test_paths, else: files
    test_pattern = project[:test_pattern] || "*.exs"

    files = Mix.Utils.extract_files(test_paths, test_pattern)
    Kernel.ParallelRequire.files files
  end

  defp require_test_helper(dir) do
    file = Path.join(dir, "test_helper.exs")

    if File.exists?(file) do
      Code.require_file file
    else
      raise Mix.Error, message: "Cannot run tests because test helper file #{inspect file} does not exist"
    end
  end
end
