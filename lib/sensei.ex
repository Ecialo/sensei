defmodule Sensei do
  use Application

  def create_user(username, role \\ :sensei) do
    user = Sensei.User.new(username: username, role: role)
    Sensei.Storage.put(user)
  end

  def create_course(name, sensei, description, schedule, followers \\ []) do
    course =
      Sensei.Course.new(
        name: name,
        sensei: sensei,
        description: description,
        schedule: schedule,
        followers: followers
      )

    Sensei.Storage.put(course)
  end

  def sample_course do
    Sensei.Course.new(
      name: "Карательная кулинария",
      sensei: {"Alex", "Tortsev", "zloe_aloe", nil},
      description: "Несквик с пивом",
      schedule: [
        %{"day" => 1, "time" => "1100—2200"},
        %{"day" => 2, "time" => "2200—1100"}
      ]
    )
  end

  # def view_course(id) do
  #   Sensei.Storage.Courses.get_course(id)
  # end

  def send_report(day_of_week) do
    Sensei.Reminder.process_report(day_of_week)
  end

  def send_notification(day_of_week) do
    Sensei.Reminder.process_reminder(day_of_week)
  end

  def start(_type, _args) do
    storage_args = Application.get_env(:sensei, Sensei.Storage, [])

    children = [
      {Sensei.Storage, storage_args},
      # Sensei.Reminder,
      Sensei.Poller
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def start_phase(:prepare_dev, :normal, _args) do
    Sensei.Storage.flush()

    create_user("zloe_aloe")

    create_course(
      "Карательная кулинария",
      {"Alex", "Tortsev", "zloe_aloe", 173_990_767},
      "Несквик с пивом",
      [
        %{"day" => 1, "time" => "1100—2200"},
        %{"day" => 2, "time" => "2200—1100"}
      ],
      [173_990_767]
    )

    :ok
  end

  # def start_phase(:setup_webhook, :normal, _args) do
  #   IO.puts("Start webhook")

  #   case {
  #     Application.get_env(:mauricio, :update_provider),
  #     Application.get_env(:mauricio, :url)
  #   } do
  #     {:acceptor, url} when not is_nil(url) ->
  #       Mauricio.Acceptor.set_webhook(url)

  #     {:poller, _} ->
  #       Nadia.delete_webhook()

  #     _anything_else ->
  #       :ok
  #   end
  # end
end
