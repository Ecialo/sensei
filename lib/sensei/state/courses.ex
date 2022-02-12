defmodule Sensei.State.Courses do
  alias Sensei.{
    Storage,
    User,
    Course,
    State
  }

  alias __MODULE__, as: Courses
  @type which() :: :all | :my

  defstruct courses: nil, which: :all

  def new do
    %Courses{which: :all}
  end

  def new(which) do
    %Courses{which: which}
  end

  defimpl Sensei.State.StateProto do
    @new_course "Новый курс"
    @inspect_course "/i"
    @delete_course ""

    def prepare(%Courses{which: :all} = c, _user) do
      {:ok, courses} = Storage.get_all_courses()
      %{c | courses: courses}
    end

    def get_header(%Courses{courses: c}, _user) do
      f_courses =
        Enum.with_index(c)
        |> Enum.map(&format_course/1)
        |> Enum.join("\n")

      """
      Доступные курсы:

      #{f_courses}
      """
    end

    def get_buttons(_, _, _) do
      []
    end

    def handle_command(state, _user, @inspect_course <> pos) do
      i = String.to_integer(pos)
      course = Enum.at(state.courses, i)

      {:change_state, State.Course.new(course)}
    end

    def handle_command(_, _, _) do
    end

    def format_course({course, pos}) do
      schedule = Course.format_schedule(course.schedule)
      sensei = User.format(course.sensei)
      "/i#{pos} — #{course.name}. Ведёт #{sensei} по #{schedule}"
    end

    #   def format_sensei({name, surname, username, uid}) do
    #     first =
    #       case {name, surname, username} do
    #         {name, nil, nil} -> name
    #         {name, surname, nil} -> "#{name} #{surname}"
    #         {_, _, username} -> username
    #       end

    #     case uid do
    #       nil ->
    #         first

    #       uid ->
    #         "[#{first}](tg://user?id=#{uid})"
    #     end
    #   end
  end
end
