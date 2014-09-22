#Amrita

[![Build Status](https://travis-ci.org/josephwilk/amrita.png?branch=master)](https://travis-ci.org/josephwilk/amrita)

A polite, well mannered and thoroughly upstanding testing framework for [Elixir](http://elixir-lang.org/).

![Elixir of life](http://s2.postimg.org/kmlrx9dp5/6337_33695901.jpg)

NOTE: Support for Elixir 1.0 is current in progress and is hiding here: https://github.com/josephwilk/amrita/tree/chasing-elixir-master until stable.

##Install

Add to your mix.exs

```elixir
  defp deps do
    [
      {:amrita, "~>0.2", github: "josephwilk/amrita"}
    ]
  end
```

After adding Amrita as a dependency, to install please run:

```console
mix deps.get
```

##Getting started

Ensure you start Amrita in: test/test_helper.exs
```elixir
Amrita.start

#Or if you want a more documentation focused formatter:

Amrita.start(formatter: Amrita.Formatter.Documentation)
```

 * Require test_helper.exs in every test (this will ensure Amrita is started):
 * Mix in `Amrita.Sweet` which will bring in everything you need to use Amrita:

```elixir
Code.require_file "../test_helper.exs", __ENV__.file

defmodule ExampleFacts do
  use Amrita.Sweet

  fact "addition" do
    1 + 1 |> 2
  end
end
```

Run your tests through mix:

```shell
$ mix amrita # Run all your tests

$ mix amrita test/integration/t_mocks.ex # Run a specific file

$ mix amrita test/integration/t_mocks.ex:10 # Run a specific test at a line number

$ mix amrita --trace # Show execution time for slow tests
```

Now time to write some tests!

## Prerequisites / Mocks

Amrita supports BDD style mocks.

Examples:

```elixir
defmodule Polite do
  def swear? do
    false
  end

  def swear?(word) do
    false
  end
end
```

#### A Simple mock
```elixir
fact "mock with a wildcard" do
  provided [Polite.swear? |> true] do
    Polite.swear? |> truthy
  end
end
```

#### Wildcard matchers for argument

```elixir
fact "mock with a wildcard"
  provided [Polite.swear?(_) |> true] do
    Polite.swear?(:yes) |> truthy
    Polite.swear?(:whatever) |> truthy
  end
end
```

#### Powerful custom predicates for argument matching
```elixir
fact "mock with a matcher function" do
  provided [Polite.swear?(fn arg -> arg =~ ~r"moo") |> false] do
    Polite.swear?("its ok to moo really") |> falsey
  end
end
```

#### Return values based on specific argument values
```elixir
fact "mock with return based on argument" do
  provided [Polite.swear?(:pants) |> false,
            Polite.swear?(:bugger) |> true] do

    Funk.swear?(:pants) |> falsey
    Funk.swear?(:bugger) |> truthy
  end
end
```

#### Polite Errors explaining when things went wrong

![Polite mock error message](http://s9.postimg.org/wjwdo9dun/Screen_Shot_2013_07_19_at_20_11_17.png)


## Checkers

Amrita is also all about checker based testing!

```elixir
Code.require_file "../test_helper.exs", __ENV__.file

defmodule ExampleFacts do
  use Amrita.Sweet

  facts "about Amrita checkers" do
    
    fact "`equals` checks equality" do
      1 - 10 |> equals -9      
      
      # For convience the default checker is equals
      # So we can write the above as
      1 - 10 |> -9
            
      # Pattern matching with tuples
      { 1, 2, { 3, 4 } } |> equals {1, _, { _, 4 } }

      # Which is the same as 
      { 1, 2, { 3, 4 } } |> {1, _, { _, 4 } }
    end

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

      "mad hatter tea party" |> contains ~r"h(\w+)er"
    end

    fact "has_prefix checks if the start of a collection matches" do
      [1, 2, 3, 4] |> has_prefix [1, 2]

      {1, 2, 3, 4} |> has_prefix {1, 2}

      "I cannot explain myself for I am not myself" |> has_prefix "I"
    end

    fact "has_prefix with a Set ignores the order" do
      {1, 2, 3, 4} |> has_prefix Set.new([{2, 1}])
    end

    fact "has_suffix checks if the end of a collection matches" do
      [1, 2, 3, 4 ,5] |> has_suffix [4, 5]

      {1, 2, 3, 4} |> has_suffix {3, 4}

      "I cannot explain myself for I am not myself" |> has_suffix "myself"
    end

    fact "has_suffix with a Set ignores the order" do
      {1, 2, 3, 4} |> has_suffix Set.new([{4, 3}])
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

    defexception Boom, message: "Golly gosh"

    fact "raises checks if an exception was raised" do
      fn -> raise Boom end |> raises ExampleFacts.Boom
    end
  end

  future_fact "I'm not run yet, just printed as a reminder. Like a TODO" do
    # Never run
    false |> truthy
  end

  fact "a fact without a body is much like a TODO"

  # Backwards compatible with ExUnit
  test "arithmetic" do
    assert 1 + 1 == 2
  end

end
```

## Assertion Syntax with |>

The syntax for assertions is as follows:

```elixir
# Equality check
ACTUAL |> [EXPECTED]
# Not equal check
ACTUAL |> ! [EXPECTED]

# Using a checker function
ACTUAL |> CHECKER [EXPECTED]
# or negative form
ACTUAL |> !CHECKER [EXPECTED]
```


##Custom checkers

Its simple to create your own checkers:

```elixir
  defchecker a_thousand(actual) do
    rem(actual, 1000) |> equals 0
  end

  fact "about 1000s" do
    1000 |> a_thousand   # true
    1200 |> ! a_thousand # true
  end
```

## Polite error messages:

Amrita tries its best to be polite with its errors:

![Polite error message](http://s24.postimg.org/vlj6epnmt/Screen_Shot_2013_06_01_at_22_12_16.png)

## Amrita with Dynamo

Checkout an example using Amrita with Dynamo: https://github.com/elixir-amrita/amrita_with_dynamo

### Plugins

See the wiki for various IDE plugins for Amrita: https://github.com/josephwilk/amrita/wiki/Plugins

## Amrita Development

Hacking on Amrita.

###Running tests

Amrita runs tests against Elixir's latest stable release and against Elixir master.
Make is your friend for running these tests:

```
# Run lastest stable and elixir master
make ci

# Run tests against your current Elixir install
make
```

### Docs

http://josephwilk.github.io/amrita/docs

## Bloody good show

Thanks for reading me, I appreciate it.

Have a good day.

Maybe drink some tea.

Its good for the constitution.

![Tea](http://s15.postimg.org/9dqs4g0wr/tea.png)

##License
(The MIT License)

Copyright (c) 2014 Joseph Wilk

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
