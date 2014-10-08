# Small event consumer to handle runner statistics.
defmodule Amrita.Engine.RunnerStats do
  @moduledoc false

  use GenEvent

  def init(_opts) do
    {:ok, %{total: 0, failures: 0, pending: 0}}
  end

  def handle_call(:stop, map) do
    {:remove_handler, map}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {tag, e}}},
                   %{total: total, failures: failures, pending: pending} = map) when tag in [:failed, :invalid] do

    {_kind, reason, _stack} = e
    exception_type = reason.__struct__
    if exception_type == Elixir.Amrita.FactPending do
      {:ok, %{map | total: total + 1, failures: failures, pending: pending + 1 }}
    else
      {:ok, %{map | total: total + 1, failures: failures + 1, pending: pending}}
    end
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:skip, _}}}, map) do
    {:ok, map}
  end

  def handle_event({:test_finished, _}, %{total: total} = map) do
    {:ok, %{map | total: total + 1}}
  end

  def handle_event(_, map) do
    {:ok, map}
  end
end