defmodule Amrita.Syntax.Describe do
  require ExUnit.Callbacks

  @moduledoc """
  Provides an alternative DSL to facts and fact.
  """
  lc facts_alias inlist [:context, :describe] do
    defmacro unquote(facts_alias)(description, thing // quote(do: _), contents) do
      quote do
        Amrita.Facts.facts(unquote(description), unquote(thing), unquote(contents))
      end
    end
  end

  lc fact_alias inlist [:it, :specify] do
    defmacro unquote(fact_alias)(description, provided // [], meta // quote(do: _), contents) do
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

  defmacro before(scope, var // quote(do: _), block) do
    if scope == :each do
      quote do: ExUnit.Callbacks.setup(unquote(var), unquote(block))
    else
      quote do: ExUnit.Callbacks.setup_all(unquote(var), unquote(block))
    end
  end
end

