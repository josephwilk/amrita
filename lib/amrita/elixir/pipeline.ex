defmodule Amrita.Elixir.Pipeline do
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

  #Patching to ensure boolean is passed on to Amrita equality case
  defp pipeline_op(left, atom) when is_atom(atom) and !is_boolean(atom) do
    { { :., [], [left, atom] }, [], [] }
  end

  #Patching pipeline so it supports non-fn values
  defp pipeline_op(left, right) when is_integer(right) or
                                     is_bitstring(right) or
                                     is_boolean(right) or
                                     is_list(right) do
    quote do
      unquote(left) |> Amrita.Checkers.Simple.equals unquote(right)
    end
  end

  defp pipeline_op(_, other) do
    raise ArgumentError, message: "Unsupported expression in pipeline |> operator: #{inspect other}"
  end
end