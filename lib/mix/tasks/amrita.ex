defmodule Mix.Tasks.Amrita do
  use Mix.Task

  @switches [force: :boolean, color: :boolean, cover: :boolean,
    trace: :boolean, max_cases: :integer, include: :keep,
    exclude: :keep, seed: :integer, only: :keep, compile: :boolean,
    start: :boolean]

  @shortdoc "Run Amrita tests"
  @recursive true

  def run(args) do
    { opts, files, _ } = OptionParser.parse(args, switches: @switches)

    unless System.get_env("MIX_ENV") do
      Mix.env(:test)
    end

    Mix.Task.run "app.start", args

    project = Mix.Project.config

    case Application.load(:ex_unit) do
      :ok -> :ok
      {:error, {:already_loaded, :ex_unit}} -> :ok
    end

    # Start the app and configure exunit with command line options
    # before requiring test_helper.exs so that the configuration is
    # available in test_helper.exs. Then configure exunit again so
    # that command line options override test_helper.exs
    Amrita.Engine.Start.configure(opts)
    opts = amrita_opts(opts)

    test_paths = project[:test_paths] || ["test"]
    Enum.each(test_paths, &require_test_helper(&1))
    Amrita.Engine.Start.configure(opts)

    test_files   = parse_files(files, test_paths)
    test_pattern = project[:test_pattern] || "*.exs"

    files = Mix.Utils.extract_files(test_files, test_pattern)
    Kernel.ParallelRequire.files files
  end

  @doc false
  def amrita_opts(opts) do
    opts = opts
            |> filter_opts(:include)
            |> filter_opts(:exclude)
            |> filter_only_opts()

    default_opts(opts) ++
    Dict.take(opts, [:trace, :max_cases, :include, :exclude, :seed])
  end

  defp default_opts(opts) do
    # Set autorun to false because Mix
    # automatically runs the test suite for us.
    case Dict.get(opts, :color) do
      nil -> [autorun: false]
      enabled? -> [autorun: false, colors: [enabled: enabled?]]
    end
  end

  defp parse_files([], test_paths) do
    test_paths
  end

  defp parse_files([single_file], _test_paths) do
    # Check if the single file path matches test/path/to_test.exs:123, if it does
    # apply `--only line:123` and trim the trailing :123 part.
    {single_file, opts} = ExUnit.Filters.parse_path(single_file)
    ExUnit.configure(opts)
    [single_file]
  end

  defp parse_files(files, _test_paths) do
    files
  end

  defp parse_filters(opts, key) do
    if Keyword.has_key?(opts, key) do
      ExUnit.Filters.parse(Keyword.get_values(opts, key))
    end
  end

  defp filter_opts(opts, key) do
    if filters = parse_filters(opts, key) do
      Keyword.put(opts, key, filters)
    else
      opts
    end
  end

  defp filter_only_opts(opts) do
    if filters = parse_filters(opts, :only) do
      opts
      |> Keyword.put_new(:include, [])
      |> Keyword.put_new(:exclude, [])
      |> Keyword.update!(:include, &(filters ++ &1))
      |> Keyword.update!(:exclude, &[:test|&1])
    else
      opts
    end
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
