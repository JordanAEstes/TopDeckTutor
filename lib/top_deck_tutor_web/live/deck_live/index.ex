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

  def format_image("commander"),
    do:
      "https://cards.scryfall.io/art_crop/front/c/0/c0fb91ec-20a8-4c13-9469-18885b1ecca3.jpg?1559591658"

  def format_image("vintage"),
    do:
      "https://cards.scryfall.io/art_crop/front/b/3/b3a69a1c-c80f-4413-a6fd-ae54cabbce28.jpg?1559591595"

  def format_image("legacy"),
    do:
      "https://cards.scryfall.io/art_crop/front/8/d/8d42d7aa-7f53-4cfc-842a-086aab2448d1.jpg?1616400136"

  def format_image("pioneer"),
    do:
      "https://cards.scryfall.io/art_crop/front/b/5/b5e81649-9954-424c-89d1-f87d73b66047.jpg?1595869185"

  def format_image("modern"),
    do:
      "https://cards.scryfall.io/art_crop/front/4/3/435589bb-27c6-4a6d-9d63-394d5092b9d8.jpg?1561978182"

  def format_image("premodern"),
    do:
      "https://cards.scryfall.io/art_crop/front/2/5/255099be-c64e-4f6a-8463-4fc058d6908d.jpg?1559591712"

  def format_image("historic"),
    do:
      "https://cards.scryfall.io/art_crop/front/3/d/3df8c148-e87d-4043-9d8b-ec72bf8b6d5d.jpg?1562345371"

  def format_image("pauper"),
    do:
      "https://cards.scryfall.io/art_crop/front/9/e/9e11bf7c-f439-4529-b29a-d711359807ef.jpg?1559591924"

  def format_image(_),
    do:
      "https://cards.scryfall.io/art_crop/front/6/a/6a0b230b-d391-4998-a3f7-7b158a0ec2cd.jpg?1731652605"
end
