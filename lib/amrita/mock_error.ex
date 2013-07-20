defexception Amrita.MockError,
                    errors: [],
                    prelude: "Expected" do

  def message(exception) do
    "#{exception.prelude}:\n" <> messages(exception)
  end

  defp messages(exception) do
    errors = Enum.map(exception.errors, fn error -> expected_call(error) <> actual_calls(error) end)
    Enum.join(errors, "\n")
  end

  defp actual_calls(e) do
    history = Enum.map e.history, fn({m,f,a}) -> "         * #{Amrita.Checker.to_s(m, f, a)}" end

    if not(Enum.empty?(history)) do
      "\n\n       Actuals calls:\n" <> Enum.join(history, "\n")
    else
      ""
    end
  end

  defp expected_call(e) do
    "     #{Amrita.Checker.to_s(e.module, e.fun, printable_args(e))} to be called but was called 0 times."
  end

  defp printable_args(e) do
    index = -1
    args = Enum.map e.args, fn arg ->
      index = index + 1
      case arg do
        {:"$meck.matcher", :predicate, _} -> Macro.to_string(Enum.at(e.raw_args, index))
        _ -> arg
      end
    end
  end

end