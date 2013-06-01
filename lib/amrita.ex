defexception Amrita.FactError,  message: "fact failed"

defexception Amrita.FactError,
                    expected: nil,
                    actual: nil,
                    reason: "",
                    negation: false,
                    prelude: "Expected" do

  def message(exception) do
    "#{exception.prelude}:\n" <>
    "     #{exception.expected}\n" <>
    "     #{exception.full_reason}:\n" <>
    "     #{exception.actual}"
  end

  def full_reason(exception) do
    "to" <> if(exception.negation, do: " not ", else: " ")
    <> exception.reason
  end
end

defmodule Amrita do

  defmodule Sweet do
    defmacro __using__(opts // []) do
      quote do
        use ExUnit.Case
        import Amrita.Facts
        import Amrita.SimpleMatchers
        import Amrita.CollectionMatchers
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

  defmodule SimpleMatchers do
    import ExUnit.Assertions

    def odd(number) do
      assert rem(number, 2) == 1
    end

    def even(number) do
      assert rem(number, 2) == 0
    end

    def truthy(thing) do
      if thing do
        r = true
      else
        r = false
      end

      assert r == true
    end

    def falsey(thing) do
      if thing do
        r = true
      else
        r = false
      end

      assert r == false
    end

    def roughly(actual, expected, delta) do
      assert_in_delta(expected, actual, delta)
    end

    def roughly(actual, expected) do
      roughly(actual, expected, 0.01)
    end

    def equals(actual, expected) do
      assert actual == expected
    end

  end

  defmodule CollectionMatchers do
    import ExUnit.Assertions

    def contains(collection, element) do
      r = Enum.any?(collection, fn x -> x == element end)

      if (not r) do
        raise Amrita.FactError,
                     expected: inspect(collection),
                     actual: inspect(element),
                     reason: "contain"
      end
    end
  end

end