defmodule TopDeckTutorWeb.DeckLive.Index do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.Deck
  alias TopDeckTutorWeb.DeckLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "My Decks")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_user = socket.assigns.current_scope.user

    {:noreply,
     socket
     |> assign(:decks, Decks.list_decks_for_user(current_user))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    deck = Decks.get_user_deck!(socket.assigns.current_scope.user, id)

    socket
    |> assign(:page_title, "Edit Deck")
    |> assign(:deck, deck)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Deck")
    |> assign(:deck, %Deck{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Decks")
    |> assign(:deck, nil)
  end

  @impl true
  def handle_info({FormComponent, {:saved, _deck}}, socket) do
    {:noreply,
     assign(socket, :decks, Decks.list_decks_for_user(socket.assigns.current_scope.user))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    deck = Decks.get_user_deck!(socket.assigns.current_scope.user, id)
    {:ok, _} = Decks.delete_deck(deck)

    {:noreply,
     assign(socket, :decks, Decks.list_decks_for_user(socket.assigns.current_scope.user))}
  end
end
