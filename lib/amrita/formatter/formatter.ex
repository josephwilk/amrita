defmodule Amrita.Formatter.Formatter do
  import Exception, only: [format_stacktrace_entry: 2]

  @doc """
  Receives a pending test and formats it.
  """
  def format_test_pending(ExUnit.Test[] = test, counter, cwd, color) do
    ExUnit.Test[case: test_case, name: test, failure: { kind, reason, stacktrace }] = test

    test_info("#{counter})", color) <>
      error_info("#{reason.message}", color) <>
      format_stacktrace(stacktrace, test_case, test, cwd, color)
  end

  defp format_stacktrace([{ test_case, test, _, [ file: file, line: line ] }|_], test_case, test, cwd, color) do
    location_info("at #{Path.relative_to(file, cwd)}:#{line}", color)
  end

  defp format_stacktrace(stacktrace, _case, _test, cwd, color) do
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