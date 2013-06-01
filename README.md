#Amrita

[![Build Status](https://travis-ci.org/josephwilk/amrita.png?branch=master)](https://travis-ci.org/josephwilk/amrita)

A polite, well mannered and throughly upstanding testing framework for Elixir.

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

##Setup

Ensure you start Amrita in: test/test_helper.exs
```elixir
Amrita.start
```

##Usage

```elixir
Code.require_file "../test_helper.exs", __FILE__

defmodule ExampleFacts do
  use Amrita.Sweet

  facts "about collections of numbers" do
    fact "contains an element" do
      [1, 2, 4, 5] |> contains 4

      {6, 7, 8, 9} |> contains 9

      [a: 1, :b 2] |> contains {:a, 1}
    end

    fact "has a prefix" do
      [1, 2, 3, 4] |> has_prefix [1, 2]

      {1, 2, 3, 4} |> has_prefix {1, 2}
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

  #Nested tests
  facts "about substraction" do

    fact "negative numbers" do
      1 - 10 |> equals -9
    end
  end

  #Backwards compatible with ExUnit
  test "arithmetic" do
    assert 1 + 1 == 2
  end

end
```

### Polite error messages:

![Polite error message](http://s24.postimg.org/vlj6epnmt/Screen_Shot_2013_06_01_at_22_12_16.png)


## Development

###Running tests

```
make
```

### Docs

http://josephwilk.github.io/amrita/docs

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
