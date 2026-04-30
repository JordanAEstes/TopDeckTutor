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
    %Deck{user_id: user_id}
    |> Deck.changeset(attrs)
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

  def get_deck_entry!(%Deck{id: deck_id}, entry_id) do
    DeckEntry
    |> where([de], de.id == ^entry_id and de.deck_id == ^deck_id)
    |> Repo.one!()
  end

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

  def search_cards_in_deck(%Deck{id: deck_id}, term) when is_binary(term) do
    trimmed = String.trim(term)

    base_query =
      from c in Card,
        join: de in DeckEntry,
        on: de.card_id == c.id,
        where: de.deck_id == ^deck_id,
        select: %{card: c, quantity: de.quantity, section: de.section}

    case trimmed do
      "" ->
        base_query
        |> order_by([c, de], asc: de.section, asc: c.name)
        |> Repo.all()

      _ ->
        pattern = "%#{trimmed}%"

        base_query
        |> where(
          [c, de],
          ilike(c.name, ^pattern) or
            ilike(c.type_line, ^pattern) or
            ilike(c.oracle_text, ^pattern)
        )
        |> order_by([c, de], asc: de.section, asc: c.name)
        |> Repo.all()
    end
  end

  def deck_search_scope(%Deck{id: deck_id}) do
    from c in Card,
      join: de in DeckEntry,
      on: de.card_id == c.id,
      where: de.deck_id == ^deck_id,
      order_by: [asc: de.section, asc: c.name],
      select: %{card: c, quantity: de.quantity, section: de.section}
  end

  def selected_decks_search_scope(%User{id: user_id}, deck_ids) when is_list(deck_ids) do
    from c in Card,
      join: de in DeckEntry,
      on: de.card_id == c.id,
      join: d in Deck,
      on: d.id == de.deck_id,
      where: d.user_id == ^user_id and de.deck_id in ^deck_ids,
      distinct: c.normalized_name,
      order_by: [asc: c.name]
  end

  def search_ast_in_deck(%Deck{} = deck, ast) when is_list(ast) do
    ast
    |> TopDeckTutor.Search.Compiler.compile(deck_search_scope(deck))
    |> Repo.all()
  end

  def search_ast_in_decks(%User{} = user, deck_ids, ast)
      when is_list(deck_ids) and is_list(ast) do
    ast
    |> TopDeckTutor.Search.Compiler.compile(selected_decks_search_scope(user, deck_ids))
    |> Repo.all()
  end

  def search_query_in_deck(%Deck{} = deck, query_string) when is_binary(query_string) do
    with {:ok, ast} <- TopDeckTutor.Search.parse(query_string) do
      {:ok, search_ast_in_deck(deck, ast)}
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
