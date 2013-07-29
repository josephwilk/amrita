defmodule Amrita.Checker do
  @moduledoc false

  defmodule Helper do
    defmacro defchecker(name, _ // quote(do: _), contents) do
      {fun_name, _, vars} = name

      args = Macro.escape(vars)
      contents = Macro.escape(contents)
      fun_contents = Macro.escape(quote do: fn actual -> actual |> unquote(fun_name)
                                                         {:nil, __ENV__.function}
                                            end)

      quote do
        def unquote(fun_name), unquote(args), [] do
          import Kernel, except: [|>: 2]
          import Amrita.Elixir.Pipeline

          unquote(contents)
        end

        def unquote(fun_name), [],[] do
          unquote(fun_contents)
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
