defmodule Amrita.Checkers.Messages do
  alias Amrita.Message, as: Message

  @moduledoc """
  Checkers relating to messages.
  """


  @doc """
  Returns a function to return the received message with parameters for
  checking

  ## Examples
      self <- :hello
      received |> msg(:hello)

  """
  def received, do: fn -> _received end

  @doc false
  def _received do
    timeout = 0
    receive do
      other -> other
    after
      timeout ->
        Message.fail("Expected to have received message", __ENV__.function)
    end
  end
end
