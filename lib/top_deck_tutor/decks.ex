defmodule TopDeckTutor.Decks do
  import Ecto.Query, warn: false

  alias TopDeckTutor.Repo
  alias TopDeckTutor.Accounts.User
  alias TopDeckTutor.Cards.Card
  alias TopDeckTutor.Decks.{Deck, DeckEntry}

  def list_decks_for_user(%User{id: user_id}) do
    Deck
    |> where([d], d.user_id == ^user_id)
    |> order_by([d], asc: d.inserted_at)
    |> Repo.all()
  end

  def get_user_deck!(%User{id: user_id}, deck_id) do
    Deck
    |> where([d], d.id == ^deck_id and d.user_id == ^user_id)
    |> Repo.one!()
  end

  def get_user_deck_with_entries!(%User{} = user, deck_id) do
    user
    |> get_user_deck!(deck_id)
    |> Repo.preload(deck_entries: [:card])
  end

  def create_deck(%User{id: user_id}, attrs) do
    %Deck{}
    |> Deck.changeset(Map.put(attrs, :user_id, user_id))
    |> Repo.insert()
  end

  def update_deck(%Deck{} = deck, attrs) do
    deck
    |> Deck.changeset(attrs)
    |> Repo.update()
  end

  def delete_deck(%Deck{} = deck) do
    Repo.delete(deck)
  end

  def change_deck(%Deck{} = deck, attrs \\ %{}) do
    Deck.changeset(deck, attrs)
  end

  def list_entries(%Deck{id: deck_id}) do
    DeckEntry
    |> where([de], de.deck_id == ^deck_id)
    |> preload(:card)
    |> order_by([de], asc: de.section, asc: de.inserted_at)
    |> Repo.all()
  end

  def get_entry!(id), do: Repo.get!(DeckEntry, id)

  def add_card(%Deck{id: deck_id}, %Card{id: card_id}, attrs \\ %{}) do
    section = Map.get(attrs, "section") || Map.get(attrs, :section) || "mainboard"

    quantity =
      attrs
      |> Map.get("quantity", Map.get(attrs, :quantity, 1))
      |> normalize_quantity()

    case Repo.get_by(DeckEntry, deck_id: deck_id, card_id: card_id, section: section) do
      nil ->
        %DeckEntry{}
        |> DeckEntry.changeset(%{
          deck_id: deck_id,
          card_id: card_id,
          section: section,
          quantity: quantity
        })
        |> Repo.insert()

      %DeckEntry{} = entry ->
        update_entry(entry, %{quantity: entry.quantity + quantity})
    end
  end

  def update_entry(%DeckEntry{} = entry, attrs) do
    entry
    |> DeckEntry.changeset(attrs)
    |> Repo.update()
  end

  def remove_entry(%DeckEntry{} = entry) do
    Repo.delete(entry)
  end

  def cards_query(%Deck{id: deck_id}) do
    from c in Card,
      join: de in DeckEntry,
      on: de.card_id == c.id,
      where: de.deck_id == ^deck_id,
      select: c
  end

  def entries_by_section(%Deck{} = deck) do
    deck
    |> list_entries()
    |> Enum.group_by(& &1.section)
  end

  defp normalize_quantity(quantity) when is_integer(quantity), do: quantity
  defp normalize_quantity(quantity) when is_binary(quantity), do: String.to_integer(quantity)
  defp normalize_quantity(_), do: 1
end
