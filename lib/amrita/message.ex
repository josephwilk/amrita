defmodule Amrita.Message do
  @moduledoc false

  def fail(candidate, fun) do
    raise Amrita.FactError, actual: candidate,
                            predicate: fun
  end

  def fail(actual, expected, fun) do
    raise Amrita.FactError, expected: expected,
                            actual: actual,
                            predicate: fun
  end

  def mock_fail(errors) do
    raise Amrita.MockError, errors: errors
  end

  def pending(message) do
    raise Amrita.FactPending, message: message
  end
end
