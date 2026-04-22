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
  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    deck = Decks.get_user_deck_with_entries!(socket.assigns.current_scope.user, id)
    view_mode = normalize_view_mode(Map.get(params, "view", "details"))
    entries_by_section = Decks.entries_by_section(deck)

    preview_card =
      deck.deck_entries
      |> List.first()
      |> case do
        nil -> nil
        entry -> entry.card
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:deck, deck)
     |> assign(:entries_by_section, entries_by_section)
     |> assign(:view_mode, view_mode)
     |> assign(:preview_card, preview_card)
     |> assign(:search_term, "")
     |> assign(:search_results, [])
     |> assign(:selected_section, "mainboard")
     |> assign(:quantity, 1)}
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

  @impl true
  def handle_event("set_view_mode", %{"mode" => mode}, socket) do
    mode = normalize_view_mode(mode)

    {:noreply, push_patch(socket, to: ~p"/decks/#{socket.assigns.deck}?view=#{mode}")}
  end

  @impl true
  def handle_event("preview_card", %{"card_id" => card_id}, socket) do
    card = TopDeckTutor.Cards.get_card!(card_id)
    {:noreply, assign(socket, :preview_card, card)}
  end

  @impl true
  def handle_event("clear_preview_card", _params, socket) do
    {:noreply, socket}
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

  defp normalize_view_mode("details"), do: "details"
  defp normalize_view_mode("images"), do: "images"
  defp normalize_view_mode("list"), do: "list"
  defp normalize_view_mode(_), do: "details"
end
