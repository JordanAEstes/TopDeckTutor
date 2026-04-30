defmodule TopDeckTutor.Search.AdvancedForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias TopDeckTutor.Decks

  @primary_key false
  embedded_schema do
    field :name, :string
    field :oracle_text, :string
    field :mana_cost, :string
    field :mana_value, :string
    field :card_type, :string
    field :colors, {:array, :string}, default: []
    field :color_identity, {:array, :string}, default: []
    field :keyword, :string
    field :power, :string
    field :toughness, :string
    field :rarity, :string
    field :legality_status, :string
    field :legality_format, :string
    field :scope, :string, default: "catalog"
    field :deck_ids, {:array, :integer}, default: []
  end

  @cast_fields [
    :name,
    :oracle_text,
    :mana_cost,
    :mana_value,
    :card_type,
    :colors,
    :color_identity,
    :keyword,
    :power,
    :toughness,
    :rarity,
    :legality_status,
    :legality_format,
    :scope,
    :deck_ids
  ]

  @integer_fields [:mana_value, :power, :toughness]

  def build(params, current_scope) when is_map(params) do
    changeset =
      %__MODULE__{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    %{
      changeset: changeset,
      ast: build_ast(changeset),
      scope: build_scope(changeset, current_scope)
    }
  end

  def changeset(form, params) do
    form
    |> cast(normalize_params(params), @cast_fields)
    |> validate_integer_fields()
  end

  def to_query(ast) when is_list(ast) do
    ast
    |> Enum.map(&node_to_query/1)
    |> Enum.join(" ")
  end

  defp build_ast(%Ecto.Changeset{valid?: false}), do: []

  defp build_ast(changeset) do
    values = apply_changes(changeset)

    [
      field_contains_node(:name, values.name),
      field_contains_node(:oracle_text, values.oracle_text),
      field_contains_node(:mana_cost, values.mana_cost),
      integer_cmp_node(:mana_value, values.mana_value, &Decimal.new/1),
      field_eq_node(:type, values.card_type),
      color_node(values.colors),
      color_identity_node(values.color_identity),
      keyword_node(values.keyword),
      integer_cmp_node(:power, values.power, &String.to_integer/1),
      integer_cmp_node(:toughness, values.toughness, &String.to_integer/1),
      field_eq_node(:rarity, values.rarity),
      legality_node(values.legality_format, values.legality_status)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp build_scope(changeset, %{user: user}) when not is_nil(user) do
    values = apply_changes(changeset)

    case values.scope do
      "selected_decks" ->
        owned_ids =
          user
          |> Decks.list_decks_for_user()
          |> Enum.map(& &1.id)
          |> MapSet.new()

        deck_ids = Enum.filter(values.deck_ids, &MapSet.member?(owned_ids, &1))
        {:decks, deck_ids}

      _ ->
        :catalog
    end
  end

  defp build_scope(_changeset, _current_scope), do: :catalog

  defp validate_integer_fields(changeset) do
    Enum.reduce(@integer_fields, changeset, fn field, acc ->
      validate_change(acc, field, fn ^field, value ->
        if value in [nil, ""] or Regex.match?(~r/^-?\d+$/, value) do
          []
        else
          [{field, "must be a whole number"}]
        end
      end)
    end)
  end

  defp normalize_params(params) do
    params
    |> Map.take(Enum.map(@cast_fields, &Atom.to_string/1))
    |> Map.update("colors", [], &normalize_multiselect/1)
    |> Map.update("color_identity", [], &normalize_multiselect/1)
    |> Map.update("deck_ids", [], &normalize_deck_ids/1)
    |> Enum.into(%{}, fn {key, value} -> {String.to_existing_atom(key), normalize_text(value)} end)
  end

  defp normalize_multiselect(values) when is_list(values) do
    values
    |> Enum.map(&normalize_text/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp normalize_multiselect(value), do: normalize_multiselect([value])

  defp normalize_deck_ids(values) when is_list(values) do
    values
    |> Enum.map(&normalize_deck_id/1)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_deck_ids(value), do: normalize_deck_ids([value])

  defp normalize_deck_id(value) when is_integer(value), do: value

  defp normalize_deck_id(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {deck_id, ""} -> deck_id
      _ -> nil
    end
  end

  defp normalize_deck_id(_value), do: nil

  defp normalize_text(value) when is_binary(value), do: String.trim(value)
  defp normalize_text(value), do: value

  defp field_contains_node(_field, value) when value in [nil, ""], do: nil
  defp field_contains_node(field, value), do: {:field_contains, field, value}

  defp field_eq_node(_field, value) when value in [nil, ""], do: nil
  defp field_eq_node(field, value), do: {:field_eq, field, String.downcase(value)}

  defp color_node([]), do: nil
  defp color_node(["C"]), do: {:color, []}
  defp color_node(colors), do: {:color, colors}

  defp color_identity_node([]), do: nil
  defp color_identity_node(colors), do: {:color_identity, colors}

  defp keyword_node(value) when value in [nil, ""], do: nil
  defp keyword_node(value), do: {:keyword, String.downcase(value)}

  defp legality_node(format, status) when format in [nil, ""] or status in [nil, ""], do: nil

  defp legality_node(format, status),
    do: {:legality, String.downcase(format), String.downcase(status)}

  defp integer_cmp_node(_field, value, _converter) when value in [nil, ""], do: nil
  defp integer_cmp_node(field, value, converter), do: {:cmp, field, :==, converter.(value)}

  defp node_to_query({:field_contains, :name, value}), do: "name:#{encode_value(value)}"
  defp node_to_query({:field_contains, :oracle_text, value}), do: "text:#{encode_value(value)}"
  defp node_to_query({:field_contains, :mana_cost, value}), do: "mana:#{encode_value(value)}"
  defp node_to_query({:field_eq, :type, value}), do: "type:#{encode_value(value)}"
  defp node_to_query({:field_eq, :rarity, value}), do: "rarity:#{value}"
  defp node_to_query({:color, []}), do: "color:c"
  defp node_to_query({:color, colors}), do: "color:#{colors |> Enum.join() |> String.downcase()}"

  defp node_to_query({:color_identity, colors}),
    do: "ci:#{colors |> Enum.join() |> String.downcase()}"

  defp node_to_query({:keyword, value}), do: "keyword:#{encode_value(value)}"

  defp node_to_query({:cmp, :mana_value, :==, value}),
    do: "mv=#{Decimal.to_string(value, :normal)}"

  defp node_to_query({:cmp, :power, :==, value}), do: "power=#{value}"
  defp node_to_query({:cmp, :toughness, :==, value}), do: "toughness=#{value}"
  defp node_to_query({:legality, format, status}), do: "#{status}:#{format}"

  defp encode_value(value) do
    if String.contains?(value, " ") do
      ~s("#{value}")
    else
      value
    end
  end
end
