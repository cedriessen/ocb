defmodule Ocb.Mixfile do
  use Mix.Project

  def project do
    [
      [
        app: :ocb,
        version: "0.0.1",
        elixir: "~> 1.2",
        deps: deps
      ],
      exdoc,
      escript,
      inch
    ]
    |> merge
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :porcelain, :timex]]
  end

  #
  #
  #

  # ExDoc config
  defp exdoc do
    [
      # ExDoc
      name: "ocb",
      source_url: "https://github.com/cedriessen/ocb",
      docs: [
#        logo: "path/to/logo.png",
        extras: ["README.md", "LICENSE.md"]
      ],
      deps: [
        {:earmark, "~> 0.1", only: :dev},
        {:ex_doc, "~> 0.11", only: :dev}
      ]
    ]
  end

  # InchEx config
  # update with
  # $ MIX_ENV=docs mix inch.report
  # or simply
  # $ mix inch.report
  defp inch do
    [
      preferred_cli_env: ["inch.report": :docs],
      deps: [{:inch_ex, ">= 0.0.0", only: :docs}]
    ]
  end

  # escript config
  # create a standalone application with escript
  defp escript do
    [
      escript: [main_module: Ocb],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
    ]
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
      {:tzdata, "~> 0.1.8", override: true},
    ]
  end

  #
  #
  #

  # Merge a list of keyword lists into one.
  # The values of equal keys are merged into a list.
  defp merge(deps) do
    deps
    |> Enum.reduce(fn dep, acc -> Keyword.merge(dep, acc, &merge/3) end)
  end

  defp merge(_k, v1, v2) when is_list(v1) and is_list(v2), do: v1 ++ v2
  defp merge(_k, v1, v2) when is_list(v1), do: [v2 | v1]
  defp merge(_k, v1, v2) when is_list(v2), do: [v1 | v2]
  defp merge(_k, v1, v2), do: [v1, v2]
end
