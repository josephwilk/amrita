defmodule Support do
  defexception FactDidNotFail, name: nil do
    def message(exception) do
      "Expected #{exception.name} to fail"
    end
  end

  def fail(which, test) do
    try do
      test.()
      raise FactDidNotFail, name: which
      rescue
        Amrita.FactError ->
    end
  end
end

Amrita.start

