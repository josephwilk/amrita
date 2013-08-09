Code.require_file "../../../../test_helper.exs", __FILE__

defmodule HistoryFacts do
  use Amrita.Sweet

  alias Amrita.Mocks.History, as: History

  #Example of meck history
  #[{#PID<0.301.0>,{Faker,:shout,["the mighty BOOSH"]},"the mighty BOOSH"}]

  facts "about History.match?" do
    fact "regex arguments match bit_string arguments" do
      :meck.new(Faker, [:non_strict])
      :meck.expect(Faker, :shout, fn x -> x end)
      :meck.expect(Faker, :whisper, fn x -> x end)

      Faker.shout("the mighty BOOSH")
      Faker.whisper("journey through space and time")

      History.match?(Faker, :shout, [%r"mighty"]) |> truthy
      History.match?(Faker, :shout, [%r"wrong"]) |> falsey
    end

    fact "regex arguments match regex arguments" do
      :meck.new(Saker, [:non_strict])
      :meck.expect(Saker, :shout, fn x -> x end)
      :meck.expect(Saker, :whisper, fn x -> x end)

      Saker.shout(%r"funk")
      Saker.whisper("shh")

      History.match?(Saker, :shout, [%r"funk"]) |> truthy
      History.match?(Saker, :shout, [%r"sunk"]) |> falsey
    end

  end
end