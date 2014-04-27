Code.require_file "../test_helper.exs", __DIR__

defmodule Integration.MockFacts do
  use Amrita.Sweet

  import Support

  defmodule Polite do
    def swear? do
      false
    end

    def message do
      "oh swizzlesticks"
    end
  end

  fact "check unstubbed module was preserved after stub" do
    Polite.swear? |> falsey
    Polite.message |> "oh swizzlesticks"
  end

  fact "simple mock on existing module" do
    provided [Integration.MockFacts.Polite.swear? |> true] do
      Polite.swear? |> truthy
    end
  end

  failing_fact "provided when not called raises a fail" do
    provided [Integration.MockFacts.Polite.swear? |> true] do
      Polite.message |> "oh swizzlesticks"
    end
  end

  fact "check again that unstubbed module was preserved after stub" do
    Polite.swear? |> falsey
    Polite.message |> "oh swizzlesticks"
  end

  fact "multi mocks on same module" do
    provided [Integration.MockFacts.Polite.swear? |> true,
              Integration.MockFacts.Polite.message |> "funk"] do
      Polite.swear? |> truthy
      Polite.message |> "funk"
    end
  end

  defmodule Rude do
    def swear? do
      true
    end
  end

  fact "multi mocks on different modules" do
    provided [Integration.MockFacts.Polite.swear? |> true,
              Integration.MockFacts.Rude.swear? |> false] do
      Polite.swear? |> truthy
      Rude.swear? |> falsey
    end
  end

  facts "about mocks with fn matcher arguments" do

    fact "fn matches against a regexp" do
      provided [Flip.flop(fn x -> x =~ ~r"moo" end) |> true] do
        Flip.flop("this is a mooo thing") |> true
      end

      fail do
        provided [Flip.flop(fn x -> x =~ ~r"moo" end) |> true] do
          Flip.flop("this is a doo thing") |> true
          Flip.flop("this is a zoo thing") |> true
        end
      end
    end

  end

  facts "about mocks with non checker arguments" do

    defmodule Funk do
      def hip?(_arg) do
        true
      end
    end

    fact "mock with a single argument" do
      provided [Integration.MockFacts.Funk.hip?(:yes) |> false] do
        Funk.hip?(:yes) |> falsey
      end
    end

    facts "mock with elixir types" do
      fact "regex" do
        provided [Integration.MockFacts.Funk.hip?(~r"monkey") |> false] do
          Funk.hip?(~r"monkey") |> falsey
        end

        fail do
          provided [Integration.MockFacts.Funk.hip?(~r"monkey") |> false] do
            Funk.hip?(~r"mon") |> falsey
          end
        end
      end

      fact "list" do
        provided [Integration.MockFacts.Funk.hip?([1, 2, 3]) |> false] do
          Funk.hip?([1, 2, 3]) |> falsey
        end

        fail do
          provided [Integration.MockFacts.Funk.hip?([1, 2, 3]) |> false] do
            Funk.hip?([1, 2, 3, 4]) |> falsey
          end
        end
      end

      fact "tuple" do
        provided [Integration.MockFacts.Funk.hip?({1, 2, 3}) |> false] do
          Funk.hip?({1, 2, 3}) |> falsey
        end

        fail do
          provided [Integration.MockFacts.Funk.hip?({1, 2, 3}) |> false] do
            Funk.hip?({1, 2}) |> falsey
          end
        end
      end

      fact "dict" do
        provided [Integration.MockFacts.Funk.hip?(HashDict.new([{:a,1}])) |> false] do
          Funk.hip?(HashDict.new([{:a, 1}])) |> falsey
        end

        fail do
          provided [Integration.MockFacts.Funk.hip?(HashDict.new([{:a, 1}])) |> false] do
            Funk.hip?(HashDict.new([{:a, 2}])) |> falsey
          end
        end
      end

      fact "range" do
        provided [Integration.MockFacts.Funk.hip?(1..10) |> false] do
          Funk.hip?(1..10) |> falsey
        end

        fail do
          provided [Integration.MockFacts.Funk.hip?(1..10) |> false] do
            Funk.hip?(1..11) |> falsey
          end
        end
      end
    end

    failing_fact "mock with an argument that does not match fails" do
      provided [Integration.MockFacts.Funk.hip?(:yes) |> false] do
        Funk.hip?(:no) |> falsey
      end
    end

    fact "mock with a wildcard" do
      provided [Integration.MockFacts.Funk.hip?(:_) |> false] do
        Funk.hip?(:yes) |> falsey
        Funk.hip?(:whatever) |> falsey
      end
    end

    fact "mock with a _ wildcard" do
      provided [Integration.MockFacts.Funk.hip?(_) |> false] do
        Funk.hip?(:yes) |> falsey
        Funk.hip?(:whatever) |> falsey
      end
    end

    fact "mock anything wildcard" do
      provided [Integration.MockFacts.Funk.hip?(anything, anything, anything) |> false] do
        Funk.hip?(:yes, :no, :maybe) |> falsey
      end
    end

    failing_fact "failing anything wildcard" do
      provided [Integration.MockFacts.Funk.hip?(anything, anything, anything) |> false] do
        Funk.hip?(:yes, :no, :maybe, :funk) |> falsey
      end
    end

    def tiplet do
      "brandy"
    end

    fact "mock with a function defined inside a test" do
      provided [Integration.MockFacts.Funk.hip?(tiplet) |> false] do
        Funk.hip?("brandy") |> falsey
      end
    end

    def tiplet(count) do
      "brandy#{count}"
    end

    fact "mock with a function with args defined inside a test" do
      provided [Integration.MockFacts.Funk.hip?(tiplet(1)) |> true] do
        Funk.hip?("brandy1") |> truthy
      end

      provided [Integration.MockFacts.Funk.hip?(Integration.MockFacts.tiplet(1)) |> true] do
        Funk.hip?("brandy1") |> truthy
      end
    end

    fact "mock with many arguments" do
      provided [Integration.MockFacts.Funk.flop?(:yes, :no, :yes) |> false] do
        Funk.flop?(:yes, :no, :yes) |> falsey
      end
    end

    failing_fact "mock with a mismatch in arity of arguments fails" do
      provided [Integration.MockFacts.Funk.hip?(:yes) |> false] do
        Funk.hip?(:yes, :no) |> falsey
      end
    end

    fact "mock with > 6 arguments" do
      provided [Integration.MockFacts.Funk.flop?(:a, :b, :c, :d, :e, :f, :g, :h) |> false] do
        Funk.flop?(:a, :b, :c, :d, :e, :f, :g, :h) |> falsey
      end
    end

    fact "mock the same function based on different arguments" do
      provided [Integration.MockFacts.Funk.hip?(:cats) |> false, Integration.MockFacts.Funk.hip?(:coffee) |> true] do
        Integration.MockFacts.Funk.hip?(:cats) |> falsey
        Integration.MockFacts.Funk.hip?(:coffee) |> truthy
      end
    end

  end

  fact "mock with a return value as a function" do
    provided [Integration.MockFacts.Funk.hip?(_) |> tiplet(2)] do
      Funk.hip?("brandy") |> "brandy2"
    end

    provided [Integration.MockFacts.Funk.hip?(_) |> tiplet] do
      Funk.hip?("shandy") |> "brandy"
    end

    provided [Integration.MockFacts.Funk.hip?(_) |> Integration.MockFacts.tiplet] do
      Funk.hip?("shandy") |> "brandy"
    end
  end

  fact "mock with a return value as a local var" do
    x = 10
    provided [Integration.MockFacts.Funk.hip?(_) |> x] do
      Funk.hip?("shandy") |> 10
    end
  end

  fact "mock with alternative syntax", provided: [Flip.flop(:ok) |> true] do
    Flip.flop(:ok) |> truthy
  end

end
