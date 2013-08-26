defmodule Amrita.Formatter.Format do
  @moduledoc false

  import Exception, only: [format_stacktrace_entry: 2]

  @doc """
  Receives a pending test and formats it.
  """
  def format_test_pending(ExUnit.Test[] = test, counter, cwd, color) do
    ExUnit.Test[case: test_case, name: test_name, failure: { _kind, _reason, stacktrace }] = test

    test_info("#{counter})", color) <>
      error_info("#{format_test_name(test)}", color) <>
      format_location(stacktrace, test_case, test_name, cwd, color)
  end

  def format_test_name(ExUnit.Test[name: name]) do
    case atom_to_binary(name) do
      "test_" <> rest -> rest
      "test " <> rest -> rest
    end
  end

  def colorize(escape, string) do
    if System.get_env("NO_COLOR") do
      string
    else
      IO.ANSI.escape_fragment("%{#{escape}}") <> string <> IO.ANSI.escape_fragment("%{reset}")
    end
  end

  defp format_location([{ test_case, test, _, [ file: file, line: line ] }|_], test_case, test, cwd, color) do
    location_info("# #{Path.relative_to(file, cwd)}:#{line}", color)
  end

  defp format_location(stacktrace, _case, _test, cwd, color) do
    location_info("# #{Enum.map_join(stacktrace, fn(s) -> format_stacktrace_entry(s, cwd) end)}", color)
  end

  defp test_info(msg, nil),   do: "  " <> msg <> " "
  defp test_info(msg, color), do: test_info(color.(:test_info, msg), nil)

  defp error_info(msg, nil),   do: "" <> msg <> "\n"
  defp error_info(msg, color), do: error_info(color.(:error_info, msg), nil)

  defp location_info(msg, nil),   do: "     " <> msg <> "\n"
  defp location_info(msg, color), do: location_info(color.(:location_info, msg), nil)

end