defmodule Amrita.Mixfile do
  use Mix.Project

  def project do
    [app: :amrita,
     version: "0.1.2",
     name: "Amrita",
     source_url: "https://github.com/josephwilk/amrita",
     homepage_url: "http://amrita.io",
     env: [test: [deps: deps],
           dev:  [deps: deps ++ dev_deps]],
           prod: [deps: deps],
     deps: deps]
  end

  def application do
    []
  end

  defp deps do
    [{:meck, "0.7.2", [github: "eproxus/meck"]}]
  end

  defp dev_deps do
    [{:ex_doc, github: "elixir-lang/ex_doc"}]
  end
end
