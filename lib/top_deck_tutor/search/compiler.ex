defmodule TopDeckTutor.Search.Compiler do
  import Ecto.Query

  def compile(ast, queryable) when is_list(ast) do
    Enum.reduce(ast, queryable, &apply_node/2)
  end

  defp apply_node({:text, term}, query) do
    pattern = "%#{term}%"

    where(
      query,
      [c],
      ilike(c.name, ^pattern) or
        ilike(c.type_line, ^pattern) or
        ilike(c.oracle_text, ^pattern)
    )
  end

  defp apply_node({:field_eq, :type, value}, query) do
    pattern = "%#{value}%"

    where(query, [c], ilike(c.type_line, ^pattern))
  end

  defp apply_node({:cmp, :mana_value, :<=, value}, query) do
    where(query, [c], c.mana_value <= ^value)
  end

  defp apply_node({:cmp, :mana_value, :>=, value}, query) do
    where(query, [c], c.mana_value >= ^value)
  end

  defp apply_node({:cmp, :mana_value, :==, value}, query) do
    where(query, [c], c.mana_value == ^value)
  end

  defp apply_node({:flag, :legendary}, query) do
    where(query, [c], c.is_legendary == true)
  end
end
