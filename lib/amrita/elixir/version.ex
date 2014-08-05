defmodule Amrita.Elixir.Version do
  @moduledoc false

  def less_than_or_equal?(version) do
    elixir_version = as_ints

    Enum.fetch!(elixir_version, 0) < Enum.fetch!(version, 0) ||
    Enum.fetch!(elixir_version, 0) == Enum.fetch!(version, 0) && Enum.fetch!(elixir_version, 1) < Enum.fetch!(version, 1) ||
    Enum.fetch!(elixir_version, 0) == Enum.fetch!(version, 0) && Enum.fetch!(elixir_version, 1) == Enum.fetch!(version, 1) && Enum.fetch!(elixir_version, 2) <= Enum.fetch!(version, 2)
  end


  def as_ints do
    elixir_version = String.split(System.version, ~r"[\.-]")
    Enum.map elixir_version, fn x -> if x != "dev", do: String.to_integer(x) end
  end
end