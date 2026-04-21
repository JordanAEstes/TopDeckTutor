defmodule TopDeckTutor.Cards.Normalizer do
  @moduledoc false

  def from_scryfall(card) when is_map(card) do
    primary_face = primary_face(card)
    type_line = card_field(card, primary_face, "type_line", "")
    name = card_name(card, primary_face)

    %{
      id: card["id"],
      oracle_id: card_field(card, primary_face, "oracle_id"),
      name: name,
      normalized_name: normalize_name(name),
      lang: Map.get(card, "lang", "en"),
      mana_cost: card_field(card, primary_face, "mana_cost"),
      mana_value: to_decimal(card["cmc"]),
      type_line: type_line,
      oracle_text: card_field(card, primary_face, "oracle_text"),
      colors: card_field(card, primary_face, "colors", []),
      color_identity: Map.get(card, "color_identity", []),
      keywords: Map.get(card, "keywords", []),
      produced_mana: card_field(card, primary_face, "produced_mana", []),
      power: card_field(card, primary_face, "power"),
      toughness: card_field(card, primary_face, "toughness"),
      loyalty: card_field(card, primary_face, "loyalty"),
      layout: card["layout"],
      released_at: parse_date(card["released_at"]),
      set_code: card["set"],
      set_name: card["set_name"],
      set_type: card["set_type"],
      collector_number: card["collector_number"],
      rarity: card["rarity"],
      legalities: Map.get(card, "legalities", %{}),
      games: Map.get(card, "games", []),
      finishes: Map.get(card, "finishes", []),
      reserved: Map.get(card, "reserved", false),
      game_changer: Map.get(card, "game_changer", false),
      digital: Map.get(card, "digital", false),
      foil: Map.get(card, "foil", false),
      nonfoil: Map.get(card, "nonfoil", false),
      oversized: Map.get(card, "oversized", false),
      promo: Map.get(card, "promo", false),
      reprint: Map.get(card, "reprint", false),
      variation: Map.get(card, "variation", false),
      full_art: Map.get(card, "full_art", false),
      textless: Map.get(card, "textless", false),
      booster: Map.get(card, "booster", false),
      story_spotlight: Map.get(card, "story_spotlight", false),
      is_creature: String.contains?(type_line, "Creature"),
      is_land: String.contains?(type_line, "Land"),
      is_instant: String.contains?(type_line, "Instant"),
      is_sorcery: String.contains?(type_line, "Sorcery"),
      is_artifact: String.contains?(type_line, "Artifact"),
      is_enchantment: String.contains?(type_line, "Enchantment"),
      is_planeswalker: String.contains?(type_line, "Planeswalker"),
      is_legendary: String.contains?(type_line, "Legendary"),
      image_uris: card_field(card, primary_face, "image_uris", %{}),
      artist: card_field(card, primary_face, "artist"),
      border_color: card["border_color"],
      frame: card["frame"],
      edhrec_rank: card["edhrec_rank"],
      penny_rank: card["penny_rank"],
      raw: card
    }
  end

  def normalize_name(nil), do: nil

  def normalize_name(name) when is_binary(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/u, "")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> parsed
      {:error, _} -> nil
    end
  end

  defp to_decimal(nil), do: Decimal.new("0")
  defp to_decimal(%Decimal{} = value), do: value
  defp to_decimal(value) when is_integer(value), do: Decimal.new(value)
  defp to_decimal(value) when is_float(value), do: Decimal.from_float(value)
  defp to_decimal(value) when is_binary(value), do: Decimal.new(value)

  defp primary_face(card) do
    case Map.get(card, "card_faces") do
      [face | _] when is_map(face) -> face
      _ -> %{}
    end
  end

  defp card_name(card, face) do
    case {Map.get(card, "name"), Map.get(face, "name")} do
      {name, face_name} when is_binary(name) and is_binary(face_name) ->
        if String.contains?(name, " // "), do: face_name, else: name

      {nil, face_name} ->
        face_name

      {name, _face_name} ->
        name
    end
  end

  defp card_field(card, face, key, default \\ nil) do
    case Map.get(card, key) do
      nil -> Map.get(face, key, default)
      value -> value
    end
  end
end
