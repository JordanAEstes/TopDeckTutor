defmodule TopDeckTutorWeb.DeckLive.Search do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Decks
  alias TopDeckTutor.Search

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Search Deck",
       query: "",
       results: [],
       ast: [],
       parse_error: nil,
       deck: nil
     )}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    user = socket.assigns.current_scope.user
    deck = Decks.get_user_deck_with_entries!(user, id)
    q = params |> Map.get("q", "") |> String.trim()

    {:noreply,
     socket
     |> assign(:deck, deck)
     |> apply_search_query(q)}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    {:noreply, apply_search_query(socket, String.trim(q))}
  end

  defp apply_search_query(socket, ""), do: clear_search(socket)

  defp apply_search_query(socket, q) do
    case Search.parse(q) do
      {:ok, ast} ->
        results = Decks.search_ast_in_deck(socket.assigns.deck, ast)

        socket
        |> assign(:query, q)
        |> assign(:results, results)
        |> assign(:ast, ast)
        |> assign(:parse_error, nil)

      {:error, reason} ->
        socket
        |> assign(:query, q)
        |> assign(:results, [])
        |> assign(:ast, [])
        |> assign(:parse_error, reason)
    end
  end

  defp clear_search(socket) do
    socket
    |> assign(:query, "")
    |> assign(:results, [])
    |> assign(:ast, [])
    |> assign(:parse_error, nil)
  end
end
