defmodule Amrita.Mixfile do
  use Mix.Project

  def project do
    [app: :amrita,
     version: version,
     name: "Amrita",
     source_url: "https://github.com/josephwilk/amrita",
     elixir: "~> 0.10.3",
     homepage_url: "http://amrita.io",
     env: [test: [deps: deps],
           dev:  [deps: deps ++ dev_deps]],
     deps: deps]
  end

  def version do
    String.strip(File.read!("VERSION"))
  end

  def application do
    []
  end

  defp deps do
    [{:meck, [branch: "develop" ,github: "eproxus/meck"]}]
  end

  defp dev_deps do
    [{:ex_doc, github: "elixir-lang/ex_doc"}]
  end
end
