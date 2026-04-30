defmodule TopDeckTutorWeb.SearchAdvancedLive do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Decks
  alias TopDeckTutor.Search.AdvancedForm

  @card_types ~w(creature land instant sorcery artifact enchantment planeswalker battle)
  @colors ~w(W U B R G C)
  @rarities ~w(common uncommon rare mythic)
  @legality_statuses ~w(legal banned restricted)
  @legality_formats ~w(standard pioneer modern legacy vintage commander brawl pauper historic timeless)
  @keywords ~w(flying trample haste vigilance deathtouch lifelink ward menace reach flash)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Advanced Search",
       results: [],
       search_started?: false,
       form: to_form(AdvancedForm.changeset(%AdvancedForm{}, %{}), as: :advanced_search),
       decks: []
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    decks = user_decks(socket.assigns.current_scope)
    result = AdvancedForm.build(params, socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:decks, decks)
     |> assign(:form, to_form(result.changeset, as: :advanced_search))
     |> assign(:search_started?, search_started?(params))
     |> assign(:results, search_results(result, socket.assigns.current_scope, params))}
  end

  @impl true
  def handle_event("validate", %{"advanced_search" => params}, socket) do
    result = AdvancedForm.build(params, socket.assigns.current_scope)

    {:noreply, assign(socket, :form, to_form(result.changeset, as: :advanced_search))}
  end

  @impl true
  def handle_event("search", %{"advanced_search" => params}, socket) do
    {:noreply, push_navigate(socket, to: main_search_path(params, socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/search/advanced")}
  end

  def card_type_options, do: Enum.map(@card_types, &{Phoenix.Naming.humanize(&1), &1})
  def rarity_options, do: Enum.map(@rarities, &{Phoenix.Naming.humanize(&1), &1})

  def legality_status_options,
    do: Enum.map(@legality_statuses, &{Phoenix.Naming.humanize(&1), &1})

  def legality_format_options, do: Enum.map(@legality_formats, &{Phoenix.Naming.humanize(&1), &1})
  def keyword_options, do: Enum.map(@keywords, &{Phoenix.Naming.humanize(&1), &1})
  def color_options, do: @colors

  def selected?(values, value) when is_list(values), do: value in values
  def selected?(_, _), do: false

  defp user_decks(%{user: user}) when not is_nil(user), do: Decks.list_decks_for_user(user)
  defp user_decks(_), do: []

  defp search_started?(params) do
    Enum.any?(params, fn
      {"scope", _} -> false
      {"deck_ids", _} -> false
      {_key, value} when is_binary(value) -> String.trim(value) != ""
      {_key, value} when is_list(value) -> Enum.any?(value, &(&1 != ""))
      _ -> false
    end)
  end

  defp search_results(%{changeset: %{valid?: false}}, _current_scope, _params), do: []
  defp search_results(_result, _current_scope, params) when map_size(params) == 0, do: []

  defp search_results(%{ast: []}, _current_scope, _params), do: []

  defp search_results(result, current_scope, _params) do
    result.ast
    |> Cards.search_ast_page(scope: query_scope(result.scope, current_scope), page_size: 60)
    |> Map.fetch!(:results)
  end

  defp query_scope(:catalog, _current_scope), do: :catalog
  defp query_scope({:decks, []}, _current_scope), do: {:decks, []}

  defp query_scope({:decks, deck_ids}, %{user: user}) when not is_nil(user) do
    {:decks, {user, deck_ids}}
  end

  defp query_scope(_scope, _current_scope), do: :catalog

  defp main_search_path(params, current_scope) do
    result = AdvancedForm.build(params, current_scope)
    query = AdvancedForm.to_query(result.ast)

    query_params =
      []
      |> maybe_put_param(:q, query)
      |> maybe_put_scope_params(result.scope)

    ~p"/search?#{query_params}"
  end

  defp maybe_put_param(params, _key, value) when value in [nil, ""], do: params
  defp maybe_put_param(params, key, value), do: Keyword.put(params, key, value)

  defp maybe_put_scope_params(params, :catalog), do: params

  defp maybe_put_scope_params(params, {:decks, []}),
    do: Keyword.put(params, :scope, "selected_decks")

  defp maybe_put_scope_params(params, {:decks, deck_ids}) do
    params
    |> Keyword.put(:scope, "selected_decks")
    |> Keyword.put(:deck_ids, Enum.map(deck_ids, &Integer.to_string/1))
  end
end
