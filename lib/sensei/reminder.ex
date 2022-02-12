defmodule Sensei.Reminder do
  use GenServer

  require Logger

  alias Sensei.{
    Storage,
    Chat,
    Message,
    Course
  }

  alias __MODULE__, as: Reminder

  @type t() :: %Reminder{
          timezone: String.t(),
          time_for_reminder: Time.t(),
          time_for_report: Time.t()
        }
  defstruct [:timezone, :time_for_reminder, :time_for_report]

  # def launch_reminders

  def init(init_arg) do
    {:ok, init_arg, {:continue, :schdedule}}
  end

  def handle_continue(:schedule, state) do
    schedule_next_reminder(state)
    schedule_next_report(state)
    {:noreply, state}
  end

  def handle_call(:remind, _from, state) do
    process_reminder(state)
    {:reply, :ok, state}
  end

  def handle_call(:report, _from, state) do
    process_report(state)
    {:reply, :ok, state}
  end

  def handle_info(:remind, state) do
    process_reminder(state)
    schedule_next_reminder(state)
    {:noreply, state}
  end

  def handle_info(:report, state) do
    process_report(state)
    schedule_next_report(state)
    {:noreply, state}
  end

  def schedule_next_reminder(state, current_datetime \\ nil) do
  end

  def schedule_next_report(state, current_datetime \\ nil) do
  end

  def process_report(day_of_week) do
    # current_datetime = current_datetime || DateTime.now(state.timezone)

    {:ok, courses} = Storage.get_all_active_courses_for(day_of_week)

    courses
    |> Stream.each(&commit_report(&1, day_of_week))
    |> Stream.run()
  end

  defp commit_report(course, day_of_week) do
    Logger.debug("Process course #{inspect(course)}")
    msg = format_report(course, day_of_week)
    send_report = fn subscriber -> Chat.send_message(subscriber, msg) end

    sensei_as_subs =
      case course.sensei do
        {_, _, _, nil} -> []
        {_, _, _, id} -> [id]
      end

    Enum.each(course.subscribers ++ sensei_as_subs, send_report)
    Storage.clear_course_confirmations(course)
  end

  @spec process_reminder(DateTime.t()) :: :ok
  def process_reminder(day_of_week) do
    # tommorow = Date.add(current_datetime, 1) |> Date.day_of_week()
    # day_of_week = Date.day_of_week(datetime)

    {:ok, courses} = Storage.get_all_active_courses_for(day_of_week)

    courses
    |> Stream.each(&remind_about_course(&1, day_of_week))
    |> Stream.run()
  end

  defp remind_about_course(course, day_of_week) do
    Enum.each(course.followers, &remind_user_about_course(&1, course, day_of_week))
  end

  defp schedule_event_to_time(event, current_time, target_time) do
    time_to_wait = compute_time_to_wait(current_time, target_time)
    Process.send_after(self(), event, time_to_wait)
  end

  def compute_time_to_wait(current_time, target_time) do
    case Time.compare(current_time, target_time) do
      :lt -> :ok
      _ -> :ok
    end
  end

  defp remind_user_about_course(user_id, course, day_of_week) do
    {message, buttons} = format_reminder(course, day_of_week)
    Chat.send_message_with_inline_keyboard(user_id, message, buttons)
    # Chat.send_message_with_keyboard_reply(user_id, message, buttons, one_time_keyboard: true)
  end

  defp format_reminder(course, day_of_week) do
    time = Course.specify_time(course, day_of_week)

    message = """
    Завтра в #{time} будет тренировка по направлению #{course.name}
    Идёшь?
    """

    # yes = "#{Message.accept_command()} #{course.id}"
    # no = "#{Message.refuse_command()} #{course.id}"
    yes = %{text: "Да!", callback_data: "y_#{course.id}"}
    no = %{text: "Нет...", callback_data: "n_#{course.id}"}

    buttons = [[yes, no]]

    {message, buttons}
  end

  defp format_report(course, day_of_week) do
    confirmed = Enum.count(course.confirmed)
    total = Enum.count(course.followers)
    time = Course.specify_time(course, day_of_week)

    # supplicant_formmater = fn {i, s} -> "#{i + 1}. #{s}" end

    # supplicants =
    #   course.followers
    #   |> Enum.with_index()
    #   |> Enum.map(supplicant_formmater)
    #   |> Enum.join("\n")

    """
    Сегодня в #{time} будет тренировка по направлению #{course.name}
    На ней будет #{confirmed}/#{total} человек:
    """
  end
end
