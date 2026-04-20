defmodule TopDeckTutorWeb.DeckLive.FormComponent do
  use TopDeckTutorWeb, :live_component

  alias TopDeckTutor.Decks

  @impl true
  def update(%{deck: deck} = assigns, socket) do
    changeset = Decks.change_deck(deck)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"deck" => deck_params}, socket) do
    changeset =
      socket.assigns.deck
      |> Decks.change_deck(deck_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"deck" => deck_params}, socket) do
    save_deck(socket, socket.assigns.action, deck_params)
  end

  defp save_deck(socket, :edit, deck_params) do
    case Decks.update_deck(socket.assigns.deck, deck_params) do
      {:ok, deck} ->
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
end
