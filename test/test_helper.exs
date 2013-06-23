defmodule Support do
  defexception TestDidNotFailError, name: nil do
    def message(exception) do
      "Expected #{exception.name} to fail"
    end
  end

  def fails(which, test) do
    try do
      test.()
      raise TestDidNotFailError, name: which
      rescue
        Amrita.FactError ->
    end
  end
end

Amrita.start

