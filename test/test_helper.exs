defmodule Support do
  defexception FactDidNotFail, name: nil do
    def message(exception) do
      "Expected #{exception.name} to fail"
    end
  end

  defmacro failing_fact(name, _ // quote(do: _), contents) do
    quote do
      fact unquote(name) do
        fail unquote(name) do
          unquote(contents)
        end
      end
    end
  end

  defmacro fail(name, _ // quote(do: _), contents) do
    quote do
      try do
        unquote(contents)
        raise FactDidNotFail, name: unquote(name)
        rescue
          error in [Amrita.FactError, Amrita.MockError] ->
      end
    end
  end

end

Amrita.start

