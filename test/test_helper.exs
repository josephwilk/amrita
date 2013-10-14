defmodule Support do
  defexception FactDidNotFail, [:line, :file, :form] do
    def message(exception) do
      "Expected:\n" <>
        "      #{Macro.to_string(exception.form)} " <> exception.location <> "\n" <>
        "      to fail but it passed."
    end

    def location(exception) do
      IO.ANSI.escape_fragment("%{cyan}") <>
        "# #{Path.relative_to(exception.file, System.cwd)}:#{exception.line}" <>
        IO.ANSI.escape_fragment("%{red}")
    end
  end

  defmacro failing_fact(name, _ // quote(do: _), contents) do
    quote do
      fact unquote(name) do
        fail unquote(name) do
          unquote(Support.Wrap.assertions(contents))
        end
      end
    end
  end

  defmacro fail(_name // "", _ // quote(do: _), contents) do
    Support.Wrap.assertions(contents)
  end

  defmodule Wrap do
    def assertions([ do: forms ]) when is_list(forms), do: [do: Enum.map(forms, &assertions(&1))]

    def assertions([ do: { :provided, [line: line], [a, mocks] } ]) do
      inject_exception_test([ do: { :provided, [line: line], [a, assertions(mocks)]}], line)
    end

    def assertions([ do: thing ]), do: [do: assertions(thing)]

    def assertions({ :__block__, m, forms }) do
      { :__block__, m, Enum.map(forms, &assertions(&1)) }
    end

    def assertions({ :|>, [line: line], _args } = test) do
      inject_exception_test(test, line)
    end

    def assertions(form), do: form

    defp inject_exception_test(form, line) do
      quote do
        try do
          unquote(form)

          raise FactDidNotFail, file: __ENV__.file, line: unquote(line), form: unquote(Macro.escape(form))
        catch
          #Raised by :meck when a match is not found with a mock
          :error, error in [:function_clause, :undef] -> true
        rescue
          error in [Amrita.FactError, Amrita.MockError] -> true
        end
      end
    end

  end
end

if Amrita.Elixir.Version.less_than_or_equal?([0, 9, 3]) do
  Amrita.start
else
  Amrita.start(formatter: Amrita.Formatter.Documentation)
end
