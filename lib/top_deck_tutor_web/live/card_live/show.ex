defmodule TopDeckTutorWeb.CardLive.Show do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Cards

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Card")}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    card = Cards.get_card!(id)

    {:noreply,
     socket
     |> assign(:card, card)
     |> assign(:page_title, card.name)}
  end

  def legality_rows(legalities) when is_map(legalities) do
    legalities
    |> Enum.sort_by(fn {format, _} -> format end)
  end

  def finish_text(card) do
    cond do
      card.foil && card.nonfoil -> "Nonfoil/Foil"
      card.foil -> "Foil"
      card.nonfoil -> "Nonfoil"
      true -> "Unknown"
    end
  end

  def background_image_uri(card) do
    card.image_uris["art_crop"] || card.image_uris["large"] || card.image_uris["normal"]
  end

  def card_frame_style(card) do
    case card_frame_tint(card) do
      nil ->
        nil

      tint ->
        IO.inspect(tint)

        [
          "background-color: color-mix(in srgb, #{tint} 15%, var(--surface) 85%)",
          "border-color: color-mix(in srgb, #{tint} 28%, var(--border) 72%)"
        ]
        |> Enum.join("; ")
    end
  end

  def legality_class("legal"), do: "bg-emerald-100 text-emerald-800 border-emerald-200"
  def legality_class("not_legal"), do: "bg-zinc-100 text-zinc-600 border-zinc-200"
  def legality_class("restricted"), do: "bg-amber-100 text-amber-800 border-amber-200"
  def legality_class("banned"), do: "bg-red-100 text-red-800 border-red-200"
  def legality_class(_), do: "bg-zinc-100 text-zinc-600 border-zinc-200"

  def legality_label("not_legal"), do: "Not legal"
  def legality_label(value), do: Phoenix.Naming.humanize(value)

  defp card_frame_tint(card) do
    case card.colors || [] do
      [color] -> mana_var(color)
      colors when is_list(colors) and length(colors) > 1 -> "var(--brand)"
      _ -> nil
    end
  end

  defp mana_var("W"), do: "var(--mana-white)"
  defp mana_var("U"), do: "var(--mana-blue)"
  defp mana_var("B"), do: "var(--mana-black)"
  defp mana_var("R"), do: "var(--mana-red)"
  defp mana_var("G"), do: "var(--mana-green)"
  defp mana_var(_), do: nil
end
