defmodule TopDeckTutor.Decks.DeckImporter do
  import Ecto.Query, warn: false

  alias TopDeckTutor.Cards.Card
  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.Deck
  alias TopDeckTutor.Repo

  def parse_text(raw_text) when is_binary(raw_text) do
    {rows, errors} =
      raw_text
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.reduce({[], []}, fn {line, line_number}, {rows, errors} ->
        case parse_line(line, line_number) do
          {:ok, nil} -> {rows, errors}
          {:ok, row} -> {[row | rows], errors}
          {:error, error} -> {rows, [error | errors]}
        end
      end)

    case Enum.reverse(errors) do
      [] -> {:ok, Enum.reverse(rows)}
      errors -> {:error, errors}
    end
  end

  def import_text(%Deck{} = deck, raw_text, opts \\ []) when is_binary(raw_text) do
    section = Keyword.get(opts, :section, "mainboard")

    with {:ok, rows} <- parse_text(raw_text),
         {:ok, resolved_rows} <- resolve_rows(rows) do
      persist_rows(deck, resolved_rows, section)
    end
  end

  defp parse_line(line, line_number) do
    line = String.trim(line)

    if line == "" do
      {:ok, nil}
    else
      {quantity, name_with_set} = parse_quantity(line)

      cond do
        quantity < 1 ->
          {:error, %{line_number: line_number, message: "invalid quantity"}}

        String.trim(name_with_set) == "" ->
          {:error, %{line_number: line_number, message: "malformed line"}}

        true ->
          {card_name, set_code} = parse_set_code(name_with_set)

          if card_name == "" do
            {:error, %{line_number: line_number, message: "malformed line"}}
          else
            {:ok,
             %{
               line_number: line_number,
               quantity: quantity,
               card_name: card_name,
               set_code: set_code
             }}
          end
      end
    end
  end

  defp parse_quantity(line) do
    case Regex.run(~r/^(\d+)(?:\s+(.+))?$/u, line) do
      [_, quantity] -> {String.to_integer(quantity), ""}
      [_, quantity, rest] -> {String.to_integer(quantity), String.trim(rest)}
      _ -> {1, line}
    end
  end

  defp parse_set_code(name_with_set) do
    case Regex.run(~r/^(.*?)\s+\(([A-Za-z0-9]+)\)$/u, name_with_set) do
      [_, card_name, set_code] -> {String.trim(card_name), String.downcase(set_code)}
      _ -> {String.trim(name_with_set), nil}
    end
  end

  defp resolve_rows(rows) do
    {resolved_rows, errors} =
      Enum.reduce(rows, {[], []}, fn row, {resolved_rows, errors} ->
        case resolve_card(row) do
          {:ok, card} -> {[Map.put(row, :card, card) | resolved_rows], errors}
          {:error, error} -> {resolved_rows, [error | errors]}
        end
      end)

    case Enum.reverse(errors) do
      [] -> {:ok, Enum.reverse(resolved_rows)}
      errors -> {:error, errors}
    end
  end

  defp resolve_card(%{set_code: nil} = row) do
    case preferred_printing(row.card_name) do
      nil -> {:error, %{line_number: row.line_number, message: "card not found"}}
      %Card{} = card -> {:ok, card}
    end
  end

  defp resolve_card(%{set_code: set_code} = row) do
    normalized_name = normalize_name(row.card_name)

    card =
      Card
      |> where([c], c.normalized_name == ^normalized_name and c.set_code == ^set_code)
      |> order_by([c], asc: c.id)
      |> limit(1)
      |> Repo.one()

    cond do
      card ->
        {:ok, card}

      card_name_exists?(normalized_name) ->
        {:error,
         %{
           line_number: row.line_number,
           message: "no printing found for set #{String.upcase(set_code)}"
         }}

      true ->
        {:error, %{line_number: row.line_number, message: "card not found"}}
    end
  end

  defp preferred_printing(card_name) do
    normalized_name = normalize_name(card_name)

    Card
    |> where([c], c.normalized_name == ^normalized_name)
    |> order_by([c],
      desc: fragment("? = ANY(?)", "paper", c.games),
      asc: c.digital,
      desc_nulls_last: c.released_at,
      asc: c.id
    )
    |> limit(1)
    |> Repo.one()
  end

  defp card_name_exists?(normalized_name) do
    Card
    |> where([c], c.normalized_name == ^normalized_name)
    |> Repo.exists?()
  end

  defp persist_rows(deck, rows, section) do
    Repo.transaction(fn ->
      Enum.reduce(rows, 0, fn row, imported_count ->
        case Decks.add_card(deck, row.card, %{section: section, quantity: row.quantity}) do
          {:ok, _entry} -> imported_count + row.quantity
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end)
    |> case do
      {:ok, imported_count} -> {:ok, %{imported_count: imported_count}}
      {:error, changeset} -> {:error, [%{line_number: nil, message: inspect(changeset.errors)}]}
    end
  end

  defp normalize_name(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/u, "")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end
end
