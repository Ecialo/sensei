defmodule Sensei.FormServer do
  use GenServer

  alias Sensei.Chat
  alias __MODULE__, as: FormServer
  defstruct [:target, :questions, :answers, :remain_answers]

  def init(init_arg) do
    state = %FormServer{
      target: init_arg[:target],
      questions: init_arg[:questions],
      answers: init_arg[:answers],
      remain_answers: Enum.count(init_arg[:questions])
    }

    {:ok, state, {:continue, :ask_first}}
  end

  def collect_answer(form_server, answer) do
    GenServer.call(form_server, {:answer, answer})
  end

  def handle_continue(:ask_first, state) do
    state = ask_question(state)
    {:noreply, state}
  end

  def handle_call({:answer, answ}, _from, state) do
    state = process_answer(answ, state)

    case state.remain_answers do
      0 ->
        answers = Enum.reverse(state.answers)
        {:stop, :normal, {:done, answers}, state}

      _ ->
        state = ask_question(state)
        {:reply, :continue, state}
    end
  end

  defp ask_question(%FormServer{questions: qs, target: t} = s) do
    case qs do
      [] ->
        s

      [q | rest] ->
        do_ask_question(t, q)
        %{s | questions: rest}
    end
  end

  defp do_ask_question(target, {text, buttons, opts}) do
    Chat.send_message_with_keyboard_reply(target, text, buttons, opts)
  end

  defp do_ask_question(target, {text, buttons}) do
    Chat.send_message_with_keyboard_reply(target, text, buttons)
  end

  defp do_ask_question(target, text) do
    Chat.send_message(target, text)
  end

  defp process_answer(answer, %FormServer{answers: a, remain_answers: ra} = s) do
    %{s | answers: [answer | a], remain_answers: ra - 1}
  end
end
