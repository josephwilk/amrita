defmodule Amrita.Elixir.String do
  @doc false
  def contains?(element, string) do
    case :binary.matches(string, element) do
      [_] -> true
      []  -> false
    end
  end
end