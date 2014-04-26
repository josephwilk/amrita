defmodule Amrita.Checkers.Exceptions do
  alias Amrita.Message, as: Message
  
  @moduledoc """
  Checkers for expectations about Exceptions.
  """

  @doc """
  Checks if an exception was raised and that it was of the expected type or matches the
  expected message. Note it does not currently match when throw (Erlang errors) .

  ## Example
      fn -> raise Exception end |> raises Exception ; true
      fn -> raise "Jolly jolly gosh" end |> raises %r"j(\w)+y" ; true

      fn -> true end            |> raises Exception ; false
  """
  def raises(function, expected_exception) when is_function(function) do
    try do
      function.()
      Message.fail expected_exception, "No exception raised", __ENV__.function
    rescue
      error in [expected_exception] -> error
      error ->
        name = error.__record__(:name)

        if name in [ExUnit.AssertionError, ExUnit.ExpectationError, Amrita.FactError, Amrita.MockError] do
          raise(error)
        else
          failed_exception_match(error, expected_exception)
        end
    end
  end

  defp failed_exception_match(error, expected) when is_bitstring(expected) do
    message = error.message
    if not(String.contains?(expected, message)) do
      Message.fail message, expected, __ENV__.function
    end
  end

  defp failed_exception_match(error, expected) do
    if Regex.regex?(expected) do
      message = error.message
      if not(Regex.match?(expected, message)) do
        Message.fail message, expected, __ENV__.function
      end
    end
  end

  defp failed_exception_match(error, expected) do
    Message.fail error.__record__(:name), expected, __ENV__.function
  end

  @doc false
  def raises(expected_exception) do
    fn function ->
         function |> raises expected_exception
         {expected_exception,  __ENV__.function}
    end
  end
end
