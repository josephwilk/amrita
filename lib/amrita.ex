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

    if :application.get_env(:ex_unit, :started) != { :ok, true } do
      :application.set_env(:ex_unit, :started, true)

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
  end

 def configure(options) do
    Enum.each options, fn { k, v } ->
      :application.set_env(:ex_unit, k, v)
    end
  end

def configuration do
    :application.get_all_env(:ex_unit)
  end


  def run do
    { async, sync, load_us } = ExUnit.Server.start_run
    Amrita.Engine.Runner.run async, sync, configuration, load_us
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

        import Amrita.Checker.Helper
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

    defmodule Wrap do
      def assertions([ do: forms ]) when is_list(forms), do: [do: Enum.map(forms, assertions(&1))]

      def assertions([ do: { :provided, [line: line], _mocks } ] = thing) do
        inject_exception_test(thing, line)
      end

      def assertions([ do: thing ]), do: [do: assertions(thing)]

      def assertions({ :__block__, m, forms }) do
        { :__block__, m, Enum.map(forms, assertions(&1)) }
      end

      def assertions({ :|>, [line: line], _args } = test), do: inject_exception_test(test, line)

      def assertions(form), do: form

      defp inject_exception_test(form, line) do
        quote hygiene: [vars: false] do
          try do
            unquote(form); __pid__ <- {self, :fact_finished,  __test__}
          rescue
            error in [Amrita.FactError, Amrita.MockError] ->
              __fail_test__ = __test__.failure { :error, Exception.normalize(:Amrita.FactError, error), System.stacktrace }
              __pid__ <- {self, :fact_finished, __fail_test__}
          end
        end
      end

    end

    defmacro fact(description, provided // [], var // quote(do: _), contents) do
      var = case provided do
        [provided: _] -> var
        []            -> var
        _             -> provided
      end

      quote do
        testz Enum.join(@name_stack, "") <> unquote(fact_name(description)), unquote(var) do
          import Kernel, except: [|>: 2]
          import Amrita.Elixir.Pipeline

          unquote do
            if is_list(provided) && !Enum.empty?(provided) && match?({:provided, _}, Enum.at(provided, 0)) do
              { :provided, mocks } = Enum.at(provided, 0)
              quote do
                provided unquote(mocks) do
                  unquote(Wrap.assertions(contents))
                end
              end
            else
              quote do
                unquote(Wrap.assertions(contents))
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
    
    defmacro testz(message, var // quote(do: _), contents) do
      contents =
        case contents do
          [do: _] ->
            quote do
              unquote(contents)
              :ok
            end
          _ ->
            quote do
              try(unquote(contents))
              :ok
            end
        end

      var      = Macro.escape(var)
      pid_var = {:__pid__, [line: 8], nil}
      pid_var = Macro.escape(pid_var)

      test_var = {:__test__, [line: 8], nil}
      test_var = Macro.escape(test_var)

      contents = Macro.escape(contents, unquote: true)

      quote bind_quoted: binding do
        message = if is_binary(message) do
          :"test #{message}"
        else
          :"test_#{message}"
        end

        def unquote(message)(unquote(var), unquote(pid_var), unquote(test_var))  do
          unquote(contents)
        end
      end
    end
    
    
    
    
    
    
    
  end

end
