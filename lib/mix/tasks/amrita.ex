defmodule Mix.Tasks.Amrita do
  use Mix.Task

  @switches [force: :boolean, color: :boolean, cover: :boolean,
              trace: :boolean, max_cases: :integer]

  @shortdoc "Run Amrita tests"
  @recursive true

  def run(args) do
    { opts, files, _ } = OptionParser.parse(args, switches: @switches)

    selectors = Enum.map files, fn file ->
      splits = String.split(file, ":")
      case splits do
        [file, line] -> [file: file, line: binary_to_integer(line)]
        _ -> [file: file]
      end
    end

    selectors = Enum.reject selectors, fn selector -> selector == nil end
    files = Enum.map selectors, fn selector -> selector[:file] end

    opts = opts ++ [selectors: selectors]

    unless System.get_env("MIX_ENV") do
      Mix.env(:test)
    end

    Mix.Task.run "app.start", args

    project = Mix.project

    :application.load(:ex_unit)
    Amrita.Engine.Start.configure(Dict.take(opts, [:trace, :max_cases, :color, :selectors]))

    test_paths = project[:test_paths] || ["test"]
    Enum.each(test_paths, &require_test_helper(&1))

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
