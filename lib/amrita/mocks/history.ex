defmodule History do

  def matches(module, fun) do
    fn_invocations = history(module)

    Enum.filter fn_invocations, fn {_, {m, f, _a}, _} ->
      m == module && f == fun
    end
  end

  def matches(module, fun, args) do
    matching_fns = matches(module, fun)
    Enum.filter(matching_fns, fn {_, {_,_,a}, _} -> args_match(args, a) end)
  end

  def match?(module, fun, args) do
    !Enum.empty?(matches(module, fun, args))
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