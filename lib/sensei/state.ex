defprotocol Sensei.State.StateProto do
  def prepare(state, user)
  def get_header(state, user)
  def get_buttons(state, user, role)

  def handle_command(state, user, command)
end

defmodule Sensei.State do
  alias Sensei.User
  alias Sensei.State.StateProto

  def handle_command(state, command, user) do
    StateProto.handle_command(state, user, command)
    |> process_commands(user)
  end

  defp process_commands(commands, user) when is_list(commands) do
    commands
    |> Enum.map(&expand(&1, user))
    |> IO.inspect()
    |> Enum.reduce({[], []}, &merge/2)
    |> IO.inspect()
  end

  defp process_commands(commands, user) do
    process_commands([commands], user)
  end

  def expand({:change_state, new_state}, user) do
    new_user = User.change_state(user, new_state)
    describe(new_state, new_user)
  end

  def expand({:put, what}, _user) do
    {[put: what], []}
  end

  def expand(nil, _user) do
    {[], []}
  end

  def describe(state, user) do
    state = StateProto.prepare(state, user)
    user = User.change_state(user, state)

    header = StateProto.get_header(state, user)

    admb = fn -> StateProto.get_buttons(state, user, :admin) end
    senb = fn -> StateProto.get_buttons(state, user, :sensei) end
    supb = fn -> StateProto.get_buttons(state, user, :supplicant) end

    buttons =
      case user.role do
        :admin ->
          [
            supb.(),
            senb.(),
            admb.()
          ]

        :sensei ->
          [
            supb.(),
            senb.()
          ]

        :supplicant ->
          [
            supb.()
          ]
      end

    make_description(header, buttons)
    |> merge({[put: user], []})
  end

  def make_description(header, buttons_with_description) do
    buttons = extract_buttons(buttons_with_description)

    {
      [],
      [{header, buttons ++ [["◀️"]], one_time_keyboard: true}]
    }

    # case Enum.concat(buttons) do
    #   [] ->
    #     {[], [header]}

    #   _ ->
    #     {[], [{header, buttons}]}
    # end
  end

  def extract_buttons(buttons_with_description) do
    buttons_with_description
    |> Enum.map(&Enum.map(&1, fn x -> elem(x, 0) end))
    |> Enum.reject(&(&1 == []))
  end

  def merge({to_store_r, to_reply_r}, {to_store_l, to_reply_l}) do
    {to_store_l ++ to_store_r, to_reply_l ++ to_reply_r}
  end
end
