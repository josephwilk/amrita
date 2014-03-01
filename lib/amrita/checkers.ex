defmodule Amrita.Checkers do
  @moduledoc false

  defmodule Helper do

    @doc """
    Helper function to create your own checker functions.

    ## Example:

        defchecker thousand(actual) do
          actual |> 1000
        end

        fact "using thousand checker" do
          1000 |> thousand
          1001 |> ! thousand
        end

    """
    defmacro defchecker(name, _ \\ quote(do: _), contents) do
      { fun_name, _, args } = name

      neg_args = Enum.drop(args, 1)
      expected_arg = Enum.at(args,1)

      actual_arg = Enum.take(args,1)
      call_args = Enum.concat(actual_arg, Enum.drop(args,2))
      called_with_args = Enum.concat(actual_arg, Enum.drop(args,1))

      quote do
        def unquote(fun_name)(unquote_splicing(args)) do
          import Kernel, except: [|>: 2]
          import Amrita.Elixir.Pipeline

          unquote(contents)
        end

        def unquote(fun_name)(unquote_splicing(neg_args)) do
          case Enum.count(unquote(neg_args)) do
             0 -> fn(actual) -> unquote(fun_name)(actual); {nil, __ENV__.function} end

             _ -> fn(unquote_splicing(call_args)) ->
                    unquote(fun_name)(unquote_splicing(called_with_args))
                    {unquote(expected_arg), __ENV__.function}
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
