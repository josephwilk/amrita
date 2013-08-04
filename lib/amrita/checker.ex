defmodule Amrita.Checker do
  @moduledoc false

  @moduledoc false
  defmodule Helper do
    defmacro defchecker(name, _ // quote(do: _), contents) do
      { fun_name, _, vars } = name

      neg_args = Enum.drop(vars, 1)
      neg_args = Macro.escape(neg_args)

      expected_arg = Enum.at(vars,1)
      expected_arg = Macro.escape(expected_arg)

      args = Macro.escape(vars)
      contents = Macro.escape(contents)

      quote do
        def(unquote(fun_name), unquote(args), []) do
          import Kernel, except: [|>: 2]
          import Amrita.Elixir.Pipeline

          unquote(contents)
        end

        def(unquote(fun_name), unquote(neg_args), []) do
          name = unquote(fun_name)
          expected = unquote(expected_arg)
          actual = unquote(Enum.take(args,1))
          args = List.concat(actual ,unquote(Enum.drop(args,2 )))
          call_args = unquote(args)

          case Enum.count(unquote(neg_args)) do
            0 -> quote do: fn(actual) -> unquote(name)(actual); {nil, __ENV__.function}
                 end

            _ -> quote do: fn(unquote_splicing(args)) ->
                               unquote(name)(unquote_splicing(call_args)); {unquote(expected), __ENV__.function}
                 end
          end
        end
      end
    end
  end

  def to_s(module, fun, args) do
    to_s "#{inspect(module)}.#{fun}", args
  end

  def to_s({function_name, 1}, _) do
    "#{function_name}"
  end

  def to_s({function_name, _arity}, args) do
    to_s(function_name, args)
  end

  def to_s(:!, { expected, { fun, arity }}) do
    "! " <> to_s({ fun, arity + 1 }, expected)
  end

  def to_s(function_name, args) when is_list(args) do
    str_args = Enum.map args, fn a -> inspect(a) end
    "#{function_name}(#{Enum.join(str_args, ",")})"
  end

  def to_s(function_name, args) do
    "#{function_name}(#{inspect(args)})"
  end

end
