defmodule TopDeckTutor.Formats.Modern do
  @behaviour TopDeckTutor.Formats.Format

  @impl true
  def key, do: "modern"

  @impl true
  def display_name, do: "Modern"

  @impl true
  def validate_deck(_deck), do: :ok

  @impl true
  def legal_card?(card, format_key), do: Map.get(card.legalities || %{}, format_key) == "legal"

  @impl true
  def max_copies(card, _format_key) do
    if basic_land?(card), do: :unlimited, else: 4
  end

  @impl true
  def allowed_sections, do: ["mainboard", "sideboard", "maybeboard"]

  defp basic_land?(card), do: String.contains?(card.type_line || "", "Basic Land")
end
