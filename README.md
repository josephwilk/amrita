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

##Usage

```elixir
defmodule MathFacts do
  use Amrita.Sweet

  #Matchers
  facts "about numbers" do
    fact "odd?" do
      1 |> odd?
    end

    fact "even?" do
      2 |> even?
    end
  end

  facts "about floats" do
    0.1001 |> roughly 0.1
  end

  facts "about true and false" do
    fact "nil is false" do
      nil |> falsey?
    end

    fact "empty list is true" do
      "" |> truthy?
    end
  end

  #Nested tests
  facts "about substraction" do

    #Using assert
    fact "positive numbers" do
      assert 2 - 1 == 1
    end

    #Using |>
    # Default fn of |> is equality
    fact "negative numbers" do
      1 - 10 |> -9
    end
  end

  #Backwards compatible with ExUnit
  test "arithmetic" do
    assert 1 + 1 == 2
  end

end
```

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
