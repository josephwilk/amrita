defmodule Amrita.MockError do
  require Record
  require Amrita.Mocks.Provided
  
  defexception errors: [],
               prelude: "Expected"

  def message(exception) do
    "#{exception.prelude}:\n" <> messages(exception)
  end

  defp messages(exception) do
    IO.inspect exception.errors
    errors = Enum.map(exception.errors, fn e -> expected_call(e) <> actual_calls(e) end)
    Enum.join(errors, "\n")
  end

  defp actual_calls(e) do
    history = Enum.map Amrita.Mocks.Provided.error(e, :history), fn({m,f,a}) -> "         * #{Amrita.Checkers.to_s(m, f, a)}" end

    if not(Enum.empty?(history)) do
      "\n\n       Actuals calls:\n" <> Enum.join(history, "\n")
    else
      ""
    end
  end

  defp expected_call(e) do
    "     #{Amrita.Checkers.to_s(Amrita.Mocks.Provided.error(e, :module), Amrita.Mocks.Provided.error(e, :fun), printable_args(e))} to be called but was called 0 times."
  end

  defp printable_args(e) do
    index = -1
    Enum.map Amrita.Mocks.Provided.error(e, :args), fn arg ->
      index = index + 1
      case arg do
        {:"$meck.matcher", :predicate, _} -> Macro.to_string(Enum.at(Amrita.Mocks.Provided.error(e, :raw_args), index))
        _ -> arg
      end
    end
  end

end