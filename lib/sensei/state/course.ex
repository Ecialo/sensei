defmodule Sensei.State.Course do
  alias Sensei.{
    Storage,
    User
  }

  alias __MODULE__, as: StCourse
  defstruct [:course]

  def new(course) do
    %StCourse{course: course}
  end

  defimpl Sensei.State.StateProto do
    @check_in "Хочу!"
    @check_out "Хватит!"
    @confirm "Буду!"
    @refuse "Не буду!"
    @pause "На паузу"
    @unpause "Распаузить"
    @edit "Редактировать"

    def prepare(state, _user) do
      id = state.course.id
      {:ok, course} = Storage.get_course(id)
      %{state | course: course}
    end

    def get_header(state, _user) do
      course = state.course
      sensei = User.format(course.sensei)

      """
      #{course.name}
      __#{course.description}__
      Тренер: #{sensei}
      Проходит по:
      #{inspect(course.schedule)}
      """
    end

    def get_buttons(_state, _user, :admin) do
      []
    end

    def get_buttons(_state, _user, :sensei) do
      []
    end

    def get_buttons(state, user, :supplicant) do
      course = state.course

      if user.id in course.followers do
        [
          {@check_out, "Отписаться"}
        ]
      else
        [
          {@check_in, "Записаться"}
        ]
      end
    end

    def handle_command(state, user, @check_in) do
      new_state = update_in(state.course.followers, &[user.id | &1])

      [
        {:change_state, new_state},
        {:put, new_state.course}
      ]
    end

    def handle_command(state, user, @check_out) do
      new_state = update_in(state.course.followers, &List.delete(&1, user.id))

      [
        {:change_state, new_state},
        {:put, new_state.course}
      ]
    end

    def handle_command(_state, _user, _) do
      nil
    end
  end
end
