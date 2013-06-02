Code.require_file "../test_helper.exs", __FILE__

defmodule AmritaFacts do
  use Amrita.Sweet

  #Testing a single fact
  fact "addition" do
    assert 1 + 1 == 2
  end

  #Testing a fact group
  facts "about subtraction" do
    fact "postive numbers" do
      assert 2 - 2 == 0
    end

    fact "negative numbers" do
      assert -2 - -2 == 0
    end
  end

  #Testing multiple depths of facts
  facts "about subtraction" do
    facts "zero results" do
      fact "postive numbers" do
        assert 2 - 2 == 0
      end
      fact "negative numbers" do
        assert -2 - -2 == 0
      end
    end
  end

  #Matchers
  facts "about simple matchers" do
    fact "about odd" do
      1 |> odd
    end

    fact "about even" do
      2 |> even
    end

    fact "truthy" do
      true |> truthy
      []   |> truthy
      ""   |> truthy
    end

    fact "falsey" do
      false |> falsey
      nil   |> falsey
    end

    fact "roughly" do
      0.1001 |> roughly 0.1
    end

    fact "equals" do
      999 |> equals 999
    end
  end

  facts "about collection matchers" do
    fact "contains" do
      [1, 2, 3] |> contains 3

      {4, 5, 6} |> contains 5

      [a: 1, b: 2] |> contains({:a, 1})
    end

    fact "has_prefix" do
      [1, 2, 3] |> has_prefix [1, 2]

      {4, 5, 6} |> has_prefix {4, 5}
    end

    fact "has_suffix" do
      [1, 2, 3, 4, 5] |> has_suffix [3, 4, 5]

      {1, 2, 3, 4, 5} |> has_suffix {3, 4, 5}
    end

    fact "for_all" do
      [2, 4, 6, 8] |> for_all even(&1)

      [2, 4, 6, 8] |> Enum.all? even(&1)
    end

    future_fact "for_some" do
      [2, 4, 7, 8] |> for_some odd(&1)
    end

  end

  test "Backwards compatible with ExUnit" do
    assert 2 + 2 == 4
  end

end
