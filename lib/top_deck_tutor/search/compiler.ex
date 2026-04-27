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

  defp node_dynamic({:field_eq, :rarity, value}) do
    dynamic([c, ...], c.rarity == ^value)
  end

  defp node_dynamic({:field_eq, :set_code, value}) do
    dynamic([c, ...], c.set_code == ^value)
  end

  defp node_dynamic({:game, value}) do
    dynamic(
      [c, ...],
      fragment(
        "EXISTS (SELECT 1 FROM unnest(?) AS game WHERE lower(game) = ?)",
        c.games,
        ^value
      )
    )
  end

  defp node_dynamic({:keyword, value}) do
    dynamic(
      [c, ...],
      fragment(
        "EXISTS (SELECT 1 FROM unnest(?) AS keyword WHERE lower(keyword) = ?)",
        c.keywords,
        ^value
      )
    )
  end

  defp node_dynamic({:field_contains, :name, value}) do
    pattern = "%#{value}%"
    dynamic([c, ...], ilike(c.name, ^pattern))
  end

  defp node_dynamic({:field_contains, :oracle_text, value}) do
    pattern = "%#{value}%"
    dynamic([c, ...], ilike(c.oracle_text, ^pattern))
  end

  defp node_dynamic({:color_identity, colors}) do
    dynamic([c, ...], fragment("? @> ?", c.color_identity, type(^colors, {:array, :string})))
  end

  defp node_dynamic({:color, []}) do
    dynamic([c, ...], c.colors == ^[])
  end

  defp node_dynamic({:color, colors}) do
    dynamic([c, ...], fragment("? @> ?", c.colors, type(^colors, {:array, :string})))
  end

  defp node_dynamic({:legality, format, status}) do
    dynamic([c, ...], fragment("? ->> ? = ?", c.legalities, ^format, ^status))
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

  defp node_dynamic({:cmp, field, op, value}) when field in [:power, :toughness] do
    numeric_stat_dynamic(field, op, value)
  end

  defp node_dynamic({:field_cmp, left, op, right})
       when left in [:power, :toughness] and right in [:power, :toughness] do
    stat_field_dynamic(left, op, right)
  end

  defp node_dynamic({:flag, :legendary}) do
    dynamic([c, ...], c.is_legendary == true)
  end

  defp numeric_stat_dynamic(field, :<=, value) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^field), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) <= ?", field(c, ^field), ^value)
    )
  end

  defp numeric_stat_dynamic(field, :>=, value) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^field), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) >= ?", field(c, ^field), ^value)
    )
  end

  defp numeric_stat_dynamic(field, :==, value) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^field), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) = ?", field(c, ^field), ^value)
    )
  end

  defp numeric_stat_dynamic(field, :<, value) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^field), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) < ?", field(c, ^field), ^value)
    )
  end

  defp numeric_stat_dynamic(field, :>, value) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^field), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) > ?", field(c, ^field), ^value)
    )
  end

  defp stat_field_dynamic(left, :<=, right) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^left), "^-?[0-9]+$") and
        fragment("? ~ ?", field(c, ^right), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) <= CAST(? AS INTEGER)", field(c, ^left), field(c, ^right))
    )
  end

  defp stat_field_dynamic(left, :>=, right) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^left), "^-?[0-9]+$") and
        fragment("? ~ ?", field(c, ^right), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) >= CAST(? AS INTEGER)", field(c, ^left), field(c, ^right))
    )
  end

  defp stat_field_dynamic(left, :==, right) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^left), "^-?[0-9]+$") and
        fragment("? ~ ?", field(c, ^right), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) = CAST(? AS INTEGER)", field(c, ^left), field(c, ^right))
    )
  end

  defp stat_field_dynamic(left, :<, right) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^left), "^-?[0-9]+$") and
        fragment("? ~ ?", field(c, ^right), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) < CAST(? AS INTEGER)", field(c, ^left), field(c, ^right))
    )
  end

  defp stat_field_dynamic(left, :>, right) do
    dynamic(
      [c, ...],
      fragment("? ~ ?", field(c, ^left), "^-?[0-9]+$") and
        fragment("? ~ ?", field(c, ^right), "^-?[0-9]+$") and
        fragment("CAST(? AS INTEGER) > CAST(? AS INTEGER)", field(c, ^left), field(c, ^right))
    )
  end
end
