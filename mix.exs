defmodule Ocb.Mixfile do
  use Mix.Project

  def project do
    [app: :ocb,
     version: "0.0.1",
     elixir: "~> 1.2",
     # create a standalone application with escript
     escript: [main_module: Ocb],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :porcelain, :timex]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:porcelain, "~> 2.0"},
      {:dir_walker, github: "pragdave/dir_walker", ref: "b34b1b6a9bfcbc1e5d0bbfcd7d8549952f601469"},
      {:dialyze, "~> 0.2.0"},
      {:timex, "~> 1.0.1"},
      # Use Tzdata 0.1.8 since the latest version has issues with escript builds.
      # See https://github.com/bitwalker/timex/issues/86
      {:tzdata, "~> 0.1.8", override: true}
    ]
  end
end
