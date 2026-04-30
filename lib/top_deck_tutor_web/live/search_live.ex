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
       parse_error: nil,
       view_mode: "details",
       preview_card: nil,
       page: 1,
       page_size: 60,
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

    page =
      params
      |> Map.get("page", "1")
      |> normalize_page()

    case query do
      "" ->
        {:noreply,
         socket
         |> assign(:view_mode, view_mode)
         |> assign(:query, "")
         |> assign(:page, 1)
         |> assign(:results, [])
         |> assign(:ast, [])
         |> assign(:parse_error, nil)
         |> assign(:preview_card, nil)
         |> assign(:total_count, 0)
         |> assign(:total_pages, 1)}

      _ ->
        case Search.parse(query) do
          {:ok, ast} ->
            page_data =
              Cards.search_ast_page(ast, page: page, page_size: socket.assigns.page_size)

            {:noreply,
             socket
             |> assign(:view_mode, view_mode)
             |> assign(:query, query)
             |> assign(:page, page_data.page)
             |> assign(:results, page_data.results)
             |> assign(:ast, ast)
             |> assign(:parse_error, nil)
             |> assign(:preview_card, List.first(page_data.results))
             |> assign(:total_count, page_data.total_count)
             |> assign(:total_pages, page_data.total_pages)}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:view_mode, view_mode)
             |> assign(:query, query)
             |> assign(:page, 1)
             |> assign(:results, [])
             |> assign(:ast, [])
             |> assign(:parse_error, reason)
             |> assign(:preview_card, nil)
             |> assign(:total_count, 0)
             |> assign(:total_pages, 1)}
        end
    end
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    {:noreply, push_patch(socket, to: search_path(String.trim(q), socket.assigns.view_mode, 1))}
  end

  @impl true
  def handle_event("set_view_mode", %{"mode" => mode}, socket) do
    {:noreply,
     push_patch(socket,
       to: search_path(socket.assigns.query, normalize_view_mode(mode), socket.assigns.page)
     )}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    {:noreply,
     push_patch(socket,
       to: search_path(socket.assigns.query, socket.assigns.view_mode, normalize_page(page))
     )}
  end

  @impl true
  def handle_event("preview_card", %{"card_id" => card_id}, socket) do
    {:noreply, assign(socket, :preview_card, Cards.get_card!(card_id))}
  end

  defp search_path(query, view_mode, page) do
    params =
      []
      |> maybe_put_param(:q, query, "")
      |> maybe_put_param(:view, view_mode, "details")
      |> maybe_put_param(:page, page, 1)

    ~p"/search?#{params}"
  end

  defp maybe_put_param(params, _key, value, default) when value in [nil, default], do: params
  defp maybe_put_param(params, key, value, _default), do: Keyword.put(params, key, value)

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
end
