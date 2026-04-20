defmodule TopDeckTutorWeb.DeckLive.Search do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Decks

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Search Deck",
       query: "",
       results: [],
       deck: nil
     )}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    user = socket.assigns.current_scope.user
    deck = Decks.get_user_deck_with_entries!(user, id)

    {:noreply,
     socket
     |> assign(:deck, deck)
     |> assign(:results, Decks.search_cards_in_deck(deck, socket.assigns.query))}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    results = Decks.search_cards_in_deck(socket.assigns.deck, q)

    {:noreply,
     socket
     |> assign(:query, q)
     |> assign(:results, results)}
  end
end
