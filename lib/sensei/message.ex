defmodule Sensei.Message do
  alias Nadia.Model.Update

  @start_command "/start"
  @stop_command "/stop"
  @show_command "/show"
  @help_command "/help"
  @accept_command "/yes"
  @refuse_command "/no"
  @back_command "◀️"

  def with_message?(%Update{message: nil}), do: false
  def with_message?(_), do: true

  def extract_chat_type(message) do
    # IO.inspect(message)
    chat = message.chat

    case chat.type do
      "private" -> :private
      _ -> :group
    end
  end

  def extract_chat_id(message) do
    message.chat.id
  end

  def extract_command(message) do
    case message.text do
      @start_command <> _rest -> :start
      @stop_command <> _rest -> :stop
      @back_command <> _rest -> :back
      nil -> nil
      command -> command
    end
  end

  def normalize_nadia_user(nadia_user) do
    username = nadia_user.username && String.downcase(nadia_user.username)
    %{nadia_user | username: username}
  end

  def accept_command do
    @accept_command
  end

  def refuse_command do
    @refuse_command
  end
end
