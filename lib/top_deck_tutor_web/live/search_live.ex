defmodule TopDeckTutorWeb.SearchLive do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Search.AdvancedForm
  alias TopDeckTutor.Search

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Search",
       query: "",
       results: [],
       ast: [],
       parse_error: nil,
       game_filter: "all",
       view_mode: "details",
       preview_card: nil,
       page: 1,
       page_size: 60,
       search_scope: :catalog,
       total_count: 0,
       total_pages: 1
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    query =
      params
      |> Map.get("q", "")
      |> String.trim()

    view_mode =
      params
      |> Map.get("view", "details")
      |> normalize_view_mode()

    game_filter =
      params
      |> Map.get("game", "all")
      |> normalize_game_filter()

    page =
      params
      |> Map.get("page", "1")
      |> normalize_page()

    search_scope = normalized_scope(params, socket.assigns.current_scope)

    case query do
      "" ->
        {:noreply,
         socket
         |> assign(:game_filter, game_filter)
         |> assign(:view_mode, view_mode)
         |> assign(:query, "")
         |> assign(:page, 1)
         |> assign(:results, [])
         |> assign(:ast, [])
         |> assign(:parse_error, nil)
         |> assign(:preview_card, nil)
         |> assign(:search_scope, search_scope)
         |> assign(:total_count, 0)
         |> assign(:total_pages, 1)}

      _ ->
        case Search.parse(query) do
          {:ok, ast} ->
            full_ast = maybe_append_game_filter(ast, game_filter)

            page_data =
              Cards.search_ast_page(
                full_ast,
                page: page,
                page_size: socket.assigns.page_size,
                scope: query_scope(search_scope, socket.assigns.current_scope)
              )

            {:noreply,
             socket
             |> assign(:game_filter, game_filter)
             |> assign(:view_mode, view_mode)
             |> assign(:query, query)
             |> assign(:page, page_data.page)
             |> assign(:results, page_data.results)
             |> assign(:ast, full_ast)
             |> assign(:parse_error, nil)
             |> assign(:preview_card, List.first(page_data.results))
             |> assign(:search_scope, search_scope)
             |> assign(:total_count, page_data.total_count)
             |> assign(:total_pages, page_data.total_pages)}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:game_filter, game_filter)
             |> assign(:view_mode, view_mode)
             |> assign(:query, query)
             |> assign(:page, 1)
             |> assign(:results, [])
             |> assign(:ast, [])
             |> assign(:parse_error, reason)
             |> assign(:preview_card, nil)
             |> assign(:search_scope, search_scope)
             |> assign(:total_count, 0)
             |> assign(:total_pages, 1)}
        end
    end
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    {:noreply,
     push_patch(
       socket,
       to:
         search_path(
           String.trim(q),
           socket.assigns.view_mode,
           socket.assigns.game_filter,
           1,
           socket.assigns.search_scope
         )
     )}
  end

  @impl true
  def handle_event("set_view_mode", %{"mode" => mode}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         search_path(
           socket.assigns.query,
           normalize_view_mode(mode),
           socket.assigns.game_filter,
           socket.assigns.page,
           socket.assigns.search_scope
         )
     )}
  end

  @impl true
  def handle_event("set_game_filter", %{"game" => game}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         search_path(
           socket.assigns.query,
           socket.assigns.view_mode,
           normalize_game_filter(game),
           1,
           socket.assigns.search_scope
         )
     )}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         search_path(
           socket.assigns.query,
           socket.assigns.view_mode,
           socket.assigns.game_filter,
           normalize_page(page),
           socket.assigns.search_scope
         )
     )}
  end

  @impl true
  def handle_event("preview_card", %{"card_id" => card_id}, socket) do
    {:noreply, assign(socket, :preview_card, Cards.get_card!(card_id))}
  end

  defp search_path(query, view_mode, game_filter, page, search_scope) do
    params =
      []
      |> maybe_put_param(:q, query, "")
      |> maybe_put_param(:view, view_mode, "details")
      |> maybe_put_param(:game, game_filter, "all")
      |> maybe_put_param(:page, page, 1)
      |> maybe_put_scope_params(search_scope)

    ~p"/search?#{params}"
  end

  defp maybe_put_param(params, _key, value, default) when value in [nil, default], do: params
  defp maybe_put_param(params, key, value, _default), do: Keyword.put(params, key, value)

  defp maybe_put_scope_params(params, :catalog), do: params

  defp maybe_put_scope_params(params, {:decks, []}),
    do: Keyword.put(params, :scope, "selected_decks")

  defp maybe_put_scope_params(params, {:decks, deck_ids}) do
    params
    |> Keyword.put(:scope, "selected_decks")
    |> Keyword.put(:deck_ids, Enum.map(deck_ids, &Integer.to_string/1))
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, ""} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(_), do: 1

  defp normalize_view_mode("details"), do: "details"
  defp normalize_view_mode("images"), do: "images"
  defp normalize_view_mode("list"), do: "list"
  defp normalize_view_mode(_), do: "details"

  defp normalize_game_filter("all"), do: "all"
  defp normalize_game_filter("paper"), do: "paper"
  defp normalize_game_filter("arena"), do: "arena"
  defp normalize_game_filter(_), do: "all"

  defp maybe_append_game_filter(ast, "all"), do: ast
  defp maybe_append_game_filter(ast, game_filter), do: ast ++ [{:game, game_filter}]

  defp normalized_scope(params, current_scope) do
    params
    |> Map.take(["scope", "deck_ids"])
    |> AdvancedForm.build(current_scope)
    |> Map.fetch!(:scope)
  end

  defp query_scope(:catalog, _current_scope), do: :catalog
  defp query_scope({:decks, []}, _current_scope), do: {:decks, []}

  defp query_scope({:decks, deck_ids}, %{user: user}) when not is_nil(user) do
    {:decks, {user, deck_ids}}
  end

  defp query_scope(_search_scope, _current_scope), do: :catalog
end
