defmodule Amrita.Formatter.Format do
  @moduledoc false

  import Exception, only: [format_stacktrace_entry: 2]

  @doc """
  Receives a pending test and formats it.
  """
  def format_test_pending(ExUnit.Test[] = test, counter, color) do
    ExUnit.Test[case: test_case, name: test_name, failure: { _kind, _reason, stacktrace }] = test

    test_info("#{counter})", color) <>
      error_info("#{format_test_name(test)}", color) <>
      format_location(find_case(stacktrace, test_case, test_name), test_case, test_name, color)
  end

  defp find_case([head|tail], test_case, test_name) do
    case head do
      { ^test_case, ^test_name, _, _ } -> [head]
      _                                -> find_case(tail, test_case, test_name)
    end
  end

  defp find_case([], _, _) do
    []
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

  defp format_location([{ test_case, test, _, [ file: file, line: line ] }|_], test_case, test, color) do
    location_info("# #{Path.relative_to_cwd(file)}:#{line}", color)
  end

  defp format_location(stacktrace, _case, test, color) do
    location_info("# #{Enum.map_join(stacktrace, fn(s) -> format_stacktrace(s, test, nil, color) end)}", color)
  end

  defp format_stacktrace([{ test_case, test, _, [ file: file, line: line ] }|_], test_case, test, color) do
    location_info("at #{Path.relative_to_cwd(file)}:#{line}", color)
  end

  defp format_stacktrace(stacktrace, _case, _test, color) do
    cwd = System.cwd
    location_info("stacktrace:", color) <>
      Enum.map_join(stacktrace, fn(s) -> stacktrace_info format_stacktrace_entry(s, cwd), color end)
  end

  defp test_info(msg, nil),   do: "  " <> msg <> " "
  defp test_info(msg, color), do: test_info(color.(:test_info, msg), nil)

  defp error_info(msg, nil),   do: "" <> msg <> "\n"
  defp error_info(msg, color), do: error_info(color.(:error_info, msg), nil)

  defp location_info(msg, nil),   do: "     " <> msg <> "\n"
  defp location_info(msg, color), do: location_info(color.(:location_info, msg), nil)

  defp stacktrace_info(msg, nil),   do: "       " <> msg <> "\n"
  defp stacktrace_info(msg, color), do: stacktrace_info(color.(:stacktrace_info, msg), nil)

end