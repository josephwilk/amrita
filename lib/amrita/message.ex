defmodule Amrita.Message do
  @moduledoc false

  def fail(candidate, {checker, _}) do
    raise Amrita.FactError, actual: candidate,
                            predicate: checker
  end

  def fail(actual, expected, {checker, _}) do
    raise Amrita.FactError, expected: inspect(expected),
                            actual: inspect(actual),
                            predicate: checker
  end

  def mock_fail(errors) do
    raise Amrita.MockError, errors: errors
  end

  def pending(message) do
    raise Amrita.FactPending, message: message
  end
end
