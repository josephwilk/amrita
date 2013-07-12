defexception Amrita.FactError,
                    expected: nil,
                    actual: nil,
                    predicate: "",
                    negation: false,
                    mock_fail: false,
                    errors: [],
                    prelude: "Expected" do

  def message do
    "fact failed"
  end

  def message(exception) do
    if exception.mock_fail do
     "#{exception.prelude}:\n" <> mock_messages(exception)
    else
      "#{exception.prelude}:\n" <>
      "     #{exception.actual_result} |> #{exception.full_checker}"
    end
  end

  def full_checker(exception) do
    Amrita.Checker.to_s exception.predicate, exception.expected
  end

  def actual_result(exception) do
    if is_bitstring(exception.actual) do
      exception.actual
    else
     inspect exception.actual
    end
  end

  defp mock_messages(exception) do
    errors = Enum.map(exception.errors, fn error -> mock_message(error) <> actual_calls(error) end)
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

  defp mock_message(e) do
    "     #{Amrita.Checker.to_s(e.module, e.fun, e.args)} called 0 times |> called(Expected atleast once)"
  end

end