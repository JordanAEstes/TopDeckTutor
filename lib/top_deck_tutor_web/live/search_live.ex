defmodule TopDeckTutorWeb.SearchLive do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Cards

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Search",
       query: "",
       results: []
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    query = Map.get(params, "q", "") |> String.trim()

    results =
      case query do
        "" -> []
        q -> Cards.search_cards(q)
      end

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:results, results)}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    {:noreply, push_patch(socket, to: ~p"/search?q=#{q}")}
  end
end
