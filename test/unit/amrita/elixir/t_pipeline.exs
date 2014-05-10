Code.require_file "../../../../test_helper.exs", __ENV__.file

defmodule PipelineFacts do
  use Amrita.Sweet
  import Support

  def example(x) do
    x |> equals 10
  end

  fact "|> supports expected value as a var" do
    a = "var test"
    b = "var test"

    a |> b

    a = 10
    10 |> a

    b = 10
    b |> example

    fail do
      a = "var test"
      b = "fail"

      a |> b

      a = 10
      a |> 11

      b = 11
      10 |> b
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

      fail do
        :no |> :yes
      end
    end

    fact "lists" do
      [1, 2, 3] |> [1, 2, 3]

      fail do
        [1, 2, 3] |> [1, 2, 4]
      end
    end

    fact "tuples" do
      { 1, 2, 3 } |> { 1, 2, 3 }

      fail do
        { 1, 2, 3 } |> { 1, 2, 4 }
      end
    end

    fact "tuples with a pattern match" do
      { 1, 2, 3 } |> { 1, _, 3 }

      fail do
        { 1, 2, 4 } |> { _, 2, 5 }
      end
    end

    fact "lists with a pattern match" do
      [ 1, 2, 3 ] |> [ 1, _, 3 ]

      fail do
        [ 1, 2, 3 ] |> [ 2, _, 3 ]
      end
    end

    fact "ranges" do
      1..2 |> 1..2

      fail do
        1..2 |> 1..3
      end
    end

    fact "hashdict" do
      Enum.into([{:b, 1}], [{:a, 2}]) |> equals Enum.into([{:b, 1}], [{:a, 2}])

      fail do
        Enum.into([{:b, 1}], [{:a, 2}]) |> equals Enum.into([{:b, 1}], [{:a, 6}])
      end
    end

    fact "hashset" do
      HashSet.new([1,2,3]) |> HashSet.new([1,2,3])

      fail do
        HashSet.new([1,2,3]) |> HashSet.new([1,2,4])
      end
    end

  end

  facts "pipelines non test assertion behaviour" do
    fact "simple" do
      [1, [2], 3] |> List.flatten |> [1, 2, 3]

      fail do
        [1, [2], 3] |> List.flatten |> [1, 2, 4]
      end
    end

    fact "nested" do
      [1, [2], 3] |> List.flatten |> Enum.map(&(&1 *2)) |> [2, 4, 6]

      fail do
        [1, [2], 3] |> List.flatten |> Enum.map(fn(x) -> (x * 2) end) |> [2, 4, 9]
      end
    end

  end

end
