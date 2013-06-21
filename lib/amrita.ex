defmodule Amrita do
  @moduledoc """
  A polite, well mannered and thoroughly upstanding testing framework for Elixir.
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
    Responsible for loading Amrita within a test module.

        defmodule TestsAboutSomething do
          use Amrita.Sweet
        end
    """

    @doc false
    defmacro __using__(_ // []) do
      quote do
        use ExUnit.Case
        import Kernel, except: [|>: 2]
        import Amrita.Elixir.Pipeline

        import Amrita.Facts
        import Amrita.Describes

        import Amrita.Checkers.Simple
        import Amrita.Checkers.Collection
        import Amrita.Checkers.Exceptions
      end
    end
  end

  defmodule Describes do
    defmacro describe(description, thing // quote(do: _), contents) do
      quote do
        Amrita.Facts.facts(unquote(description), unquote(thing), unquote(contents))
      end
    end

    defmacro it(description, thing // quote(do: _), contents) do
      quote do
        Amrita.Facts.fact(unquote(description), unquote(thing), unquote(contents))
      end
    end

    defmacro it(description) do
      quote do
        Amrita.Facts.fact(unquote(description))
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

  defmodule Message do
    @moduledoc false

    def fail(candidate, {checker, _}) do
      raise Amrita.FactError, actual: candidate,
                              predicate: checker
    end

    def fail(actual, expected, {checker, _}) do
      raise Amrita.FactError, expected: inspect(expected),
                              actual: inspect(actual),
                              predicate: checker
    end

    def pending(message) do
      IO.puts IO.ANSI.escape("%{yellow}" <>  message)
    end
  end

  defmodule Checker do
    @moduledoc false

    def to_s({function_name, arity}, args) do
      to_s(function_name, args)
    end

    def to_s(function_name, args) do
      if args do
        "#{function_name}(#{inspect(args)})"
      else
        "#{function_name})"
      end
    end
  end

  defmodule Checkers.Exceptions do
    import Amrita.Elixir.String

    @doc """
    Checks if an exception was raised and that it was of the expected type or matches the
    expected message.

    ## Example
        fn -> raise Exception end |> raises Exception ; true
        fn -> raise "Jolly jolly gosh" end |> raises %r"j(\w)+y" ; true

        fn -> true end            |> raises Exception ; false
    """
    def raises(function, expected_exception) when is_function(function) do
      try do
        function.()
        Message.fail expected_exception, "No exception raised", __ENV__.function
      rescue
        error in [expected_exception] -> error
        error ->
          name = error.__record__(:name)
          message = error.message

          if name in [ExUnit.AssertionError, ExUnit.ExpectationError, Amrita.FactError] do
            raise(error)
          else
            failed_exception_match(error, expected_exception)
          end
      end
    end

    defp failed_exception_match(error, expected) when is_bitstring(expected) do
      message = error.message
      if not(Amrita.Elixir.String.contains?(expected, message)) do
        Message.fail message, expected, __ENV__.function
      end
    end

    defp failed_exception_match(error, expected) when is_regex(expected) do
      message = error.message
      if not(Regex.match?(expected, message)) do
        Message.fail message, expected, __ENV__.function
      end
    end

    defp failed_exception_match(error, expected) do
      Message.fail error.__record__(:name), expected, __ENV__.function
    end

    @doc false
    def raises(expected_exception) do
      fn function ->
           function |> raises expected_exception
           "raises(#{inspect expected_exception})"
      end
    end
  end

  defmodule Checkers.Simple do
    @moduledoc """
    Checkers for operating on single forms like numbers, atoms, bools, floats, etc.
    """

    import Amrita.Elixir.String

    @doc """
    Check if actual is odd

    ## Example
        2 |> even ; true

    """
    def odd(number) when is_integer(number) do
      r = rem(number, 2) == 1

      if (not r), do: Message.fail number, __ENV__.function
    end

    @doc """
    Check if actual is even

    ## Example
        2 |> even ; true
    """
    def even(number) when is_integer(number) do
      r = rem(number, 2) == 0

      if (not r), do: Message.fail number, __ENV__.function
    end

    @doc """
    Check if `actual` evaluates to precisely true

    ## Example
        "mercury" |> truthy ; true
        nil       |> truthy ; false
    """
    def truthy(actual) do
      if actual do
        r = true
      else
        r = false
      end

      if (not r), do: Message.fail actual, __ENV__.function
    end

    @doc """
    Check if `actual` evaluates to precisely false.

    ## Example
        nil |> falsey ; true
        ""  |> falsey ; false
    """
    def falsey(actual) do
      if actual do
        r = false
      else
        r = true
      end

      if (not r), do: Message.fail actual, __ENV__.function
    end

    @doc """
    Checks if actual is within delta of the expected value.

    ## Example
        0.1 |> roughly 0.2, 0.2  ; true
        0.1 |> roughly 0.01, 0.2 ; false
    """
    def roughly(actual, expected, delta) do
      r = (expected >= (actual - delta)) and (expected <= (actual + delta))

      if (not r), do: Message.fail actual, expected, __ENV__.function
    end

    @doc """
    Checks if actual is a value within 1/1000th of the expected value.

    ## Example
        0.10001 |> roughly 0.1  ; true
        0.20001 |> roughly 0.1  ; false
    """
   def roughly(actual, expected) do
      roughly(actual, expected, 0.01)
    end

    @doc false
    def roughly(expected) do
      fn actual ->
           actual |> roughly expected
           Checker.to_s(__ENV__.function, expected)
      end
    end

    @doc """
    Checks if actual == expected

    ## Example
        1000 |> equals 1000 ; true
        1000 |> equals 0    ; false
    """
    def equals(actual, expected) do
      r = (actual == expected)

      if (not r), do: Message.fail actual, expected, __ENV__.function
    end

    @doc false
    def equals(expected) do
      fn actual ->
           actual |> equals expected
           Checker.to_s(__ENV__.function, expected)
      end
    end

    @doc """
    Negates all following checkers.

    ## Examples

        [1, 2, 3, 4] |> ! contains 999 ; true
        [1, 2, 3, 4] |> ! contains 4   ; false

    """
    def :!.(actual, checker) when is_function(checker) do
      r = try do
        checker.(actual)
      rescue
        error in [Amrita.FactError, ExUnit.AssertionError] -> false
        error -> raise(error)
      end

      if r, do: Message.fail actual, r, __ENV__.function
    end

    def :!.(actual, value) do
      value |> ! equals actual
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
            c when is_bitstring(element) -> Amrita.Elixir.String.contains?(element, c)
          end

      if (not r), do: Message.fail collection, element, __ENV__.function
    end

    @doc false
    def contains(element) do
      fn collection ->
           collection |> contains element
           Checker.to_s(__ENV__.function, element)
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

      if (not r), do: Message.fail prefix, collection, __ENV__.function
    end

    @doc false
    def has_prefix(element) do
      fn collection ->
           collection |> has_prefix element
           Checker.to_s(__ENV__.function, element)
      end
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

      if (not r), do: Message.fail suffix, collection, __ENV__.function
    end

    @doc false
    def has_suffix(element) do
      fn collection ->
           collection |> has_suffix element
           Checker.to_s(__ENV__.function, element)
      end
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