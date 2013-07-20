defmodule Amrita.Elixir.Pipeline do
  @moduledoc false

  defmacro left |> right do
    pipeline_op(left, right)
  end

  defp pipeline_op(left, { :|>, _, [middle, right] }) do
    pipeline_op(pipeline_op(left, middle), right)
  end

  defp pipeline_op(left, { call, line, atom }) when is_atom(atom) do
    { call, line, [left] }
  end

  # tuple |> tuple is rewired to perform comparison rather than join.
  defp pipeline_op({:{}, line1, left}, {:{}, line, right}) do
    quote do
      unquote(left) |> Amrita.Checkers.Simple.equals unquote(right)
    end
  end

  defp pipeline_op(left, { call, line, args }) when is_list(args) do
    { call, line, [left|args] }
  end

  #Patching pipeline so it supports non-fn values
  defp pipeline_op(left, right) when is_integer(right) or
                                     is_bitstring(right) or
                                     is_atom(right) or
                                     is_list(right) do
    quote do
      unquote(left) |> Amrita.Checkers.Simple.equals unquote(right)
    end
  end

  defp pipeline_op(_, other) do
    raise ArgumentError, message: "Unsupported expression in pipeline |> operator: #{inspect other}"
  end
end