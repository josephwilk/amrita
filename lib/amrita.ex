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
    Amrita.start_it formatter: formatter
  end

  @doc """
  Polite version of start.
  """
  def please_start(opts // []) do
    start(opts)
  end

  def start_it(options // []) do
    :application.start(:elixir)
    :application.start(:ex_unit)

    configure(options)

    System.at_exit fn
      0 ->
        failures = Amrita.run
        System.at_exit fn _ ->
          if failures > 0, do: System.halt(1), else: System.halt(0)
        end
      _ ->
        :ok
    end
  end

  @doc """
  Configures ExUnit.

  ## Options

  ExUnit supports the following options:

  * `:formatter` - The formatter that will print results.
                   Defaults to `ExUnit.CLIFormatter`;

  * `:max_cases` - Maximum number of cases to run in parallel.
                   Defaults to `:erlang.system_info(:schedulers_online)`;

  * `:trace` - Set ExUnit into trace mode, this set `:max_cases` to 1
               and prints each test case and test while running;

  """
  def configure(options) do
    Enum.each options, fn { k, v } ->
      :application.set_env(:ex_unit, k, v)
    end
  end

  @doc """
  Returns ExUnit configuration.
  """
  def configuration do
    :application.get_all_env(:ex_unit)
  end

  @doc """
  API used to run the tests. It is invoked automatically
  if ExUnit is started via `ExUnit.start`.

  Returns the number of failures.
  """
  def run do
    { async, sync, load_us } = ExUnit.Server.start_run

    async = Enum.sort(async, fn(c,c1) -> c <= c1 end)
    sync = Enum.sort(sync, fn(c,c1) -> c <= c1 end)

    ExUnit.Runner.run async, sync, configuration, load_us
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

    """
    defmacro fact(description, provided // [], _meta // quote(do: _), contents) do
      quote do
        test unquote(fact_name(description)) do
          import Kernel, except: [|>: 2]
          import Amrita.Elixir.Pipeline

          unquote do
            if is_list(provided) && !Enum.empty?(provided) do
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
        test unquote(fact_name(description)) do
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
        test unquote(fact_name(description)) do
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
        message = if is_binary(unquote(description)) do
                    binary_to_atom(unquote(description))
                  else
                    unquote(description)
                  end

        defmodule Module.concat(__MODULE__, unquote(description)) do
          use ExUnit.Case
          use Amrita.Sweet

          unquote(contents)
        end

      end
    end
  end

end
