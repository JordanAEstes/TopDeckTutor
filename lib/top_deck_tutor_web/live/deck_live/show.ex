defmodule TopDeckTutorWeb.DeckLive.Show do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Decks
  alias TopDeckTutorWeb.DeckLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    deck = Decks.get_user_deck_with_entries!(socket.assigns.current_scope.user, id)

    {:noreply,
     socket
     |> assign(
       page_title: page_title(socket.assigns.live_action),
       deck: deck,
       entries_by_section: Decks.entries_by_section(deck),
       search_term: "",
       search_results: [],
       selected_section: "mainboard",
       quantity: 1
     )}
  end

  @impl true
  def handle_event("search_cards", %{"q" => q}, socket) do
    results =
      case String.trim(q) do
        "" -> []
        term -> Cards.search_cards(term)
      end

    {:noreply,
     socket
     |> assign(:search_term, q)
     |> assign(:search_results, results)}
  end

  def handle_event(
        "add_card",
        %{"card_id" => card_id, "section" => section, "quantity" => quantity},
        socket
      ) do
    deck = socket.assigns.deck
    card = Cards.get_card!(card_id)

    case Decks.add_card(deck, card, %{section: section, quantity: quantity}) do
      {:ok, _entry} ->
        refreshed_deck =
          Decks.get_user_deck_with_entries!(socket.assigns.current_scope.user, deck.id)

        {:noreply,
         socket
         |> assign(:deck, refreshed_deck)
         |> assign(:entries_by_section, Decks.entries_by_section(refreshed_deck))
         |> put_flash(:info, "#{card.name} added to deck")}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Could not add card: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("remove_entry", %{"id" => id}, socket) do
    entry = TopDeckTutor.Decks.get_deck_entry!(socket.assigns.deck, id)

    case TopDeckTutor.Decks.remove_entry(entry) do
      {:ok, _deleted_entry} ->
        refreshed_deck =
          TopDeckTutor.Decks.get_user_deck_with_entries!(
            socket.assigns.current_scope.user,
            socket.assigns.deck.id
          )

        {:noreply,
         socket
         |> assign(:deck, refreshed_deck)
         |> assign(:entries_by_section, TopDeckTutor.Decks.entries_by_section(refreshed_deck))
         |> put_flash(:info, "Card removed from deck")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not remove card")}
    end
  end

  defp page_title(:show), do: "Show Deck"
  defp page_title(:edit), do: "Edit Deck"
end
