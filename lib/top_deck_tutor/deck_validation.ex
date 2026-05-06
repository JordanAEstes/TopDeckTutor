defmodule TopDeckTutor.DeckValidation do
  @moduledoc """
  Validates decks against rules resolved from the persisted `decks.format` key.
  """

  alias Ecto.Association.NotLoaded
  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.{Deck, DeckEntry}
  alias TopDeckTutor.Formats

  def validate_deck(%Deck{} = deck) do
    format_key = Formats.normalize_key(deck.format)

    case Formats.get(format_key) do
      nil ->
        {:error, ["Unsupported format: #{deck.format}"]}

      format ->
        loaded_entries = entries(deck)
        deck = %{deck | deck_entries: loaded_entries}

        errors =
          loaded_entries
          |> Enum.flat_map(&entry_errors(&1, format, format_key))
          |> format_result(format.validate_deck(deck))

        if errors == [], do: :ok, else: {:error, errors}
    end
  end

  defp entries(%Deck{deck_entries: entries}) when is_list(entries), do: entries

  defp entries(%Deck{id: nil}), do: []

  defp entries(%Deck{deck_entries: %NotLoaded{}} = deck), do: Decks.list_entries(deck)

  defp entry_errors(%DeckEntry{} = entry, format, format_key) do
    card = entry.card

    []
    |> maybe_add_section_error(entry, card, format, format_key)
    |> maybe_add_legality_error(card, format, format_key)
    |> maybe_add_copy_limit_error(entry, card, format, format_key)
    |> Enum.reverse()
  end

  defp maybe_add_section_error(errors, entry, card, format, format_key) do
    if entry.section in format.allowed_sections() do
      errors
    else
      ["#{card.name} is in #{entry.section}, which is not allowed in #{format_key}" | errors]
    end
  end

  defp maybe_add_legality_error(errors, card, format, format_key) do
    if format.legal_card?(card, format_key) do
      errors
    else
      ["#{card.name} is not legal in #{format_key}" | errors]
    end
  end

  defp maybe_add_copy_limit_error(errors, entry, card, format, format_key) do
    case format.max_copies(card, format_key) do
      :unlimited ->
        errors

      max_copies when entry.quantity <= max_copies ->
        errors

      max_copies ->
        ["#{card.name} exceeds #{format_key} copy limit of #{max_copies}" | errors]
    end
  end

  defp format_result(errors, :ok), do: errors
  defp format_result(errors, {:error, format_errors}), do: errors ++ format_errors
end
