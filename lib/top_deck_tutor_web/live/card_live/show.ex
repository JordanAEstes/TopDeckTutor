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

  def legality_class("legal"), do: "bg-emerald-100 text-emerald-800 border-emerald-200"
  def legality_class("not_legal"), do: "bg-zinc-100 text-zinc-600 border-zinc-200"
  def legality_class("restricted"), do: "bg-amber-100 text-amber-800 border-amber-200"
  def legality_class("banned"), do: "bg-red-100 text-red-800 border-red-200"
  def legality_class(_), do: "bg-zinc-100 text-zinc-600 border-zinc-200"

  def legality_label("not_legal"), do: "Not legal"
  def legality_label(value), do: Phoenix.Naming.humanize(value)
end
