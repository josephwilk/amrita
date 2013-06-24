defmodule Support do
  defexception FactDidNotFail, name: nil do
    def message(exception) do
      "Expected #{exception.name} to fail"
    end
  end

  defmacro fail(name, _ // quote(do: _), contents) do
    quote do
      try do
        unquote(contents)
        raise FactDidNotFail, name: unquote(name)
        rescue
          Amrita.FactError ->
      end
    end
  end

end

Amrita.start

