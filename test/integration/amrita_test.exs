Code.require_file "../../test_helper.exs", __FILE__

defmodule AmritaFacts do
  use Amrita.Sweet

  import Support

  describe "something" do
    it "does addition" do
      1 + 1 |> equals 2
    end
  end

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
    fact "|> defaults to equality when given ints or strings" do
      10 |> 10
      "hello" |> "hello"
      [1,2,3,4] |> [1,2,3,4]
      true |> true
      false |> false

      fail "|>" do
        false |> true
      end
    end

    fact "|> defaults to equality when given an atom" do
      :hello |> :hello

      fail "|>" do
        :hello |> :bye
      end
    end

    fact "about odd" do
      1 |> odd

      fail :odd do
        2 |> odd
      end
    end

    fact "about even" do
      2 |> even

      fail :even do
        1 |> even
      end
    end

    fact "truthy" do
      true |> truthy
      []   |> truthy
      ""   |> truthy

      fail :truthy do
        false |> truthy
      end
    end

    fact "falsey" do
      false |> falsey
      nil   |> falsey

      fail :falsey do
        true |> falsey
      end
    end

    fact "roughly" do
      0.1001 |> roughly 0.1

      0.1 |> roughly 0.2, 0.2

      1 |> roughly 2, 2

      fail :roughly do
        0.1 |> equals 0.2
      end
    end

    fact "equals" do
      999 |> equals 999

      fail :equals do
        999 |> equals 998
      end
    end
  end

  facts "about collection matchers" do
    fact "contains" do
      [1, 2, 3] |> contains 3

      {4, 5, 6} |> contains 5

      [a: 1, b: 2] |> contains({:a, 1})

      "mad hatter tea party" |> contains "hatter"

      "mad hatter tea party" |> contains %r"h(\w+)er"

      fail :contains do
        [1, 2, 3] |> contains 4
      end

      fail :contains_with_string do
        "mad" |> contains "hatter"
      end
    end

    fact "has_prefix" do
      [1, 2, 3] |> has_prefix [1, 2]

      {4, 5, 6} |> has_prefix {4, 5}

      "mad hatter tea party" |> has_prefix "mad"

      fail :has_prefix do
        [1, 2, 3] |> has_prefix [2, 1]
      end

      fail :has_prefix_with_string do
        "mad" |> has_prefix "hatter"
      end
    end

    future_fact "has_prefix with Sets" do
      [1, 2, 3] |> has_prefix Amrita.Set.new([2, 1])
    end

    fact "has_suffix" do
      [1, 2, 3, 4, 5] |> has_suffix [3, 4, 5]

      {1, 2, 3, 4, 5} |> has_suffix {3, 4, 5}

      "white rabbit"  |> has_suffix "rabbit"

      fail :has_suffix do
        [1, 2, 3, 4, 5] |> has_suffix [4, 3, 5]
      end

      fail :has_suffix_with_string do
        "mad" |> has_suffix "hatter"
      end
    end

    future_fact "hash suffix with Sets" do
      [1, 2, 3] |> has_suffix Amrita.Set.new([3,2])
    end

    fact "for_all" do
      [2, 4, 6, 8] |> for_all even(&1)

      [2, 4, 6, 8] |> Enum.all? even(&1)

      fail :for_all do
        [2, 4, 7, 8] |> for_all even(&1)
      end
    end

    fact "for_some" do
      [2, 4, 7, 8] |> for_some odd(&1)

      fail :for_some do
        [1, 3, 5, 7] |> for_some even(&1)
      end
    end

    fact "without a body is considered pending"

  end

  facts "message checkers" do
    future_fact "receive" do
      receive |> :hello
      self <- :hello
    end

    future_fact "received" do
      self <- :hello
      received |> :hello
    end
  end

  defexception TestException, message: "golly gosh, sorry"

  facts "exceptions" do
    fact "should allow checking of exceptions" do
      fn -> raise TestException end |> raises AmritaFacts.TestException

      fail :raises do
        fn -> true end |> raises AmritaFacts.TestException
      end
    end

    fact "should allow checking of exceptions by message" do
      fn -> raise TestException end |> raises %r".*gosh.*"

      fn -> raise TestException end |> raises "golly gosh, sorry"

      fail :raises do
        fn -> raise TestException end |> raises %r"pants"
      end
    end
  end

  facts "! negates the predicate" do
    fact "contains" do
      [1, 2, 3, 4] |> ! contains 9999

      fail "! contains" do
        [1, 2, 3, 4] |> ! contains 1
      end
    end

    fact "equals" do
      1999 |> ! equals 0

      fail "! equals" do
        199 |> ! 199
      end
    end

    fact "roughly" do
      0.1001 |> ! roughly 0.2

      fail "! roughly" do
        0.1001 |> ! roughly 0.1
      end
    end

    fact "has_suffix" do
      [1, 2, 3, 4] |> ! has_suffix [3,1]

      fail "! has_suffix" do
        [1, 2, 3, 4] |> ! has_suffix [3,4]
      end
    end

    fact "has_prefix" do
      [1, 2, 3, 4] |> ! has_prefix [1, 3]

      fail "! has_prefix" do
        [1, 2, 3, 4] |> ! has_prefix [1, 2]
      end
    end

    fact "raises" do
      fn -> raise TestException end |> ! raises AmritaFacts.MadeUpException
    end

    fact "|> defaulting to not(equality)" do
      1 |> ! 2

      fail "! |>" do
        1 |> ! 1
      end
    end
  end

  test "Backwards compatible with ExUnit" do
    assert 2 + 2 == 4
  end

end
