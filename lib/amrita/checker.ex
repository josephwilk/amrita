defmodule Amrita.Checker do
  @moduledoc false

  def to_s(module, fun, args) do
    to_s "#{inspect(module)}.#{fun}", args
  end

  def to_s({function_name, _arity}, args) do
    to_s(function_name, args)
  end

  def to_s(function_name, args) when is_bitstring(args) do
    "#{function_name}(#{args})"
  end

  def to_s(function_name, args) when is_list(args) do
    str_args = Enum.map args, fn a -> inspect(a) end
    "#{function_name}(#{Enum.join(str_args, ",")})"
  end

  def to_s(function_name, args) when is_atom(args) do
    "#{function_name}(#{inspect(args)})"
  end

  def to_s(function_name, args) when args do
    "#{function_name}(#{inspect(args)})"
  end

  def to_s(function_name, _) do
    "#{function_name}"
  end
end