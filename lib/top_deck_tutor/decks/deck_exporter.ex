defmodule TopDeckTutor.Decks.DeckExporter do
  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.Deck

  def export_text(%Deck{} = deck, opts \\ []) do
    include_set_code? = Keyword.get(opts, :include_set_code, true)
    include_collector_number? = Keyword.get(opts, :include_collector_number, true)

    deck
    |> Decks.list_entries()
    |> Enum.map(&format_entry(&1, include_set_code?, include_collector_number?))
    |> Enum.join("\n")
  end

  defp format_entry(entry, include_set_code?, include_collector_number?) do
    [
      Integer.to_string(entry.quantity),
      entry.card.name,
      set_code(entry.card.set_code, include_set_code?),
      collector_number(entry.card.collector_number, include_collector_number?)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp set_code(_set_code, false), do: nil
  defp set_code(nil, true), do: nil
  defp set_code("", true), do: nil
  defp set_code(set_code, true), do: "(#{String.upcase(set_code)})"

  defp collector_number(_collector_number, false), do: nil
  defp collector_number(nil, true), do: nil
  defp collector_number("", true), do: nil
  defp collector_number(collector_number, true), do: collector_number
end
