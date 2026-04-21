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
  def handle_params(%{"id" => id}, _url, socket) do
    user = socket.assigns.current_scope.user
    deck = Decks.get_user_deck_with_entries!(user, id)

    {:noreply, assign(socket, :deck, deck)}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    q = String.trim(q)

    case q do
      "" ->
        {:noreply,
         socket
         |> assign(:query, "")
         |> assign(:results, [])
         |> assign(:ast, [])
         |> assign(:parse_error, nil)}

      _ ->
        case Search.parse(q) do
          {:ok, ast} ->
            results = Decks.search_ast_in_deck(socket.assigns.deck, ast)

            {:noreply,
             socket
             |> assign(:query, q)
             |> assign(:results, results)
             |> assign(:ast, ast)
             |> assign(:parse_error, nil)}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:query, q)
             |> assign(:results, [])
             |> assign(:ast, [])
             |> assign(:parse_error, reason)}
        end
    end
  end
end
