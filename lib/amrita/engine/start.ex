defmodule Amrita.Engine.Start do
  @moduledoc false

  use Application

  def now(options \\ []) do
    #{:ok, _} = Application.ensure_all_started(:ex_unit)
    
    configure(options)
    if Application.get_env(:ex_unit, :autorun, true) do
          Application.put_env(:ex_unit, :autorun, false)

          System.at_exit fn
            0 ->
              %{failures: failures} = Amrita.Engine.Start.run
              System.at_exit fn _ ->
                if failures > 0, do: exit({:shutdown, 1})
              end
            _ ->
              :ok
          end
        end  end

  def configure(options) do
    Enum.each options, fn { k, v } ->
      Application.put_env(:ex_unit, k, v)
    end
  end

  def configuration do
    Application.get_all_env(:ex_unit)
  end

  def run do
    { async, sync, load_us } = ExUnit.Server.start_run

    async = Enum.sort async, fn(c,c1) -> c <= c1 end
    sync  = Enum.sort  sync, fn(c,c1) -> c <= c1 end
    
    Amrita.Engine.Runner.run async, sync, configuration, load_us
  end

end