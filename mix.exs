defmodule Mite.MixProject do
  use Mix.Project

  def project do
    [
      app: :mite,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :timex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # html safety of strings
      {:phoenix_html, "~> 2.10"},
      # handle time/dates
      {:timex, "~> 3.1"},
      # handle number formatting
      {:number, "~> 0.5.4"},
      # httpoison is a http client
      {:httpoison, "~> 1.0"},
      # poison is our json en/decoder
      {:poison, "~> 3.1"}
    ]
  end
end
