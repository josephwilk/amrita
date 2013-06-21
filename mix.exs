defmodule Amrita.Mixfile do
  use Mix.Project

  def project do
    [app: :amrita,
     version: "0.1.1",
     name: "Amrita",
     source_url: "https://github.com/josephwilk/amrita",
     homepage_url: "http://amrita.io",
     deps: deps]
  end

  def application do
    []
  end

  defp deps do
    [{:ex_doc, github: "elixir-lang/ex_doc"},
     {:meck, "0.7.2", [github: "eproxus/meck"]}]
  end
end
