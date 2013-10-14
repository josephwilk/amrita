defmodule Amrita.Elixir.Pipeline do
  @moduledoc false

  import Kernel, except: [|>: 2]

  defmacro left |> right do
    pipeline_op(left, right)
  end

  defp pipeline_op(left, { :|>, _, [middle, right] }) do
    pipeline_op(pipeline_op(left, middle), right)
  end

  defp pipeline_op(left, { call, line, atom }) when is_atom(atom) do
    { call, line, [left] }
  end

  # Comparing to tuples
  defp pipeline_op(left, { :{}, _, _ }=right) do
    quote do
      unquote(left) |> equals unquote(right)
    end
  end

  defp pipeline_op(left, { _, _ }=right) do
    quote do
      unquote(left) |> equals unquote(right)
    end
  end

  # Comparing ranges
  defp pipeline_op({ :.., _, _ }=left, { :.., _, _ }=right) do
    quote do
      unquote(left) |> equals unquote(right)
    end
  end

  # Comparing HashDict
  defp pipeline_op(left, {{ :., _, [{ :__aliases__, _, [:HashDict]}, _] }, _, _ }=right) do
    quote do
      unquote(left) |> Amrita.Checkers.Simple.equals unquote(right)
    end
  end

  # Comparing HashSet
  defp pipeline_op(left, {{ :., _, [{ :__aliases__, _, [:HashSet]}, _] }, _, _ }=right) do
    quote do
      unquote(left) |> Amrita.Checkers.Simple.equals unquote(right)
    end
  end

  defp pipeline_op(left, { call, line, args }=right) when is_list(args) do
    { call, line, [left|args] }
  end

  #Patching pipeline so it supports non-fn values
  defp pipeline_op(left, right) when is_integer(right) or
                                     is_bitstring(right) or
                                     is_atom(right) or
                                     is_list(right) or
                                     is_tuple(right) do
    quote do
      unquote(left) |> Amrita.Checkers.Simple.equals unquote(right)
    end
  end

  defp pipeline_op(left, atom) when is_atom(atom) do
    { { :., [], [left, atom] }, [], [] }
  end

  defp pipeline_op(_, other) do
    pipeline_error(other)
  end

  defp pipeline_error(arg) do
    raise ArgumentError, message: "Unsupported expression in pipeline |> operator: #{Macro.to_string arg}"
  end

end
