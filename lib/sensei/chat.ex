defmodule Sensei.Chat do
  require Logger

  alias Nadia.Model.{
    Update,
    ReplyKeyboardMarkup,
    KeyboardButton,
    InlineKeyboardMarkup,
    InlineKeyboardButton
  }

  alias Sensei.{
    Storage,
    User,
    Course,
    Message,
    State,
    StateTree
  }

  def handle_update(%Update{callback_query: cq}) when not is_nil(cq) do
    uid = cq.from.id

    case cq.data do
      "y_" <> id ->
        case Storage.get_course(id) do
          {:ok, course} ->
            course = Course.confirm_follower(course, uid)
            {[put: course], ["Вы идёте на занятия по #{course.name}"]}

          _ ->
            {[], []}
        end

      "n_" <> id ->
        case Storage.get_course(id) do
          {:ok, course} ->
            course = Course.unconfirm_follower(course, uid)
            {[put: course], ["Вы больше не идёте на занятие по #{course.name}"]}

          _ ->
            {[], []}
        end

      _ ->
        {[], []}
    end
    |> store_and_reply(uid)
  end

  def handle_update(%Update{message: msg, update_id: update_id}) when not is_nil(msg) do
    msg_user = Message.normalize_nadia_user(msg.from)

    user =
      case Storage.get_user(msg_user) do
        {:ok, user} ->
          IO.inspect(user, label: "USER")
          Logger.info("User found", update_id: update_id)
          {:old, user}

        {:error, :no_such_user} ->
          Logger.info("User not found", update_id: update_id)
          {:new, User.new(msg_user)}
      end

    chat_id = Message.extract_chat_id(msg)
    chat_type = Message.extract_chat_type(msg)
    command = Message.extract_command(msg)

    IO.inspect(user)

    case {user, chat_type, command} do
      {{:new, user}, :private, :start} ->
        {to_store, to_reply} = State.describe(user.state, user)
        to_store = [{:put, user} | to_store]
        {to_store, to_reply}

      {{:old, user}, :private, :start} ->
        State.describe(user.state, user)

      {{:old, user}, :private, :back} ->
        new_state = StateTree.get_prev_state(user.state).new() |> IO.inspect(label: "prev_state")
        user = User.change_state(user, new_state)

        {to_store, to_reply} = State.describe(user.state, user)
        to_store = [{:put, user} | to_store]
        {to_store, to_reply}

      {{:old, user}, :private, :stop} ->
        {[delete: user], []}

      {{:old, user}, :private, command} ->
        State.handle_command(user.state, command, user)

      _ ->
        {[], []}
    end
    |> store_and_reply(chat_id)
  end

  def handle_update(_), do: :ok

  def store_and_reply({to_store, to_reply}, chat_id) do
    process_cruds(to_store)
    Logger.debug("To reply #{inspect(to_reply)}")
    process_replies(to_reply, chat_id)
    :ok
  end

  def process_cruds([]), do: :ok

  def process_cruds([crud | rest]) do
    do_crud(crud)
    process_cruds(rest)
  end

  def do_crud({:put, what}) do
    Storage.put(what)
  end

  def do_crud({:delete, what}) do
    Storage.delete(what)
  end

  def do_crud(_) do
    :ok
  end

  def process_replies([], _chat_id), do: :ok

  def process_replies([to_reply | rest], chat_id) do
    Logger.debug("Sending reply #{inspect(to_reply)}")
    send_reply(to_reply, chat_id)
    process_replies(rest, chat_id)
  end

  def send_reply({text, buttons}, chat_id) do
    send_message_with_keyboard_reply(chat_id, text, buttons)
  end

  def send_reply({text, buttons, keyboard_opts}, chat_id) do
    send_message_with_keyboard_reply(chat_id, text, buttons, keyboard_opts)
  end

  def send_reply(text, chat_id) do
    send_message(chat_id, text)
  end

  def send_message(chat_id, text) do
    Logger.debug("Send raw message: #{text}")
    Nadia.send_message(chat_id, text, parse_mode: :Markdown)
  end

  def send_message_with_keyboard_reply(chat_id, text, buttons, keyboard_opts \\ []) do
    Logger.debug("Send message: #{text} with keyboard #{inspect(buttons)}")
    keyboard = make_keyboard(buttons, keyboard_opts)
    Nadia.send_message(chat_id, text, parse_mode: :Markdown, reply_markup: keyboard)
  end

  def send_message_with_inline_keyboard(chat_id, text, buttons) do
    Logger.debug("Send message: #{text} with keyboard #{inspect(buttons)}")
    keyboard = make_inline_keyboard(buttons)
    Nadia.send_message(chat_id, text, parse_mode: :Markdown, reply_markup: keyboard)
  end

  def make_keyboard(buttons, opts \\ []) do
    buttons = Enum.map(buttons, &Enum.map(&1, fn text -> %KeyboardButton{text: text} end))

    %ReplyKeyboardMarkup{
      keyboard: buttons,
      one_time_keyboard: opts[:one_time_keyboard] || false,
      resize_keyboard: opts[:resize_keyboard] || false,
      selective: opts[:selective] || false
    }
  end

  def make_inline_keyboard(buttons) do
    buttons =
      Enum.map(buttons, &Enum.map(&1, fn button -> struct(InlineKeyboardButton, button) end))

    %InlineKeyboardMarkup{inline_keyboard: buttons}
  end
end
