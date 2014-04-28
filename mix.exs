Code.ensure_loaded?(Hex) and Hex.start

defmodule Amrita.Mixfile do
  use Mix.Project

  def project do
    [app: :amrita,
     version: version,
     name: "Amrita",
     description: "A polite, well mannered and thoroughly upstanding testing framework for Elixir",
     source_url: "https://github.com/josephwilk/amrita",
     elixir: "~> 0.13.0",
     homepage_url: "http://amrita.io",
     package: [links: [{"Website", "http://amrita.io"},
                       {"Source", "http://github.com/josephwilk/amrita"}],
              contributors: ["Joseph Wilk"],
              licenses: ["MIT"]],
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
    [{:meck, [branch: "master" ,github: "eproxus/meck"]}]
  end

  defp dev_deps do
    [{:ex_doc, github: "elixir-lang/ex_doc"}]
  end
end
