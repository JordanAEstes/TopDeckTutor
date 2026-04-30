defmodule TopDeckTutorWeb.DeckLive.Show do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Decks
  alias TopDeckTutor.Search
  alias TopDeckTutorWeb.DeckLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    deck = Decks.get_user_deck_with_entries!(socket.assigns.current_scope.user, id)
    view_mode = normalize_view_mode(Map.get(params, "view", "details"))
    deck_query = params |> Map.get("q", "") |> String.trim()

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
     |> assign(:view_mode, view_mode)
     |> assign(:preview_card, preview_card)
     |> assign(:search_term, "")
     |> assign(:search_results, [])
     |> assign(:deck_query, deck_query)
     |> assign(:deck_search_error, nil)
     |> assign(:selected_section, "mainboard")
     |> assign(:quantity, 1)
     |> assign_deck_state(deck)}
  end

  @impl true
  def handle_event("search_cards", %{"q" => q}, socket) do
    results =
      case String.trim(q) do
        "" -> []
        term -> Cards.search_cards_by_name(term)
      end

    {:noreply,
     socket
     |> assign(:search_term, q)
     |> assign(:search_results, results)}
  end

  @impl true
  def handle_event("search_deck", %{"search" => %{"q" => q}}, socket) do
    {:noreply, apply_deck_search(socket, String.trim(q))}
  end

  @impl true
  def handle_event("clear_deck_search", _params, socket) do
    {:noreply, clear_deck_search(socket)}
  end

  @impl true
  def handle_event("set_view_mode", %{"mode" => mode}, socket) do
    mode = normalize_view_mode(mode)

    {:noreply,
     push_patch(socket, to: show_path(socket.assigns.deck, mode, socket.assigns.deck_query))}
  end

  @impl true
  def handle_event("preview_card", %{"card_id" => card_id}, socket) do
    card = TopDeckTutor.Cards.get_card!(card_id)
    {:noreply, assign(socket, :preview_card, card)}
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
         |> assign_deck_state(refreshed_deck)
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
         |> assign_deck_state(refreshed_deck)
         |> put_flash(:info, "Card removed from deck")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not remove card")}
    end
  end

  defp page_title(:show), do: "Show Deck"
  defp page_title(:edit), do: "Edit Deck"

  defp show_path(deck, view_mode, deck_query) do
    params =
      []
      |> maybe_put_param(:view, view_mode, "details")
      |> maybe_put_param(:q, deck_query, "")

    ~p"/decks/#{deck}?#{params}"
  end

  defp assign_deck_state(socket, deck) do
    socket
    |> assign(:deck, deck)
    |> assign(:entries_by_section, Decks.entries_by_section(deck))
    |> apply_deck_search(socket.assigns[:deck_query] || "")
  end

  defp apply_deck_search(socket, ""), do: clear_deck_search(socket)

  defp apply_deck_search(socket, query) do
    case Search.parse(query) do
      {:ok, ast} ->
        results = Decks.search_ast_in_deck(socket.assigns.deck, ast)
        result_ids = MapSet.new(results, & &1.card.id)

        visible_entries_by_section =
          socket.assigns.deck
          |> Decks.list_entries()
          |> Enum.filter(&MapSet.member?(result_ids, &1.card.id))
          |> Enum.group_by(& &1.section)

        preview_card =
          visible_entries_by_section
          |> first_entry()
          |> case do
            nil -> nil
            entry -> entry.card
          end

        socket
        |> assign(:deck_query, query)
        |> assign(:deck_search_error, nil)
        |> assign(:visible_entries_by_section, visible_entries_by_section)
        |> assign(:deck_search_match_count, length(results))
        |> assign(:preview_card, preview_card)

      {:error, reason} ->
        socket
        |> assign(:deck_query, query)
        |> assign(:deck_search_error, reason)
        |> assign(:visible_entries_by_section, %{})
        |> assign(:deck_search_match_count, 0)
        |> assign(:preview_card, nil)
    end
  end

  defp clear_deck_search(socket) do
    socket
    |> assign(:deck_query, "")
    |> assign(:deck_search_error, nil)
    |> assign(:visible_entries_by_section, socket.assigns.entries_by_section)
    |> assign(:deck_search_match_count, deck_entry_count(socket.assigns.entries_by_section))
    |> assign(:preview_card, default_preview_card(socket.assigns.deck))
  end

  defp deck_entry_count(entries_by_section) do
    Enum.reduce(entries_by_section, 0, fn {_section, entries}, acc -> acc + length(entries) end)
  end

  defp default_preview_card(deck) do
    deck.deck_entries
    |> List.first()
    |> case do
      nil -> nil
      entry -> entry.card
    end
  end

  defp first_entry(entries_by_section) do
    entries_by_section
    |> Enum.sort_by(fn {section, _entries} -> section end)
    |> Enum.find_value(fn {_section, entries} -> List.first(entries) end)
  end

  defp maybe_put_param(params, _key, value, default) when value in [nil, default], do: params
  defp maybe_put_param(params, key, value, _default), do: Keyword.put(params, key, value)

  defp normalize_view_mode("details"), do: "details"
  defp normalize_view_mode("images"), do: "images"
  defp normalize_view_mode("list"), do: "list"
  defp normalize_view_mode(_), do: "details"
end
