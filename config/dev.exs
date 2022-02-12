import Config

config :sensei, Sensei.Storage,
  pool_size: 3,
  database: System.get_env("MONGODB_DATABASE", "sensei_db"),
  seeds: System.get_env("MONGODB_TEST_CLUSTER", "localhost:27017") |> String.split(","),
  username: System.get_env("MONGODB_USER", nil),
  password: System.get_env("MONGODB_PASSWORD", nil)

import_config "secret.exs"
