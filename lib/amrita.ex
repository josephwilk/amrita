defmodule Amrita do
  @moduledoc """
  A polite, well mannered and throughly upstanding testing framework for Elixir.
  """

  @doc """
  Start Amrita for a test run.

  This should be called in your test_helper.exs file.
  """
  def start do
    ExUnit.start formatter: Amrita.Formatter.Progress
  end

  @doc """
    Polite version of start.
  """
  def please_start do
    start
  end

  defmodule Sweet do
    @moduledoc """
    Responsible for loading Amrita within test.

        defmodule TestsAboutSomething do
          use Amrita.Sweet
        end
    """

    @doc false
    defmacro __using__(_ // []) do
      quote do
        use ExUnit.Case
        import Amrita.Facts
        import Amrita.Checkers.Simple
        import Amrita.Checkers.Collection
        import Amrita.Checkers.Exceptions
      end
    end
  end

  defmodule Facts do
    @moduledoc """
    Express facts about your code.
    """

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
    A fact without a body is a pending fact. Much like a TODO.
    It prints a reminder when the tests are run.

    ## Example
        fact "something thing I need to implement at somepoint"

    """
    defmacro fact(description) do
      quote do
        Amrita.Message.pending "Future fact: " <> Enum.join((@name_stack || []), "") <> unquote(description)
      end
    end

    @doc """
    A future_fact is a pending fact. Its body is *NEVER* run.
    Instead it simply prints an reminder that it is yet to be run.

    ## Example:
        future_fact "about something that does not work yet" do
          ..
        end
    """
    defmacro future_fact(description, _ // quote(do: _), _) do
      quote do
        Amrita.Message.pending "Future fact: " <> Enum.join((@name_stack || []), "") <>  unquote(description)
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

  @doc false
  defmodule Message do
    def fail(candidate, matcher) do
      raise Amrita.FactError, actual: candidate,
                              predicate: matcher
    end

    def fail(expected, actual, matcher) do
      raise Amrita.FactError, expected: inspect(expected),
                              actual: inspect(actual),
                              predicate: matcher
    end

    def pending(message) do
      IO.puts IO.ANSI.escape("%{yellow}" <>  message)
    end
  end

  defmodule Checkers.Exceptions do

    @doc """
    Checks if an exception was raised and that it was of the expected type

    ## Example
        fn -> raise Exception end |> raises Exception ; true
        fn -> true end            |> raises Exception ; false
    """
    def raises(function, expected_exception) do
      try do
        function.()
        Message.fail expected_exception, "No exception raised", "raises"
      rescue
        error in [expected_exception] -> error
        error ->
          name = error.__record__(:name)
          if name in [ExUnit.AssertionError, ExUnit.ExpectationError, Amrita.FactError] do
            raise(error)
          else
            Message.fail name, expected_exception, "raises"
          end
      end
    end
  end

  defmodule Checkers.Simple do
    @moduledoc """
    Checkers for operating on single forms like numbers, atoms, bools, floats, etc.
    """

    import ExUnit.Assertions, only: [assert_in_delta: 3]

    @doc """
    Returns if actual is odd
    """
    def odd(number) do
      r = rem(number, 2) == 1

      if (not r), do: Message.fail number, "odd"
    end

    @doc """
    Returns if actual is even
    """
    def even(number) do
      r = rem(number, 2) == 0

      if (not r), do: Message.fail number, "even"
    end

    @doc """
    Returns precisely true if actual is not nil and not false.
    """
    def truthy(actual) do
      if actual do
        r = true
      else
        r = false
      end

      if (not r), do: Message.fail actual, "truthy"
    end

    @doc """
    Returns precisely true if actual is nil or false.
    """
    def falsey(actual) do
      if actual do
        r = false
      else
        r = true
      end

      if (not r), do: Message.fail actual, "falsey"
    end

    @doc """
    Checks if actual is within delta of the expected value.
    """
    def roughly(actual, expected, delta) do
      assert_in_delta(expected, actual, delta)
    end

    @doc """
    Checks if actual is a value within 1/1000th of the expected value.
    """
    def roughly(actual, expected) do
      roughly(actual, expected, 0.01)
    end

    @doc """
    Checks if actual == expected
    """
    def equals(actual, expected) do
      r = (actual == expected)

      if (not r), do: Message.fail actual, expected, "equals"
    end

    def equals(expected) do
      fn actual ->
          actual |> equals expected
          "equals(#{inspect(expected)})"
      end
    end

    @doc """
    Negates all following predicates.

    ## Examples

        [1, 2, 3, 4] |> ! contains 999 ; true
        [1, 2, 3, 4] |> ! contains 4   ; false

    """
    def :!.(actual, checker) do
      r = try do
        checker.(actual)
      rescue
        error in [Amrita.FactError] -> false
        error -> raise(error)
      end

      if r, do: Message.fail r, actual, "! "
    end

  end

  defmodule Checkers.Collection do
    @moduledoc """
    Checkers which are designed to work with collections (lists, tuples, keyword lists, strings)
    """

    @doc """
    Checks that the collection contains element:

    ## Examples
        [1, 2, 3] |> contains 3
        {1, 2, 3} |> contains 2

        "elixir of life" |> contains "of"

        "elixir of life" |> contains %r/"of"/

    """
    def contains(collection,element) do
      r = case collection do
            c when is_tuple(c)           -> element in tuple_to_list(c)
            c when is_list(c)            -> element in c
            c when is_regex(element)     -> Regex.match?(element, c)
            c when is_bitstring(element) -> string_match?(element, c)
          end

      if (not r), do: Message.fail element, collection, "contains"
    end

    def contains(element) do
      fn collection ->
           collection |> contains element
           "contains(#{inspect(element)})"
      end
    end

    @doc false
    defp string_match?(element, string) do
      case :binary.matches(string, element) do
        [_] -> true
        []  -> false
      end
    end

    @doc """
    Checks that the actual result starts with the expected result:

    ## Examples
        [1 2 3] |> has_prefix  [1 2]   ; true
        [1 2 3] |> has_prefix  [2 1]   ; false

        {1, 2, 3} |> has_prefix {1, 2} ; true

        "I cannot explain myself for I am not myself" |> has_prefix "I"

    """
    def has_prefix(collection, prefix) do
      r = case collection do
            c when is_tuple(c) ->
              collection_prefix = Enum.take(tuple_to_list(collection), tuple_size(prefix))
              collection_prefix = list_to_tuple(collection_prefix)
              collection_prefix == prefix
            c when is_list(c)  ->
              Enum.take(collection, Enum.count(prefix)) == prefix
            _ when is_bitstring(prefix) ->
              String.starts_with?(collection, prefix)
          end

      if (not r), do: Message.fail prefix, collection, "has_prefix"
    end

    @doc """
    Checks that the actual result ends with the expected result:

    ## Examples:
        [1 2 3] |> has_suffix [2 3]  ; true
        [1 2 3] |> has_suffix [3 2]  ; false

        {1, 2, 3} |> has_suffix [3] ; true

        "I cannot explain myself for I am not myself" |> has_suffix "myself"

    """
    def has_suffix(collection, suffix) do
      r = case collection do
            c when is_tuple(c) ->
              collection_suffix = Enum.drop(tuple_to_list(collection), tuple_size(collection) - tuple_size(suffix))
              collection_suffix = list_to_tuple(collection_suffix)
              collection_suffix == suffix
            c when is_list(c) ->
              collection_suffix = Enum.drop(collection, Enum.count(collection) - Enum.count(suffix))
              collection_suffix == suffix
            c when is_bitstring(suffix) ->
              String.ends_with?(collection, suffix)
          end

      if (not r), do: Message.fail suffix, collection, "has_suffix"
    end

    @doc """
    Checks whether a predicate holds for all elements in a collection

    ## Examples:
        [1, 3, 5, 7] |> for_all odd(&1)  ; true
        [2, 3, 5, 7] |> for_all odd(&1)  ; false
    """
    def for_all(collection, fun) do
      Enum.all?(collection, fun)
    end

    @doc false
    def for_some(collection, fun) do
    end

  end
end