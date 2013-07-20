Code.require_file "../../../../test_helper.exs", __FILE__

defmodule PipelineFacts do
  use Amrita.Sweet
  import Support

  #For now this is impossible:
  # a |> b         => _ |> { :a, _, nil  }
  # true |> falsey => _ |> { :falsey, _, nil }
  # We cannot tell the different between a function and a local var reference.
  future_fact "right hand side is a var" do
    a = "var test"
    b = "var test"

    a |> b

    fail :var do
      a = "var test"
      b = "fail"

      a |> b
    end
  end

  facts "defaults to equals checker" do

    fact "strings" do
      "yes" |> "yes"

      fail :strings do
        "yes" |> "no"
      end
    end

    fact "integers" do
      1 |> 1

      fail :integers do
        1 |> 2
      end
    end

    fact "atoms" do
      :yes |> :yes

      fail :atoms do
        :no |> :yes
      end
    end

    fact "lists" do
      [1, 2, 3] |> [1, 2, 3]

      fail :lists do
        [1, 2, 3] |> [1, 2, 4]
      end
    end

    fact "tuples" do
      { 1, 2, 3 } |> { 1, 2, 3 }

      fail :tuples do
        { 1, 2, 3 } |> { 1, 2, 4 }
      end
    end

    fact "ranges" do
      1..2 |> 1..2

      fail :ranges do
        1..2 |> 1..3
      end
    end

    fact "hashdict" do
      HashDict.new([{:b, 1}, {:a, 2}]) |> HashDict.new([{:b, 1}, {:a, 2}])

      fail :hashdict do
        HashDict.new([{:b, 1}, {:a, 2}]) |> HashDict.new([{:b, 1}, {:a, 6}])
      end
    end

  end

  facts "pipelines non test assertion behaviour" do
    fact "simple" do
      [1, [2], 3] |> List.flatten |> [1, 2, 3]

      fail :simple do
        [1, [2], 3] |> List.flatten |> [1, 2, 4]
      end
    end

    fact "nested" do
      [1, [2], 3] |> List.flatten |> Enum.map(&1 * 2) |> [2, 4, 6]

      fail :nested do
        [1, [2], 3] |> List.flatten |> Enum.map(&1 * 2) |> [2, 4, 9]
      end
    end

    fact "local" do
      [1, [2], 3] |> List.flatten |> local |> [2, 4, 6]

      fail :local do
        [1, [2], 3] |> List.flatten |> local |> [2, 4, 9]
      end
    end

    fact "map" do
      Enum.map([1, 2, 3], &1 |> twice |> twice) |> [4, 8, 12]

      fail :map do
        Enum.map([1, 2, 3], &1 |> twice |> twice) |> [4, 8, 19]
      end
    end

    defp twice(a), do: a * 2

    defp local(list) do
      Enum.map(list, &1 * 2)
    end
  end

  fact "outside of a fact |> behaviours exactly the same as in Elixir" do
    do_something_amrita_pipeline_does_not_support |> 13
  end

  def do_something_amrita_pipeline_does_not_support do
    __MODULE__ |> :constant
  end

  def constant, do: 13

end