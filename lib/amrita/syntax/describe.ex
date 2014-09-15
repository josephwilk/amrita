defmodule Amrita.Syntax.Describe do
  require ExUnit.Callbacks

  @moduledoc """
  Provides an alternative DSL to facts and fact.
  """
  for facts_alias <- [:context, :describe] do
    defmacro unquote(facts_alias)(description, thing \\ quote(do: _), contents) do
      quote do
        Amrita.Facts.facts(unquote(description), unquote(thing), unquote(contents))
      end
    end
  end

  for fact_alias <- [:it, :specify] do
    defmacro unquote(fact_alias)(description, provided \\ [], meta \\ quote(do: _), contents) do
      quote do
        Amrita.Facts.fact(unquote(description), unquote(provided), unquote(meta), unquote(contents))
      end
    end

    defmacro unquote(fact_alias)(description) do
      quote do
        Amrita.Facts.fact(unquote(description))
      end
    end
  end

  defmacro before_each(var \\ quote(do: _), block) do
    quote do: ExUnit.Callbacks.setup(unquote(var), unquote(block))
  end

  defmacro before_all(var \\ quote(do: _), block) do
    quote do: ExUnit.Callbacks.setup_all(unquote(var), unquote(block))
  end

  defmacro after_each(var \\ quote(do: _), block) do
    quote do: ExUnit.Callbacks.on_exit(unquote(var), unquote(block))
  end

  # defmacro after_all(var \\ quote(do: _), block) do
  #   quote do: ExUnit.Callbacks.teardown_all(unquote(var), unquote(block))
  # end
end

