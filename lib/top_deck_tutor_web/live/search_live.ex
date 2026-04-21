defmodule TopDeckTutorWeb.SearchLive do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Search

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Search",
       query: "",
       results: [],
       ast: [],
       parse_error: nil
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    query =
      params
      |> Map.get("q", "")
      |> String.trim()

    case query do
      "" ->
        {:noreply,
         socket
         |> assign(:query, "")
         |> assign(:results, [])
         |> assign(:ast, [])
         |> assign(:parse_error, nil)}

      _ ->
        case Search.parse(query) do
          {:ok, ast} ->
            results = Cards.search_ast(ast)

            {:noreply,
             socket
             |> assign(:query, query)
             |> assign(:results, results)
             |> assign(:ast, ast)
             |> assign(:parse_error, nil)}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:query, query)
             |> assign(:results, [])
             |> assign(:ast, [])
             |> assign(:parse_error, reason)}
        end
    end
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    {:noreply, push_patch(socket, to: ~p"/search?q=#{q}")}
  end
end
