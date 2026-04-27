defmodule TopDeckTutor.Search.Compiler do
  import Ecto.Query

  def compile(ast, queryable) when is_list(ast) do
    Enum.reduce(ast, queryable, &apply_node/2)
  end

  defp apply_node(node, query) do
    where(query, [c, ...], ^node_dynamic(node))
  end

  defp node_dynamic({:not, node}) do
    condition = node_dynamic(node)
    dynamic([c, ...], not (^condition))
  end

  defp node_dynamic({:text, term}) do
    pattern = "%#{term}%"

    dynamic(
      [c, ...],
      ilike(c.name, ^pattern) or
        ilike(c.type_line, ^pattern) or
        ilike(c.oracle_text, ^pattern)
    )
  end

  defp node_dynamic({:field_eq, :type, value}) do
    pattern = "%#{value}%"
    dynamic([c, ...], ilike(c.type_line, ^pattern))
  end

  defp node_dynamic({:field_contains, :name, value}) do
    pattern = "%#{value}%"
    dynamic([c, ...], ilike(c.name, ^pattern))
  end

  defp node_dynamic({:field_contains, :oracle_text, value}) do
    pattern = "%#{value}%"
    dynamic([c, ...], ilike(c.oracle_text, ^pattern))
  end

  defp node_dynamic({:cmp, :mana_value, :<=, value}) do
    dynamic([c, ...], c.mana_value <= ^value)
  end

  defp node_dynamic({:cmp, :mana_value, :>=, value}) do
    dynamic([c, ...], c.mana_value >= ^value)
  end

  defp node_dynamic({:cmp, :mana_value, :==, value}) do
    dynamic([c, ...], c.mana_value == ^value)
  end

  defp node_dynamic({:cmp, :mana_value, :<, value}) do
    dynamic([c, ...], c.mana_value < ^value)
  end

  defp node_dynamic({:cmp, :mana_value, :>, value}) do
    dynamic([c, ...], c.mana_value > ^value)
  end

  defp node_dynamic({:flag, :legendary}) do
    dynamic([c, ...], c.is_legendary == true)
  end
end
