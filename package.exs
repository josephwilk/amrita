version = String.strip(File.read!("VERSION"))

Expm.Package.new(name:        "amrita",
                 description: "A polite, well mannered and thoroughly upstanding testing framework for Elixir",
                 homepage:    "http://amrita.io",
                 version:      version,
                 keywords:     ["testing", "tdd", "bdd", "elixir"],
                 maintainers:  [[name: "Joseph Wilk", email: "joe@josephwilk.net"]],
                 repositories: [[github: "josephwilk/amrita"]])
