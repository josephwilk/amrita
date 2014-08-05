Code.ensure_loaded?(Hex) and Hex.start

defmodule Amrita.Mixfile do
  use Mix.Project

  def project do
    [app: :amrita,
     version: version,
     name: "Amrita",
     description: "A polite, well mannered and thoroughly upstanding testing framework for Elixir",
     source_url: "https://github.com/josephwilk/amrita",
     elixir: "~> 0.15.0",
     homepage_url: "http://amrita.io",
     package: [links: [{"Website", "http://amrita.io"},
                       {"Source", "http://github.com/josephwilk/amrita"}],
              contributors: ["Joseph Wilk"],
              licenses: ["MIT"]],
     deps: deps(Mix.env)]
  end

  def version do
    String.strip(File.read!("VERSION"))
  end

  def application do
    []
  end

  defp deps(:dev) do
    base_deps
  end

  defp deps(:test) do
    base_deps ++ dev_deps
  end
  
  defp deps(_) do
    base_deps
  end

  defp base_deps do
    [{:meck, [branch: "master" ,github: "eproxus/meck"]}]
  end

  defp dev_deps do
    [{:ex_doc, github: "elixir-lang/ex_doc"}]
  end
end
