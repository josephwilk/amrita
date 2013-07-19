<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="chrome=1">
  <title>Amrita: Polite Testing Framework for Elixir</title>
  <link rel="stylesheet" href="stylesheets/styles.css">
  <link rel="stylesheet" href="stylesheets/pygment_trac.css">
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
  <script src="javascripts/respond.js"></script>
  <!--[if lt IE 9]>
    <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
  <![endif]-->
  <!--[if lt IE 8]>
  <link rel="stylesheet" href="stylesheets/ie.css">
  <![endif]-->
  <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
  <link href='http://fonts.googleapis.com/css?family=EB+Garamond' rel='stylesheet' type='text/css'>
</head>
<body>

<div id="menu-primary" class="menu-container">
  <div class="menu">
 *   [Home](/)
 *   [Docs](/docs/)
 *   [Source](https://github.com/josephwilk/amrita)
 *   [Package](http://expm.co/amrita)
  </div>
</div>

<div class="wrapper">
  <section>
    <div id="title">

# Amrita

A polite, well mannered and thoroughly upstanding testing framework for Elixir

* * *

</div>

## Beautiful tests

A simple and beautiful Amrita test or fact:

```elixir
fact "about factorial" do
  factorial(0) |> ! 0
  factorial(0) |> 1

  list_of_factorials = Enum.map 1..10, fn n -> factorial(n) end

  list_of_factorials |> contains 1
  list_of_factorials |> !contains 2
end
```

## Simple syntax

```elixir
#Equality check
ACTUAL |> [EXPECTED]

#Not equal check
ACTUAL |> ! [EXPECTED]

#Using a checker function
ACTUAL |> CHECKER [EXPECTED]
#or negative form
ACTUAL |> !CHECKER [EXPECTED]
```

## Polite

It's not polite for a testing framework to punching you in the face with words it thinks you should use.
Be it `test` or `facts`/`fact` or `it`/`describes` Amrita supports you.

```elixir
facts "jolly" do
  fact "good" do
  end
end

describe "jolly" do
  it "is good" do
  end
end

test "jolly good" do
end
```

## Test Behaviour with Mocks

Supports testing behaviour with mocks:

```elixir
defmodule Polite do
  def swear? do
    false
  end
end

fact "mocking the swear function to be true" do
  provided [MocksTest.Polite.swear?(_) |> true] do
    Polite.swear("balderdash")? |> truthy
  end
end

# Powerful argument matchers
fact "mocking the swear function to be true" do
  provided [MocksTest.Polite.swear?(fn arg -> arg =~ %r"moo") end |> true] do
    Polite.swear?("is it ok to moo at people") |> truthy
  end
end
```

## Checker based testing

Amrita is all about checkers.

Lets explore them by looking at Amritas own tests:

```elixir
Code.require_file "../test_helper.exs", __FILE__

defmodule ExampleFacts do
  use Amrita.Sweet

  facts "about Amrita checkers" do
    fact "contains checks if an element is in a collection" do
      [1, 2, 4, 5] |> contains 4

      {6, 7, 8, 9} |> contains 9

      [a: 1, :b 2] |> contains {:a, 1}
    end

    fact "! negates a checker" do
      [1, 2, 3, 4] |> !contains 9999

      # or you can add a space, like this. Whatever tickles your fancy.

      [1, 2, 3, 4] |> ! contains 9999

      10 |> ! equal 11
    end

    fact "contains works with strings" do
      "mad hatters tea party" |> contains "hatters"

      "mad hatter tea party" |> contains %r"h(\w+)er"
    end

    fact "has_prefix checks if the start of a collection matches" do
      [1, 2, 3, 4] |> has_prefix [1, 2]

      {1, 2, 3, 4} |> has_prefix {1, 2}

      "I cannot explain myself for I am not myself" |> has_prefix "I"
    end

    fact "has_suffix checks if the end of a collection matches" do
      [1, 2, 3, 4 ,5] |> has_suffix [4, 5]

      {1, 2, 3, 4} |> has_suffix {3, 4}

      "I cannot explain myself for I am not myself" |> has_suffix "myself"
    end

    fact "for_all checks if a predicate holds for all elements" do
      [2, 4, 6, 8] |> for_all even(&1)

      # or alternatively you could write

      [2, 4, 6, 8] |> Enum.all? even(&1)
    end

    fact "odd checks if a number is, well odd" do
      1 |> odd
    end

    fact "even checks is a number if even" do
      2 |> even
    end

    fact "roughly checks if a float within some +-delta matches" do
      0.1001 |> roughly 0.1
    end

    fact "falsey checks if expression evalulates to false" do
      nil |> falsey
    end

    fact "truthy checks if expression evaulates to true" do
      "" |> truthy
    end

    fact "equals checks ==" do
      1 - 10 |> equals -9
    end

    defexception Boom, message: "Golly gosh"

    fact "raises checks if an exception was raised" do
      fn -> raise Boom end |> raises ExampleFacts.Boom
    end
  end

  future_fact "I'm not run yet, just printed as a reminder. Like a TODO" do
    #Never run
    false |> truthy
  end

  fact "a fact without a body is much like a TODO"

  #Backwards compatible with ExUnit
  test "arithmetic" do
    assert 1 + 1 == 2
  end

end
```

## [<span class="octicon octicon-link"></span>](#install)Installing Amrita

Add to your mix.exs

```elixir
  defp deps do
    [
      {:amrita, "~>0.2", github: "josephwilk/amrita"}
    ]
  end
```

After adding Amrita as a dependency, to install please run:

`mix deps.get`

## Want to learn more?

Checkout [Amrita on Github](https://github.com/josephwilk/amrita).

</section>

    </div>
    <!--[if !IE]><script>fixScale(document);</script><![endif]-->

  </body>
</html>
