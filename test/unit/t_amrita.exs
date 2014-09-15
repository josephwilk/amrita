Code.require_file "../../test_helper.exs", __ENV__.file

defmodule Unit.AmritaFacts do
  use Amrita.Sweet

  fixtures = [[[playerA: 0, playerB: 0], :playerA, [playerA: 15, playerB: 0]]]

  facts "Dynamically constructed fact/facts names" do
    for [state, player, expected_state] <- fixtures  do
      @player player
      @state  state
      @expected_state expected_state

      facts "When <#{player}> scores" do
        fact "the new state should be <#{inspect(expected_state)}>" do
          true |> truthy
        end
      end

    end
  end
end
