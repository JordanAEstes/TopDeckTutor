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
    raw_line = String.trim(line)

    if raw_line == "" do
      {:ok, nil}
    else
      {quantity, name_with_set} = parse_quantity(raw_line)
      {card_name, set_code, collector_number} = parse_printing(name_with_set)
      card_text = error_card_text(card_name, raw_line)

      cond do
        quantity < 1 ->
          {:error, import_error(line_number, card_text, "invalid quantity")}

        String.trim(name_with_set) == "" ->
          {:error, import_error(line_number, card_text, "malformed line")}

        card_name == "" ->
          {:error, import_error(line_number, card_text, "malformed line")}

        true ->
          {:ok,
           %{
             line_number: line_number,
             raw_line: raw_line,
             quantity: quantity,
             card_name: card_name,
             set_code: set_code,
             collector_number: collector_number
           }}
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

  defp parse_printing(name_with_set) do
    case Regex.run(~r/^(.*?)\s+\(([A-Za-z0-9]+)\)(?:\s+(\S+))?$/u, name_with_set) do
      [_, card_name, set_code] ->
        {String.trim(card_name), String.downcase(set_code), nil}

      [_, card_name, set_code, collector_number] ->
        {String.trim(card_name), String.downcase(set_code), collector_number}

      _ ->
        {String.trim(name_with_set), nil, nil}
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
      nil -> {:error, import_error(row, "card not found")}
      %Card{} = card -> {:ok, card}
    end
  end

  defp resolve_card(%{set_code: set_code} = row) do
    normalized_name = normalize_name(row.card_name)

    card =
      Card
      |> where([c], c.normalized_name == ^normalized_name and c.set_code == ^set_code)
      |> maybe_filter_collector_number(row.collector_number)
      |> Repo.all()
      |> preferred_set_printing()

    cond do
      card ->
        {:ok, card}

      card_name_exists?(normalized_name) ->
        {:error, import_error(row, "no printing found for set #{String.upcase(set_code)}")}

      true ->
        {:error, import_error(row, "card not found")}
    end
  end

  defp import_error(
         %{line_number: line_number, card_name: card_name, raw_line: raw_line},
         message
       ) do
    import_error(line_number, error_card_text(card_name, raw_line), message)
  end

  defp import_error(line_number, card_text, message) do
    %{line_number: line_number, card_text: card_text, message: message}
  end

  defp error_card_text(card_name, raw_line) do
    card_name
    |> String.trim()
    |> case do
      "" -> raw_line
      card_name -> card_name
    end
  end

  defp maybe_filter_collector_number(query, nil), do: query

  defp maybe_filter_collector_number(query, collector_number) do
    where(query, [c], c.collector_number == ^collector_number)
  end

  defp preferred_set_printing([]), do: nil

  defp preferred_set_printing(cards) do
    Enum.min_by(cards, &collector_number_sort_key/1)
  end

  defp collector_number_sort_key(%Card{collector_number: collector_number, id: id}) do
    {collector_number_number(collector_number), collector_number_suffix(collector_number),
     collector_number || "", id}
  end

  defp collector_number_number(nil), do: 1_000_000_000

  defp collector_number_number(collector_number) do
    case Regex.run(~r/^\d+/, collector_number) do
      [number] -> String.to_integer(number)
      nil -> 1_000_000_000
    end
  end

  defp collector_number_suffix(nil), do: ""

  defp collector_number_suffix(collector_number) do
    case Regex.run(~r/^\d+(.*)$/, collector_number) do
      [_, suffix] -> suffix
      nil -> collector_number
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
