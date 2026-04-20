defmodule TopDeckTutorWeb.DeckLive.Show do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Decks
  alias TopDeckTutorWeb.DeckLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    deck = Decks.get_user_deck_with_entries!(socket.assigns.current_scope.user, id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:deck, deck)
     |> assign(:entries_by_section, Decks.entries_by_section(deck))}
  end

  defp page_title(:show), do: "Show Deck"
  defp page_title(:edit), do: "Edit Deck"
end
