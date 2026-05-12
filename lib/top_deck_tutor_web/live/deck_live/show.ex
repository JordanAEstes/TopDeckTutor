defmodule TopDeckTutorWeb.DeckLive.Show do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.DeckExporter
  alias TopDeckTutor.Decks.DeckImporter
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
    sort_mode = normalize_sort_mode(Map.get(params, "sort"))
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
     |> assign(:sort_mode, sort_mode)
     |> assign(:sort_by_type?, sort_mode == "type")
     |> assign(:preview_card, preview_card)
     |> assign(:search_term, "")
     |> assign(:search_results, [])
     |> assign(:deck_query, deck_query)
     |> assign(:deck_search_error, nil)
     |> assign(:import_modal_open?, false)
     |> assign(:import_errors, [])
     |> assign(:import_form, import_form())
     |> assign(:export_modal_open?, false)
     |> assign(:export_include_set_code?, true)
     |> assign(:export_include_collector_number?, true)
     |> assign(:selected_section, "mainboard")
     |> assign(:quantity, 1)
     |> assign_deck_state(deck)}
  end

  @impl true
  def handle_event("search_cards", %{"value" => q}, socket) do
    results = Cards.search_cards_by_name(q, add_card_search_opts(socket.assigns.deck))

    {:noreply,
     socket
     |> assign(:search_term, q)
     |> assign(:search_results, results)}
  end

  @impl true
  def handle_event("select_card", %{"id" => id}, socket) do
    deck = socket.assigns.deck
    card = Cards.get_card!(id)

    case Decks.add_card(deck, card, %{section: "mainboard", quantity: 1}) do
      {:ok, _entry} ->
        refreshed_deck =
          Decks.get_user_deck_with_entries!(socket.assigns.current_scope.user, deck.id)

        {:noreply,
         socket
         |> assign_deck_state(refreshed_deck)
         |> assign(:search_term, "")
         |> assign(:search_results, [])
         |> put_flash(:info, "#{card.name} added to deck")}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Could not add card: #{inspect(changeset.errors)}")}
    end
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
  def handle_event("open_deck_importer", _params, socket) do
    {:noreply,
     socket
     |> assign(:import_modal_open?, true)
     |> assign(:import_errors, [])
     |> assign(:import_form, import_form())}
  end

  @impl true
  def handle_event("close_deck_importer", _params, socket) do
    {:noreply,
     socket
     |> assign(:import_modal_open?, false)
     |> assign(:import_errors, [])
     |> assign(:import_form, import_form())}
  end

  @impl true
  def handle_event("open_deck_exporter", _params, socket) do
    {:noreply,
     socket
     |> assign(:export_modal_open?, true)
     |> assign(:export_include_set_code?, true)
     |> assign(:export_include_collector_number?, true)
     |> assign_export_state()}
  end

  @impl true
  def handle_event("close_deck_exporter", _params, socket) do
    {:noreply, assign(socket, :export_modal_open?, false)}
  end

  @impl true
  def handle_event("deck_export_copied", _params, socket) do
    {:noreply,
     socket
     |> assign(:export_modal_open?, false)
     |> put_flash(:info, "Decklist copied")}
  end

  @impl true
  def handle_event("update_deck_export_options", %{"export" => export_params}, socket) do
    {:noreply,
     socket
     |> assign(:export_include_set_code?, truthy_param?(export_params["include_set_code"]))
     |> assign(
       :export_include_collector_number?,
       truthy_param?(export_params["include_collector_number"])
     )
     |> assign_export_state()}
  end

  @impl true
  def handle_event("import_decklist", %{"import" => %{"decklist" => decklist}}, socket) do
    deck = socket.assigns.deck

    case DeckImporter.import_text(deck, decklist) do
      {:ok, %{imported_count: imported_count}} ->
        refreshed_deck =
          Decks.get_user_deck_with_entries!(socket.assigns.current_scope.user, deck.id)

        {:noreply,
         socket
         |> assign_deck_state(refreshed_deck)
         |> assign(:import_modal_open?, false)
         |> assign(:import_errors, [])
         |> assign(:import_form, import_form())
         |> put_flash(:info, "Imported #{imported_count} cards")}

      {:error, errors} ->
        {:noreply,
         socket
         |> assign(:import_modal_open?, true)
         |> assign(:import_errors, errors)
         |> assign(:import_form, import_form(decklist))}
    end
  end

  @impl true
  def handle_event("set_view_mode", %{"mode" => mode}, socket) do
    mode = normalize_view_mode(mode)

    {:noreply,
     push_patch(
       socket,
       to:
         show_path(socket.assigns.deck, mode, socket.assigns.deck_query, socket.assigns.sort_mode)
     )}
  end

  @impl true
  def handle_event("toggle_type_sort", _params, socket) do
    sort_mode = if socket.assigns.sort_by_type?, do: nil, else: "type"

    {:noreply,
     push_patch(
       socket,
       to:
         show_path(
           socket.assigns.deck,
           socket.assigns.view_mode,
           socket.assigns.deck_query,
           sort_mode
         )
     )}
  end

  @impl true
  def handle_event("preview_card", %{"card_id" => card_id}, socket) do
    card = TopDeckTutor.Cards.get_card!(card_id)
    {:noreply, assign(socket, :preview_card, card)}
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

  defp add_card_search_opts(%{format: "commander", deck_entries: entries})
       when is_list(entries) do
    entries
    |> Enum.find(&(&1.section == "command"))
    |> case do
      nil -> []
      entry -> [color_identity: entry.card.color_identity || []]
    end
  end

  defp add_card_search_opts(_deck), do: []

  defp show_path(deck, view_mode, deck_query, sort_mode) do
    params =
      []
      |> maybe_put_param(:view, view_mode, "details")
      |> maybe_put_param(:q, deck_query, "")
      |> maybe_put_param(:sort, sort_mode, nil)

    ~p"/decks/#{deck}?#{params}"
  end

  defp assign_deck_state(socket, deck) do
    socket
    |> assign(:deck, deck)
    |> assign(:entries_by_section, Decks.entries_by_section(deck))
    |> assign_export_state()
    |> apply_deck_search(socket.assigns[:deck_query] || "")
  end

  defp assign_export_state(socket) do
    include_set_code? = socket.assigns[:export_include_set_code?] != false
    include_collector_number? = socket.assigns[:export_include_collector_number?] != false

    export_text =
      DeckExporter.export_text(socket.assigns.deck,
        include_set_code: include_set_code?,
        include_collector_number: include_collector_number?
      )

    socket
    |> assign(:export_text, export_text)
    |> assign(:export_form, export_form(include_set_code?, include_collector_number?))
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

  defp import_form(decklist \\ "") do
    to_form(%{"decklist" => decklist}, as: :import)
  end

  defp export_form(include_set_code?, include_collector_number?) do
    to_form(
      %{
        "include_set_code" => include_set_code?,
        "include_collector_number" => include_collector_number?
      },
      as: :export
    )
  end

  defp truthy_param?("true"), do: true
  defp truthy_param?(_), do: false

  defp normalize_view_mode("details"), do: "details"
  defp normalize_view_mode("images"), do: "images"
  defp normalize_view_mode("list"), do: "list"
  defp normalize_view_mode(_), do: "details"

  defp normalize_sort_mode("type"), do: "type"
  defp normalize_sort_mode(_), do: nil

  defp grouped_entries(entries), do: Decks.group_entries_by_type(entries)

  defp type_group_id(section, group), do: "deck-type-group-#{section}-#{group}"

  defp list_view_columns(entries_by_section, sort_by_type?) do
    entries_by_section
    |> Enum.sort_by(fn {section, _entries} -> section end)
    |> Enum.flat_map(fn {section, entries} ->
      section_rows = [
        {:section, section, Enum.reduce(entries, 0, fn entry, acc -> entry.quantity + acc end)}
      ]

      entry_rows =
        if sort_by_type? do
          entries
          |> grouped_entries()
          |> Enum.flat_map(fn {group, group_entries} ->
            [
              {:type_group, section, group, entry_count(group_entries)}
              | Enum.map(group_entries, &{:entry, &1})
            ]
          end)
        else
          Enum.map(entries, &{:entry, &1})
        end

      section_rows ++ entry_rows
    end)
    |> split_list_columns()
  end

  defp split_list_columns(rows) do
    {columns, current_column, _entry_count} =
      Enum.reduce(rows, {[], [], 0}, fn
        {:entry, _entry} = row, {columns, current_column, 50} ->
          {[Enum.reverse(current_column) | columns], [row], 1}

        {:entry, _entry} = row, {columns, current_column, entry_count} ->
          {columns, [row | current_column], entry_count + 1}

        row, {columns, current_column, 50} ->
          {[Enum.reverse(current_column) | columns], [row], 0}

        row, {columns, current_column, entry_count} ->
          {columns, [row | current_column], entry_count}
      end)

    [Enum.reverse(current_column) | columns]
    |> Enum.reject(&(&1 == []))
    |> Enum.reverse()
  end

  defp entry_count(entries),
    do: Enum.reduce(entries, 0, fn entry, acc -> entry.quantity + acc end)

  defp card_count_label(1), do: "1 card"
  defp card_count_label(count), do: "#{count} cards"
end
