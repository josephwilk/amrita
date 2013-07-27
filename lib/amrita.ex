defmodule Amrita do
  @moduledoc """
  A polite, well mannered and thoroughly upstanding testing framework for Elixir.
  """

  @doc """
  Start Amrita for a test run.

  This should be called in your test_helper.exs file.

  Supports optional config:

      # Use a custom formatter. Defaults to Progress formatter.
      Amrita.start(formatter: Amrita.Formatter.Documentation)

  """
  def start(opts // []) do
    formatter = Keyword.get(opts, :formatter, Amrita.Formatter.Progress)
    ExUnit.start formatter: formatter
  end

  @doc """
  Polite version of start.
  """
  def please_start(opts // []) do
    start(opts)
  end

  defmodule Sweet do
    @moduledoc """
    Responsible for loading Amrita within a test module.

    ## Example:
        defmodule TestsAboutSomething do
          use Amrita.Sweet
        end
    """

    @doc false
    defmacro __using__(opts // []) do
      async = Keyword.get(opts, :async, false)
      quote do
        if !Enum.any?(__ENV__.requires, fn(x) -> x == ExUnit.Case end) do
          use ExUnit.Case, async: unquote(async)
        end

        import ExUnit.Callbacks
        import ExUnit.Assertions
        import ExUnit.Case
        @ex_unit_case true

        use Amrita.Facts
        use Amrita.Mocks
        import Amrita.Describes

        import Amrita.Checkers.Simple
        import Amrita.Checkers.Collections
        import Amrita.Checkers.Exceptions
        import Amrita.Checkers.Messages
      end
    end
  end

  defmodule Describes do
    @moduledoc """
    Provides an alternative DSL to facts and fact.
    """

    defmacro describe(description, thing // quote(do: _), contents) do
      quote do
        Amrita.Facts.facts(unquote(description), unquote(thing), unquote(contents))
      end
    end

    defmacro it(description, provided // [], meta // quote(do: _), contents) do
      quote do
        Amrita.Facts.fact(unquote(description), unquote(provided), unquote(meta), unquote(contents))
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

    @doc false
    defmacro __using__(_) do
      quote do
        @name_stack []
        import Amrita.Facts
      end
    end

    defp fact_name(name) do
      if is_binary(name) do
        name
      else
        "#{name}"
      end
    end

    @doc """
    A fact is the container of your test logic.

    ## Example
        fact "about addition" do
          ...
        end

    If you are using mocks you can define them as part of your fact.

    ## Example
        fact "about mock", provided: [Flip.flop(:ok) |> true] do
          Flip.flop(:ok) |> truthy
        end

    You can optionally examine meta data passed to each fact. Useful when used
    with callbacks:

    ## Example
        setup do
          {:ok, ping: "pong"}
        end

        fact "with meta data", meta do
          meta[:pong] |> "pong"
        end
    """
    defmacro fact(description, provided // [], var // quote(do: _), contents) do
      var = case provided do
        [provided: _] -> var
        []            -> var
        _             -> provided
      end

      quote do
        test Enum.join(@name_stack, "") <> unquote(fact_name(description)), unquote(var) do
          import Kernel, except: [|>: 2]
          import Amrita.Elixir.Pipeline

          unquote do
            if is_list(provided) && !Enum.empty?(provided) && match?({:provided, _}, Enum.at(provided, 0)) do
              { :provided, mocks } = Enum.at(provided, 0)
              quote do
                provided unquote(mocks) do
                  unquote(contents)
                end
              end
            else
              quote do
                unquote(contents)
              end
            end
          end
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
        test Enum.join(@name_stack, "") <> unquote(fact_name(description)) do
          Amrita.Message.pending unquote(description)
        end
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
        test Enum.join(@name_stack, "") <> unquote(fact_name(description)) do
          Amrita.Message.pending unquote(description)
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
        @name_stack List.concat(@name_stack, [unquote(fact_name(description)) <> " - "])
        unquote(contents)
        if Enum.count(@name_stack) > 0 do
          @name_stack Enum.take(@name_stack, Enum.count(@name_stack) - 1)
        end
      end
    end
  end

end
