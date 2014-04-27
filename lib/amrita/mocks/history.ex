defmodule Amrita.Mocks.History do
  @moduledoc false

  def matches(module, fun) do
    Enum.filter fn_invocations(module), fn { m, f, _a } ->
      m == module && f == fun
    end
  end

  def matches(module, fun, args) do
    matching_fns = matches(module, fun)
    Enum.filter matching_fns, fn { _, _, a } ->
      args_match(args, a)
    end
  end

  def match?(module, fun, args) do
    !Enum.empty?(matches(module, fun, args))
  end

  def fn_invocations(module) do
    Enum.map history(module), fn fn_call ->
      case fn_call do
        {_, fn_invoked, _} -> fn_invoked
        {_, fn_invoked, :error, :function_clause, _} -> fn_invoked
      end
    end
  end

  defp history(module) do
    :meck.history(module)
  end

  defp args_match([expected_arg|t1], [actual_arg|t2]) when is_bitstring(actual_arg) do
    if Regex.regex?(expected_arg) do
       Regex.match?(expected_arg, actual_arg) && args_match(t1, t2)
    else
      (expected_arg == actual_arg) && args_match(t1, t2)
    end
  end

  defp args_match([expected_arg|t1], [actual_arg|t2]) do
    (expected_arg == actual_arg) && args_match(t1, t2)
  end

  defp args_match([], []) do
    true
  end

  defp args_match(_, _) do
    false
  end

end
