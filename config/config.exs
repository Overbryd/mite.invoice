# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :mite, api: %{
  account: System.get_env("MITE_ACCOUNT"),
  key: System.get_env("MITE_API_KEY")
}

config :number, currency: [
  unit: "€",
  precision: 2,
  delimiter: ".",
  separator: ",",
  format: "%n",          # "30,00"
  negative_format: "-%n" # "-30.00"
]

