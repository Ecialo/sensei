defmodule Sensei.User do
  alias Sensei.State
  alias __MODULE__, as: User

  @type id() :: integer()
  @type role() :: :admin | :sensei | :supplicant
  @type short_form() :: {String.t(), String.t(), String.t(), integer()}
  # @derive [StructSimplifier.Desimplifable]
  defstruct [:id, :username, :role, :name, :surname, :state, :active?]

  def new(fields) when is_list(fields) do
    struct(User, fields)
    |> change_state(State.Root.new())
  end

  def new(nadia_user) do
    %User{
      id: nadia_user.id,
      username: nadia_user.username,
      role: :supplicant,
      name: nadia_user.first_name,
      surname: nadia_user.last_name,
      state: State.Root.new(),
      active?: true
    }
  end

  def change_state(user, state) do
    %{user | state: state}
  end

  def refine_user(sensei_user, nadia_user) do
    nuser = new(nadia_user)
    %{nuser | role: sensei_user.role, state: sensei_user.state}
  end

  defimpl StructSimplifier.Simplifable do
    alias StructSimplifier.Encoder

    def encode(user) do
      encoded = Encoder.naive_encode(user)
      Map.put(encoded, "_id", encoded["id"])
    end
  end

  def make_short_form(user) do
    {user.name, user.surname, user.username, user.id}
  end

  def format({name, surname, username, uid}) do
    first =
      case {name, surname, username} do
        {name, nil, _} ->
          name

        # {name, surname, nil} -> "#{name} #{surname}"
        {name, surname, _} ->
          "#{name} #{surname}"
          # {_, _, username} -> username
      end

    case uid do
      nil ->
        first

      uid ->
        "[#{first}](tg://user?id=#{uid})"
    end
  end
end
