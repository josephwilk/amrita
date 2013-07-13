defmodule Amrita.Mocks.History do
  @moduledoc """
  Find functions from the history of functions executed on a Module.
  """

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
    Enum.map history(module), fn {_, fn_invoked, _} -> fn_invoked end
  end

  defp history(module) do
    :meck.history(module)
  end

  defp args_match([expected_arg|t1], [actual_arg|t2]) when is_regex(expected_arg) and is_bitstring(actual_arg) do
    Regex.match?(expected_arg, actual_arg) && args_match(t1, t2)
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