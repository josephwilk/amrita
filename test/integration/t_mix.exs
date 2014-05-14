Code.require_file "../../test_helper.exs", __ENV__.file

defmodule Integration.Mix do
  use Amrita.Sweet

  def run_mix(cmd) do
    mix = System.find_executable("mix") || "vendor/elixir/bin/elixir vendor/elixir/bin/mix"
    iodata_to_binary(:os.cmd(~c(sh -c "#{mix} #{cmd}")))
  end

  setup do
    File.mkdir_p("tmp/test")
    { :ok, [] }
  end

  teardown do
    File.rm_rf!("tmp")
    { :ok, [] }
  end

  @pants_template "
defmodule PantsFacts do
  use Amrita.Sweet

  fact \"failing example\" do
    10 |> 11
  end

  fact \"passing example\" do
    10 |> 10
  end
end"

  facts "about `mix amrita`" do
    fact "supports running tests at a specific line number" do
      File.write!"tmp/test/t_pants.exs", @pants_template

      out = run_mix "amrita tmp/test/t_pants.exs:9"

      out |> contains "passing example\n"
      out |> contains "1 facts, 0 failures"
    end

    fact "appends runtime when trace option is specified" do
      File.write!"tmp/test/t_pants_trace.exs", @pants_template

      out = run_mix "amrita tmp/test/t_pants_trace.exs --trace"

      out |> contains ~r/passing example \(.+?ms\)/
      out |> contains ~r/failing example \(.+?ms\)/
      out |> contains "2 facts, 1 failures"
    end
  end
end
