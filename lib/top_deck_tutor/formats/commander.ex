defmodule TopDeckTutor.Formats.Commander do
  @behaviour TopDeckTutor.Formats.Format

  alias Ecto.Association.NotLoaded

  @impl true
  def key, do: "commander"

  @impl true
  def display_name, do: "Commander"

  @impl true
  def validate_deck(%{deck_entries: %NotLoaded{}}), do: :ok

  def validate_deck(%{deck_entries: entries}) when is_list(entries) do
    case commander_entry(entries) do
      nil ->
        {:error, ["Commander decks must include a commander"]}

      commander_entry ->
        errors = color_identity_errors(entries, commander_entry.card)

        if errors == [], do: :ok, else: {:error, errors}
    end
  end

  def validate_deck(_deck), do: :ok

  @impl true
  def legal_card?(card, format_key), do: Map.get(card.legalities || %{}, format_key) == "legal"

  @impl true
  def max_copies(card, _format_key) do
    if basic_land?(card), do: :unlimited, else: 1
  end

  @impl true
  def allowed_sections, do: ["mainboard", "sideboard", "maybeboard", "command"]

  defp basic_land?(card), do: String.contains?(card.type_line || "", "Basic Land")

  defp commander_entry(entries), do: Enum.find(entries, &(&1.section == "command"))

  defp color_identity_errors(entries, commander) do
    Enum.flat_map(entries, fn entry ->
      if color_identity_subset?(entry.card.color_identity || [], commander.color_identity || []) do
        []
      else
        ["#{entry.card.name} has color identity outside #{commander.name}"]
      end
    end)
  end

  defp color_identity_subset?(card_identity, commander_identity) do
    Enum.all?(card_identity, &(&1 in commander_identity))
  end
end
