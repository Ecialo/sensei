defmodule Sensei.Course do
  alias Sensei.User
  alias __MODULE__, as: Course

  @type t() :: %Course{
          id: binary(),
          name: String.t(),
          sensei: User.short_form(),
          schedule: [map()],
          description: String.t(),
          active?: boolean(),
          followers: [User.id()],
          confirmed: [any()],
          subscribers: [any()]
        }

  defstruct [
    :id,
    :name,
    :sensei,
    :schedule,
    :description,
    active?: true,
    followers: [],
    confirmed: [],
    subscribers: []
  ]

  def new(params \\ []) do
    struct(Course, params)
  end

  def format_schedule(schedule) do
    schedule
    |> Enum.map(fn %{"day" => day, "time" => time} -> "#{day} в #{time}" end)
    |> Enum.join(" ")
  end

  def specify_time(course, day_of_week) do
    %{"time" => time} = Enum.find(course.schedule, fn %{"day" => dow} -> dow == day_of_week end)
    time
  end

  def confirm_follower(course, follower_id) do
    if not Enum.member?(course.confirmed, follower_id) do
      update_in(course.confirmed, &[follower_id | &1])
    else
      course
    end
  end

  def unconfirm_follower(course, follower_id) do
    update_in(course.confirmed, &List.delete(&1, follower_id))
  end

  def clear_confirmed(course) do
    %{course | confirmed: []}
  end

  defimpl StructSimplifier.Simplifable do
    alias StructSimplifier.Encoder

    def encode(course) do
      whole_course =
        course
        |> Encoder.naive_encode()
        |> Map.drop(["id"])

      if course.id == nil do
        whole_course
      else
        whole_course
        |> Map.put("_id", BSON.ObjectId.decode!(course.id))
      end
    end
  end

  defimpl StructSimplifier.Desimplifable do
    def decode(s, fields) do
      %{s | id: fields[:_id] |> BSON.ObjectId.encode!()}
    end
  end
end
