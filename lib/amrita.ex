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
  @moduledoc """
  A polite, well mannered and throughly upstanding testing framework for Elixir.
  """

  def start do
    ExUnit.start
  end

  defmodule Sweet do
    @moduledoc """
    Responsible for loading Amrita within test.
    """

    defmacro __using__(_ // []) do
      quote do
        use ExUnit.Case
        import Amrita.Facts
        import Amrita.SimpleMatchers
        import Amrita.CollectionMatchers
      end
    end
  end

  defmodule Facts do

    @doc """
    A fact is the container of your test logic.

    ## Example
      fact "about addition" do
        ...
      end
    """
    defmacro fact(description, _ // quote(do: _), contents) do
      quote do
        test Enum.join((@name_stack || []), "") <> unquote(description) do
          unquote(contents)
        end
      end
    end

    @doc """
    facts are used to group with a name a number of fact tests.
    You can nest as many facts as you feel you need.

    ## Example
      facts "about arithmetic" do
        fact "about addition" do
          ...
        end
      end
    """
    defmacro facts(description, _ // quote(do: _), contents) do
      quote do
        @name_stack List.concat((@name_stack || []), [unquote(description) <> ": "])
        unquote(contents)
        if Enum.count(@name_stack) > 0 do
          @name_stack Enum.take(@name_stack, Enum.count(@name_stack) - 1)
        end
      end
    end
  end

  defmodule Fail do
    defp msg(candidate, matcher) do
      raise Amrita.FactError, actual: candidate,
                              reason: matcher
    end

    defp msg(expected, actual, matcher) do
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
    Accepts a value within delta of the expected value.
    """
    def roughly(actual, expected, delta) do
      assert_in_delta(expected, actual, delta)
    end

    @doc """
    Accepts a value within 1/1000th of the expected value.
    """
    def roughly(actual, expected) do
      roughly(actual, expected, 0.01)
    end

    def equals(actual, expected) do
      r = (actual == expected)

      if (not r), do: Fail.msg actual, expected, "equals"
    end

  end

  defmodule CollectionMatchers do
    @moduledoc """
    Matchers which are designed to work with collections (lists, tuples, keyword lists)
    """

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

    @doc """
    Checks that the actual result starts with the expected result:

    ## Examples
      [1 2 3] |> has-prefix  [1 2]) ; true
      [1 2 3] |> has-prefix  [2 1]) ; false

      {1, 2, 3} |> has-prefix {1, 2} ; true
    """
    def has_prefix(collection, prefix) do
      if is_tuple(collection) do
        list_collection = (tuple_to_list collection)
      else
        list_collection = collection
      end

      if is_tuple(prefix) do
        list_prefix = (tuple_to_list prefix)
      else
        list_prefix = prefix
      end

      r = Enum.take(list_collection, Enum.count(list_prefix)) == list_prefix

      if (not r), do: Fail.msg prefix, collection, "has_prefix"
    end

    @doc """
    Checks that the actual result ends with the expected result:

    ## Examples:
      [1 2 3] |> has-suffix [2 3]) ; true
      [1 2 3] |> has-suffix [3 2]  ; false
    """
    def has_suffix(collection, suffix) do
      suffix_length = Enum.count(suffix)
      collection_length = Enum.count(collection)

      r = Enum.drop(collection, collection_length - suffix_length) == suffix

      if (not r), do: Fail.msg suffix, collection, "has_suffix"
    end

  end

end