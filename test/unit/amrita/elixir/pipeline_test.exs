Code.require_file "../../../../test_helper.exs", __FILE__

defmodule PipelineFacts do
  use Amrita.Sweet
  import Support

  future_fact "right hand side is a var" do
    a = "yes"
    b = "yes"

    a |> b
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

    future_fact "hashdict" do
      HashDict.new |> HashDict.new
    end

  end

end

