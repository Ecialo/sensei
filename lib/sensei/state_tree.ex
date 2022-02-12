defmodule Sensei.StateTree do
  alias Sensei.StateTree.GraphUtils
  @tree Application.get_env(:sensei, :state_tree, %{}) |> GraphUtils.graph_from_naive()
  @backtrack Graph.transpose(@tree)

  def get_prev_state(%state{}) do
    get_prev_state(state)
  end

  def get_prev_state(state) do
    case Graph.out_neighbors(@backtrack, state) do
      [ps] ->
        ps

      [] ->
        state
    end
  end
end
