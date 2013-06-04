defmodule Amrita.Mixfile do
  use Mix.Project

  def project do
    [app: :amrita,
     version: "0.1.0",
     name: "Amrita",
     source_url: "https://github.com/josephwilk/amrita",
     deps: deps]
  end

  def application do
    []
  end

  defp deps do
    [{ :ex_doc, github: "elixir-lang/ex_doc" }]
  end
end
