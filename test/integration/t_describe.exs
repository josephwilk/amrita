Code.require_file "../../test_helper.exs", __FILE__

defmodule Integration.Syntax.Describe do
  use Amrita.Sweet

  import Support

  describe "we can use describe in place of facts" do
    it "works like fact" do
      10 |> 10

      fail do
        1 |> 10
      end
    end
  end

  context "we can use context in place of facts" do
    specify "specify works like fact" do
      10 |> 10
    end
  end

  describe "hooks" do
    before_all do
      {:ok, before_all: :ok}
    end

    before_each do
      {:ok, before_each: :ok}
    end

    specify "context information should be available in specs", context do
      assert context[:before_each] == :ok
      assert context[:before_all]  == :ok
    end

    after_each context do
      assert context[:before_each] == :ok
      assert context[:before_all] == :ok
      :ok
    end

    after_all context do
      assert context[:before_each] == nil
      assert context[:before_all] == :ok
      :ok
    end
  end
end
