defmodule Amrita.Pipeline do
  defmacro left |> right do
    pipeline_op(left, right)
  end

  defp pipeline_op(left, { :|>, _, [middle, right] }) do
    pipeline_op(pipeline_op(left, middle), right)
  end

  defp pipeline_op(left, { call, line, atom }) when is_atom(atom) do
    { call, line, [left] }
  end

  defp pipeline_op(left, { call, line, args }) when is_list(args) do
    { call, line, [left|args] }
  end

  defp pipeline_op(left, atom) when is_atom(atom) do
    { { :., [], [left, atom] }, [], [] }
  end

  #Patching pipeline so it supports non-fn values
  defp pipeline_op(left, n) when is_integer(n) or is_bitstring(n) do
    {:equals, [], [left, n]}
  end

  defp pipeline_op(_, other) do
    raise ArgumentError, message: "Unsupported expression in pipeline |> operator: #{inspect other}"
  end
end