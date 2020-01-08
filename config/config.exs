use Mix.Config

config :wafer, Wafer.Driver.Fake, warn: Mix.env() != :test
