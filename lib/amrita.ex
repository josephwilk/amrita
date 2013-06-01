defmodule Amrita do

  defmodule Sweet do
    defmacro __using__(opts // []) do
      quote do
        use ExUnit.Case
        import Amrita.Facts
        import Amrita.Matchers
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

  defmodule Matchers do
    import ExUnit.Assertions

    def odd?(number) do
      assert rem(number, 2) == 1
    end

    def even?(number) do
      assert rem(number, 2) == 0
    end

    def truthy?(thing) do
      if thing do
        r = true
      else
        r = false
      end

      assert r == true
    end

    def falsey?(thing) do
      if thing do
        r = true
      else
        r = false
      end

      assert r == false
    end

    def roughly(actual, expected, delta) do
      r = (expected >= (actual - delta) and expected <= (actual + delta))
      assert true == r
    end

    def roughly(actual, expected) do
      roughly(actual, expected, 0.01)
    end

    def equals(actual, expected) do
      assert actual == expected
    end

  end

  defmodule CollectionMatchers do
  end

end