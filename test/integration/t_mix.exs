Code.require_file "../../test_helper.exs", __FILE__

defmodule Integration.Mix do
  use Amrita.Sweet

  def run(cmd) do
    iolist_to_binary(:os.cmd(%c(sh -c "#{cmd}")))
  end

  setup do
    File.mkdir_p("tmp/test")
    { :ok, [] }
  end

  teardown do
    File.rm_rf!("tmp")
    { :ok, [] }
  end

  facts "about `mix amrita`" do
    fact "supports running tests at a specific line number" do
      File.write!"tmp/test/t_pants.exs", "
defmodule PantsFacts do
  use Amrita.Sweet

  fact \"failing example\" do
    10 |> 11
  end

  fact \"passing example\" do
    10 |> 10
  end
end"

      out = run "mix amrita tmp/test/t_pants.exs:9"

      out |> contains "passing example"
      out |> contains "1 facts, 0 failures"
    end
  end

end