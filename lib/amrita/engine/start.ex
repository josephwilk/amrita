defmodule Amrita.Engine.Start do
  @moduledoc false

  def now(options \\ []) do
    :application.start(:elixir)
    :application.start(:ex_unit)

    configure(options)

    System.at_exit fn
      0 ->
        failures = Amrita.Engine.Start.run
        System.at_exit fn _ ->
          if failures > 0, do: System.halt(1), else: System.halt(0)
        end
      _ ->
        :ok
    end
  end

  def configure(options) do
    Enum.each options, fn { k, v } ->
      :application.set_env(:ex_unit, k, v)
    end
  end

  def configuration do
    :application.get_all_env(:ex_unit)
  end

  def run do
    { async, sync, load_us } = ExUnit.Server.start_run

    async = Enum.sort async, fn(c,c1) -> c <= c1 end
    sync = Enum.sort  sync, fn(c,c1) -> c <= c1 end
    
    Amrita.Engine.Runner.run async, sync, configuration, load_us
  end

end