defexception Amrita.FactError,  message: "fact failed"

defexception Amrita.FactError,
                    expected: nil,
                    actual: nil,
                    reason: "",
                    negation: false,
                    prelude: "Expected" do

  def message(exception) do
    "#{exception.prelude}:\n" <>
    "     #{exception.actual} => #{exception.full_matcher}"
  end

  def full_matcher(exception) do
    "#{exception.reason}#{exception.arguments}"
  end

  def arguments(exception) do
    if exception.expected do
      "(#{exception.expected})"
    else
      ""
    end
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

  defmodule Fail do
    def msg(candidate, matcher) do
      raise Amrita.FactError, actual: candidate,
                              reason: matcher
    end

    def msg(expected, actual, matcher) do
      raise Amrita.FactError, expected: inspect(expected),
                              actual: inspect(actual),
                              reason: matcher
    end
  end

  defmodule SimpleMatchers do
    import ExUnit.Assertions

    def odd(number) do
      r = rem(number, 2) == 1

      if (not r), do: Fail.msg number, "odd"
    end

    def even(number) do
      r = rem(number, 2) == 0

      if (not r), do: Fail.msg number, "even"
    end

    @doc """
    Returns precisely true if actual is not nil and not false.
    """
    def truthy(thing) do
      if thing do
        r = true
      else
        r = false
      end

      if (not r), do: Fail.msg thing, "truthy"
    end

    @doc """
    Returns precisely true if actual is nil or false.
    """
    def falsey(thing) do
      if thing do
        r = false
      else
        r = true
      end

      if (not r), do: Fail.msg thing, "falsey"
    end

    @doc """
    With two arguments, accepts a value within delta of the
    expected value. With one argument, the delta is 1/1000th
    of the expected value.
    """
    def roughly(actual, expected, delta) do
      assert_in_delta(expected, actual, delta)
    end

    def roughly(actual, expected) do
      roughly(actual, expected, 0.01)
    end

    def equals(actual, expected) do
      r = (actual == expected)

      if (not r), do: Fail.msg actual, expected, "equals"
    end

  end

  defmodule CollectionMatchers do
    import ExUnit.Assertions

    @doc """
    Checks that the collection contains element:

    ## Examples
      [1, 2, 3] |> contains 3
    """
    def contains(collection, element) do
      if is_tuple(collection) do
        list_collection = (tuple_to_list collection)
      else
        list_collection = collection
      end

      r = Enum.any?(list_collection, fn x -> x == element end)

      if (not r), do: Fail.msg element, collection, "contains"
    end
  end

end