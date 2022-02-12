defmodule SenseiTest.MongoCase do
  use ExUnit.CaseTemplate

  setup _tags do
    Sensei.Storage.flush()
    :ok
  end
end
