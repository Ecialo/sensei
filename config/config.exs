import Config
alias Sensei.State

config :sensei,
  report_time: Time.new!(8, 0, 0),
  reminder_time: Time.new!(20, 0, 0),
  state_tree: %{
    State.Root => %{
      State.Courses => %{
        State.Course => %{}
      }
    }
  }

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :tz, reject_time_zone_periods_before_year: 2010

import_config "#{Mix.env()}.exs"
