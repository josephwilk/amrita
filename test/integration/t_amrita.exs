Code.require_file "../../test_helper.exs", __ENV__.file

defmodule Integration.AmritaFacts do
  use Amrita.Sweet

  import Support

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
  facts "more about subtraction" do
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

      fail do
        false |> true
      end
    end

    fact "|> defaults to equality when given an atom" do
      :hello |> :hello

      fail do
        :hello |> :bye
      end
    end

    fact "about odd" do
      1 |> odd

      fail do
        2 |> odd
      end
    end

    fact "about even" do
      2 |> even

      fail do
        1 |> even
      end
    end

    fact "truthy" do
      true |> truthy
      []   |> truthy
      ""   |> truthy

      fail do
        false |> truthy
      end
    end

    fact "falsey" do
      false |> falsey
      nil   |> falsey

      fail do
        true |> falsey
      end
    end

    fact "roughly" do
      0.1001 |> roughly 0.1

      0.1 |> roughly 0.2, 0.2

      1 |> roughly 2, 2

      fail do
        0.1 |> equals 0.2
      end
    end

    fact "equals" do
      999 |> equals 999

      fail do
        999 |> equals 998
      end
    end

    fact "msg" do
      fn -> :hello end |> msg(:hello)

      fail do
        fn -> :sod end |> msg(:hello)
      end
    end

    facts "equals with wild cards" do

      fact "tuples use matches when used with equals" do
        { 1, 2, 3 } |> equals { 1, _, 3 }
        # { 1, 2 } is actually a different code path than { 1, 2, 3 }
        { 1, 2 } |> equals { 1, _ }
        { 1, 2, { 1, 2 } } |> equals { 1, _,  { 1, _ } }

        fail do
          { 1, 2, 3 } |> { 2, _, _ }

          { 1, 2, { 1, 2 } } |> equals { 1, _,  { 1, 4 } }
        end
      end

      fact "tuples use equals matcher implicitly" do
        { 1, 2, 3 } |> { 1, _, 3 }
        { 1, 2 } |> { 1, _ }
      end

      fact "lists use matches when used with equals" do
        [ 3, 2, 1 ] |> equals [ 3, _, 1 ]

        fail do
          [ 3, 2, 1 ] |> equals [ 3, _, 2 ]
        end
      end

    end
  end

  facts "about collection matchers" do
    fact "contains" do
      [1, 2, 3] |> contains 3

      {4, 5, 6} |> contains 5

      [a: 1, b: 2] |> contains({:a, 1})

      "mad hatter tea party" |> contains "hatter"

      "mad hatter tea party" |> contains ~r"h(\w+)er"

      fail do
        [1, 2, 3] |> contains 4
        "mad" |> contains "hatter"
      end
    end

    fact "has_prefix" do
      [1, 2, 3] |> has_prefix [1, 2]

      {4, 5, 6} |> has_prefix {4, 5}

      "mad hatter tea party" |> has_prefix "mad"

      fail do
        [1, 2, 3] |> has_prefix [2, 1]
        "mad" |> has_prefix "hatter"
      end
    end

    fact "has_prefix with Sets" do
      [1, 2, 3] |> has_prefix Enum.into([2,1], HashSet.new)
    end

    fact "has_suffix" do
      [1, 2, 3, 4, 5] |> has_suffix [3, 4, 5]

      {1, 2, 3, 4, 5} |> has_suffix {3, 4, 5}

      "white rabbit"  |> has_suffix "rabbit"

      fail do
        [1, 2, 3, 4, 5] |> has_suffix [4, 3, 5]
        "mad" |> has_suffix "hatter"
      end
    end

    fact "hash suffix with Sets" do
      [1, 2, 3] |> has_suffix Enum.into([3,2],HashSet.new)
    end

    fact "for_all" do
      [2, 4, 6, 8] |> for_all(fn(x) -> even(x) end)

      [2, 4, 6, 8] |> Enum.all?(fn(x) -> even(x) end)

      fail do
        [2, 4, 7, 8] |> for_all(fn(x) -> even(x) end)
      end
    end

    fact "for_some" do
      [2, 4, 7, 8] |> for_some(fn(x) -> odd(x) end)

      fail do
        [1, 3, 5, 7] |> for_some(fn(x) -> even(x) end)
      end
    end

    fact "without a body is considered pending"

  end

  facts "message checkers" do
    future_fact "receive" do
      receive |> :hello
      send(self, :hello)
    end

    fact "received" do
      send(self, :hello)
      received |> :hello

      fail "wrong match" do
        send(self, :sod)
        received |> :hello
      end

      fail "never received message" do
        received |> :hello
      end
    end

    fact "received tuples" do
      send(self, { :hello, 1, 2 })
      received |> { :hello, _, 2 }
    end
  end

  defexception TestException, message: "golly gosh, sorry"

  facts "exceptions" do
    fact "should allow checking of exceptions" do
      fn -> raise TestException end |> raises Integration.AmritaFacts.TestException

      fail do
        fn -> true end |> raises Integration.AmritaFacts.TestException
      end
    end

    fact "should allow checking of exceptions by message" do
      fn -> raise TestException end |> raises ~r".*gosh.*"

      fn -> raise TestException end |> raises "golly gosh, sorry"

      fail do
        fn -> raise TestException end |> raises ~r"pants"
      end
    end
  end

  facts "! negates the predicate" do
    fact "contains" do
      [1, 2, 3, 4] |> ! contains 9999

      fail do
        [1, 2, 3, 4] |> ! contains 1
      end
    end

    fact "equals" do
      1999 |> ! equals 0

      fail do
        199 |> ! 199
      end
    end

    fact "roughly" do
      0.1001 |> ! roughly 0.2

      fail do
        0.1001 |> ! roughly 0.1
      end
    end

    fact "has_suffix" do
      [1, 2, 3, 4] |> ! has_suffix [3,1]

      fail do
        [1, 2, 3, 4] |> ! has_suffix [3,4]
      end
    end

    fact "has_prefix" do
      [1, 2, 3, 4] |> ! has_prefix [1, 3]

      fail do
        [1, 2, 3, 4] |> ! has_prefix [1, 2]
      end
    end

    fact "raises" do
      fn -> raise TestException end |> ! raises AmritaFacts.MadeUpException

      fn -> raise TestException end |> ! raises ~r".*posh.*"

      fail do
        fn -> raise TestException end |> ! raises TestException
      end
    end

    fact "|> defaulting to not(equality)" do
      1 |> ! 2

      fail do
        1 |> ! 1
      end
    end

    fact "falsey" do
      true |> ! falsey

      fail do
        false |> ! falsey
      end
    end

    fact "truthy" do
      false |> ! truthy

      fail do
        true |> ! truthy
      end
    end
  end

  test "Backwards compatible with ExUnit" do
    assert 2 + 2 == 4
  end

  facts :atoms_are_ok do
    fact :atoms_still_ok do
      1 |> 1
    end
  end
end
