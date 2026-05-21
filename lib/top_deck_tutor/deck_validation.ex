defmodule TopDeckTutor.DeckValidation do
  @moduledoc """
  Validates decks against rules resolved from the persisted `decks.format` key.
  """

  alias Ecto.Association.NotLoaded
  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.{Deck, DeckEntry}
  alias TopDeckTutor.Decks.ValidationResult
  alias TopDeckTutor.Formats

  def validate_deck(%Deck{} = deck) do
    format_key = Formats.normalize_key(deck.format)

    case Formats.get(format_key) do
      nil ->
        invalid_result([error(:unsupported_format, "Unsupported format: #{deck.format}")])

      format ->
        loaded_entries = entries(deck)
        deck = %{deck | deck_entries: loaded_entries}

        errors =
          loaded_entries
          |> Enum.flat_map(&entry_errors(&1, format, format_key))
          |> format_result(format.validate_deck(deck))

        result(errors)
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
      [
        error(
          :invalid_section,
          "#{card.name} is in #{entry.section}, which is not allowed in #{format_key}",
          card_id: card.id,
          section: entry.section
        )
        | errors
      ]
    end
  end

  defp maybe_add_legality_error(errors, card, format, format_key) do
    if format.legal_card?(card, format_key) do
      errors
    else
      [
        error(:illegal_card, "#{card.name} is not legal in #{format_key}", card_id: card.id)
        | errors
      ]
    end
  end

  defp maybe_add_copy_limit_error(errors, entry, card, format, format_key) do
    case format.max_copies(card, format_key) do
      :unlimited ->
        errors

      max_copies when entry.quantity <= max_copies ->
        errors

      max_copies ->
        [
          error(
            :too_many_copies,
            "#{card.name} exceeds #{format_key} copy limit of #{max_copies}",
            card_id: card.id
          )
          | errors
        ]
    end
  end

  defp format_result(errors, :ok), do: errors

  defp format_result(errors, {:error, format_errors}) do
    errors ++ Enum.map(format_errors, &normalize_format_error/1)
  end

  defp normalize_format_error(%{code: _code, message: _message} = error), do: error
  defp normalize_format_error(message) when is_binary(message), do: error(:format_rule, message)

  defp result([]), do: %ValidationResult{valid?: true, errors: [], warnings: []}
  defp result(errors), do: invalid_result(errors)

  defp invalid_result(errors), do: %ValidationResult{valid?: false, errors: errors, warnings: []}

  defp error(code, message, attrs \\ []) do
    attrs
    |> Map.new()
    |> Map.merge(%{code: code, message: message})
  end
end
