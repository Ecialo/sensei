defmodule Sensei.State.Root do
  alias __MODULE__, as: Root

  defstruct []

  def new() do
    %Root{}
  end

  defimpl Sensei.State.StateProto do
    alias Sensei.State

    @manage_staff "Персонал"
    @courses "Все курсы"
    @my_courses "Мои курсы"

    def prepare(state, _user) do
      state
    end

    def get_header(_state, _user) do
      "Выберите раздел"
    end

    def get_buttons(_state, _user, :admin) do
      [
        {@manage_staff, "Управление персоналом"}
      ]
    end

    def get_buttons(_state, _user, :sensei) do
      []
    end

    def get_buttons(_state, _user, :supplicant) do
      [
        {@my_courses, "Мои курсы"},
        {@courses, "Все курсы"}
      ]
    end

    def handle_command(_state, user, @manage_staff) do
      if user.role == :admin do
        {:change_state, State.ManageStaff.new()}
      else
        nil
      end
    end

    def handle_command(_state, _user, @courses) do
      {:change_state, State.Courses.new(:all)}
    end

    def handle_command(_state, _user, @my_courses) do
      {:change_state, State.Courses.new(:my)}
    end

    def handle_command(_state, _user, _) do
      nil
    end
  end
end
