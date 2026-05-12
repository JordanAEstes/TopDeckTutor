defmodule TopDeckTutorWeb.DeckLive.FormComponent do
  use TopDeckTutorWeb, :live_component

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Decks

  @format_options [
    "duel",
    "brawl",
    "penny",
    "predh",
    "future",
    "legacy",
    "modern",
    "pauper",
    "alchemy",
    "pioneer",
    "vintage",
    "historic",
    "standard",
    "timeless",
    "commander",
    "gladiator",
    "oldschool",
    "premodern",
    "oathbreaker",
    "standardbrawl",
    "paupercommander"
  ]

  @impl true
  def update(%{deck: deck} = assigns, socket) do
    changeset = Decks.change_deck(deck)
    selected_commander = selected_commander(deck)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:format_options, format_options(@format_options))
     |> assign(:selected_format, deck.format)
     |> assign(:commander_search_term, commander_search_term(selected_commander))
     |> assign(:commander_search_results, [])
     |> assign(:selected_commander, selected_commander)}
  end

  @impl true
  def handle_event("validate", %{"deck" => deck_params}, socket) do
    changeset =
      socket.assigns.deck
      |> Decks.change_deck(deck_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:selected_format, Map.get(deck_params, "format"))}
  end

  @impl true
  def handle_event("search_commander", %{"value" => term}, socket) do
    results = Cards.search_legendary_creatures_by_name(term)

    {:noreply,
     socket
     |> assign(:commander_search_term, term)
     |> assign(:commander_search_results, results)}
  end

  @impl true
  def handle_event("select_commander", %{"id" => id}, socket) do
    commander = Cards.get_card!(id)

    {:noreply,
     socket
     |> assign(:selected_commander, commander)
     |> assign(:commander_search_term, commander.name)
     |> assign(:commander_search_results, [])}
  end

  @impl true
  def handle_event("save", %{"deck" => deck_params}, socket) do
    save_deck(socket, socket.assigns.action, deck_params)
  end

  defp save_deck(socket, :edit, deck_params) do
    case Decks.update_deck(socket.assigns.deck, deck_params) do
      {:ok, deck} ->
        maybe_set_commander(deck, deck_params, socket.assigns.selected_commander)
        notify_parent({:saved, deck})

        {:noreply,
         socket
         |> put_flash(:info, "Deck updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_deck(socket, :new, deck_params) do
    case Decks.create_deck(socket.assigns.current_scope.user, deck_params) do
      {:ok, deck} ->
        maybe_set_commander(deck, deck_params, socket.assigns.selected_commander)
        notify_parent({:saved, deck})

        {:noreply,
         socket
         |> put_flash(:info, "Deck created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp format_options(formats),
    do: Enum.map(formats, fn format -> {String.capitalize(format), format} end)

  defp maybe_set_commander(deck, %{"format" => "commander"}, %Cards.Card{} = commander) do
    Decks.set_commander(deck, commander)
  end

  defp maybe_set_commander(_deck, _deck_params, _commander), do: nil

  defp selected_commander(%{id: nil}), do: nil

  defp selected_commander(deck) do
    deck
    |> Decks.list_entries()
    |> Enum.find(&(&1.section == "command"))
    |> case do
      nil -> nil
      entry -> entry.card
    end
  end

  defp commander_search_term(nil), do: ""
  defp commander_search_term(commander), do: commander.name
end
