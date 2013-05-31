defmodule Amrita do

  defmodule Sweet do
    defmacro __using__(opts // []) do
      quote do
        use ExUnit.Case
        import Amrita.Facts
      end
    end
  end

  defmodule Facts do
    defmacro facts(description, var // quote(do: _), contents) do
      quote do
        @name_stack  (@name_stack || "") <> unquote(description) <> ": "
        unquote(contents)
      end
    end

    defmacro fact(description, var // quote(do: _), contents) do
      quote do
        test  (@name_stack || "") <> unquote(description) do
          unquote(contents)
        end
      end
    end
  end

end