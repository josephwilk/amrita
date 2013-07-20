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

  # Comparing tuples
  defp pipeline_op({ :{}, _, _ }=left, { :{}, _, _ }=right) do
    quote do
      unquote(left) |> Amrita.Checkers.Simple.equals unquote(right)
    end
  end

  # Comparing ranges
  defp pipeline_op({ :.., _, _ }=left, { :.., _, _ }=right) do
    quote do
      unquote(left) |> equals unquote(right)
    end
  end

  defp pipeline_op(left, { call, line, args }=right) when is_list(args) do
    case validate_pipeline_args(args) do
      :error -> pipeline_error(right)
      _ -> nil
    end
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

  defp validate_pipeline_args([]), do: nil
  defp validate_pipeline_args([ {:&, _, _ } | _ ]), do: :error
  defp validate_pipeline_args([_|t]) do
    validate_pipeline_args(t)
  end

  defp pipeline_error(arg) do
    raise ArgumentError, message: "Unsupported expression in pipeline |> operator: #{Macro.to_string arg}"
  end

end