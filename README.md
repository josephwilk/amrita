#Amrita

[![Build Status](https://travis-ci.org/josephwilk/amrita.png?branch=master)](https://travis-ci.org/josephwilk/amrita)

A polite, well mannered and throughly upstanding testing framework for [Elixir](http://elixir-lang.org/).

![Elixir of life](http://s9.postimg.org/uv0ubzjm7/elixir.jpg)

##Install

Add to your mix.exs

```elixir
  defp deps do
    [
      {:amrita, "0.1.0", github: "josephwilk/amrita"}
    ]
  end
```

##Getting started

Ensure you start Amrita in: test/test_helper.exs
```elixir
Amrita.start
```

Create a new test file ensuring the filename ends in "_test.exs"

Require your test helper at the top of every test (this will ensure Amrita is started):

```elixir
Code.require_file "../test_helper.exs", __FILE__
```

Define a new module and mix in "Amrita.Sweet" which will bring in everything you need to use Amrita:

test/example_facts_test.exs
```elixir
defmodule ExampleFacts do
  use Amrita.Sweet

end
```

Now all thats left is to  write some tests!

A full example:

```elixir
Code.require_file "../test_helper.exs", __FILE__

defmodule ExampleFacts do
  use Amrita.Sweet

  facts "about collections of numbers" do
    fact "contains checks if an element is in a collection" do
      [1, 2, 4, 5] |> contains 4

      {6, 7, 8, 9} |> contains 9

      [a: 1, :b 2] |> contains {:a, 1}
    end

    fact "contains works with strings" do
      "mad hatters tea party" |> contains "hatters"
    end

    fact "has a prefix" do
      [1, 2, 3, 4] |> has_prefix [1, 2]

      {1, 2, 3, 4} |> has_prefix {1, 2}
    end

    fact "has a suffix" do
      [1, 2, 3, 4 ,5] |> has_suffix [4, 5]

      {1, 2, 3, 4} |> has_suffix {3, 4}
    end

    fact "evens" do
      [2, 4, 6, 8] |> for_all even(&1)

      ; or alternatively you could write

      [2, 4, 6, 8] |> Enum.all? even(&1)
    end

    fact "odds" do
      [1, 3, 5, 7] |> for_all odd(&1)
    end
  end

  facts "about numbers" do
    fact "1 is odd" do
      1 |> odd
    end

    fact "2 is even" do
      2 |> even
    end
  end

  fact "about floats" do
    0.1001 |> roughly 0.1
  end

  facts "about true and false" do
    fact "nil is false" do
      nil |> falsey
    end

    fact "empty list is true" do
      "" |> truthy
    end
  end

  facts "about substraction" do
    fact "negative numbers" do
      1 - 10 |> equals -9
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

## Running your tests

Use mix to run your tests:

```
mix test
``

##Custom matchers

Its simple to create your own matchers:

```elixir
  def a_thousand(actual) do
    rem(actual, 1000) |> equals 0
  end

  fact "about 1000s" do
    1000 |> a_thousand ; true
    1200 |> a_thousand ; false
  end
```

## Polite error messages:

Amrita tries its best to be polite with its errors:

![Polite error message](http://s24.postimg.org/vlj6epnmt/Screen_Shot_2013_06_01_at_22_12_16.png)

## Development

Hacking on Amrita.

###Running tests

```
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

Copyright (c) 2013 Joseph Wilk

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
