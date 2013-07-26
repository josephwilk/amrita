defmodule Amrita.Checkers.Simple do
  alias Amrita.Message, as: Message
  alias Amrita.Checker, as: Checker
  
  @moduledoc """
  Checkers for operating on single forms like numbers, atoms, bools, floats, etc.
  """

  @doc """
  Check if actual is odd.

  ## Example
      2 |> even ; true

  """
  def odd(number) when is_integer(number) do
    r = rem(number, 2) == 1

    if not(r), do: Message.fail(number, __ENV__.function)
  end

  @doc """
  Check if actual is even.

  ## Example
      2 |> even ; true
  """
  def even(number) when is_integer(number) do
    r = rem(number, 2) == 0

    if not(r), do: Message.fail(number, __ENV__.function)
  end

  @doc """
  Check if `actual` evaluates to precisely true.

  ## Example
      "mercury" |> truthy ; true
      nil       |> truthy ; false
  """
  def truthy(actual) do
    if actual do
      r = true
    else
      r = false
    end

    if not(r), do: Message.fail(actual, __ENV__.function)
  end

  @doc """
  Check if `actual` evaluates to precisely false.

  ## Example
      nil |> falsey ; true
      ""  |> falsey ; false
  """
  def falsey(actual) do
    if actual do
      r = false
    else
      r = true
    end

    if not(r), do: Message.fail(actual, __ENV__.function)
  end

  @doc """
  Checks if actual is within delta of the expected value.

  ## Example
      0.1 |> roughly 0.2, 0.2  ; true
      0.1 |> roughly 0.01, 0.2 ; false
  """
  def roughly(actual, expected, delta) do
    r = (expected >= (actual - delta)) and (expected <= (actual + delta))

    if not(r), do: Message.fail(actual, "#{expected} +-#{delta}", __ENV__.function)
  end

  @doc """
  Checks if actual is a value within 1/1000th of the expected value.

  ## Example
      0.10001 |> roughly 0.1  ; true
      0.20001 |> roughly 0.1  ; false
  """
  def roughly(actual, expected) do
    roughly(actual, expected, 0.01)
  end

  @doc false
  def roughly(expected) do
    fn actual ->
         actual |> roughly expected
         Checker.to_s(__ENV__.function, expected)
    end
  end

  @doc """
  Checks if a tuple matches another tuple.

  ## Example
      { 1, 2, 3 } |> matches { _, 2, _ }
  """
  defmacro matches(actual, expected) do
    quote do
      r = match?(unquote(expected), unquote(actual))
      if not(r), do: Amrita.Message.fail(unquote(actual), unquote(Macro.to_string(expected)), __ENV__.function)
    end
  end

  @doc """
  Checks if actual == expected.

  ## Example
      1000 |> equals 1000 ; true
      1000 |> equals 0    ; false
  """
  defmacro equals(actual, expected) do
    use_match = case expected do
      { :{}, _, _ }     -> true
      e when is_list(e) -> true
                      _ -> false
    end

    if(use_match) do
      quote do
        unquote(actual) |> matches unquote(expected)
      end
    else
      quote do
        r = (unquote(actual) == unquote(expected))

        if (not r), do: Message.fail(unquote(actual), unquote(expected), __ENV__.function)
    end
    end
  end

  @doc false
  def equals(expected) do
    fn actual ->
         actual |> equals expected
         Checker.to_s(__ENV__.function, expected)
    end
  end

  @doc """
  Checks if the function returns the expected result, this is used for
  checking received messages

  ## Examples
      fn -> :hello end |> :hello
      received |> msg(:hello)

  """
  def msg(function, expected) do
    actual = function.()
    r = actual == expected
    if not(r), do: Message.fail(actual, expected, __ENV__.function)
  end


  @doc """
  Negates all following checkers.

  ## Examples

      [1, 2, 3, 4] |> ! contains 999 ; true
      [1, 2, 3, 4] |> ! contains 4   ; false
  """
  def :!.(actual, checker) when is_function(checker) do
    r = try do
      checker.(actual)
      rescue
        error in [Amrita.FactError, Amrita.MockError, ExUnit.AssertionError] -> false
        error -> raise(error)
      end

    if r, do: Message.fail(actual, r, __ENV__.function)
  end

  def :!.(actual, value) do
    value |> ! equals actual
  end
end