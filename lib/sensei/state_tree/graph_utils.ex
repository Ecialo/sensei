defmodule Sensei.StateTree.GraphUtils do
  def graph_from_naive(naive) do
    g = Graph.new()

    graph_from_naive(g, naive)
  end

  defp graph_from_naive(g, naive) do
    Enum.reduce(
      naive,
      g,
      &add_branch(&2, &1)
    )
  end

  defp add_branch(g, branch) do
    {from, to} = branch
    to_v = Map.keys(to)

    g =
      Enum.reduce(
        to_v,
        g,
        fn k, g -> Graph.add_edge(g, from, k) end
      )

    Enum.reduce(
      to,
      g,
      &add_branch(&2, &1)
    )
  end
end
