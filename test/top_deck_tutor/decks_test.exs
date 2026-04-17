defmodule TopDeckTutor.DecksTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.{Deck, DeckEntry}

  import TopDeckTutor.AccountsFixtures
  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  describe "list_decks_for_user/1" do
    test "returns only decks owned by the given user" do
      user = user_fixture()
      other_user = user_fixture()

      owned_deck = deck_fixture(user)
      _other_deck = deck_fixture(other_user)

      results = Decks.list_decks_for_user(user)

      assert Enum.map(results, & &1.id) == [owned_deck.id]
    end
  end

  describe "get_user_deck!/2" do
    test "returns the deck when it belongs to the user" do
      user = user_fixture()
      deck = deck_fixture(user)
      deck_id = deck.id

      assert %Deck{id: ^deck_id} = Decks.get_user_deck!(user, deck.id)
    end

    test "raises when the deck belongs to another user" do
      user = user_fixture()
      other_user = user_fixture()
      deck = deck_fixture(other_user)

      assert_raise Ecto.NoResultsError, fn ->
        Decks.get_user_deck!(user, deck.id)
      end
    end
  end

  describe "get_user_deck_with_entries!/2" do
    test "preloads entries and cards" do
      user = user_fixture()
      deck = deck_fixture(user)
      card = card_fixture(%{name: "Brushland", normalized_name: "brushland"})

      assert {:ok, _entry} = Decks.add_card(deck, card)

      loaded = Decks.get_user_deck_with_entries!(user, deck.id)

      assert [%DeckEntry{} = entry] = loaded.deck_entries
      assert entry.card.id == card.id
    end
  end

  describe "create_deck/2" do
    test "creates a deck for the user" do
      user = user_fixture()

      assert {:ok, %Deck{} = deck} =
               Decks.create_deck(user, %{
                 name: "Esper Control",
                 format: "pioneer",
                 visibility: "private"
               })

      assert deck.user_id == user.id
      assert deck.name == "Esper Control"
    end
  end

  describe "update_deck/2" do
    test "updates the deck" do
      deck = deck_fixture()

      assert {:ok, updated} =
               Decks.update_deck(deck, %{
                 name: "Updated Deck",
                 visibility: "public"
               })

      assert updated.name == "Updated Deck"
      assert updated.visibility == "public"
    end
  end

  describe "delete_deck/1" do
    test "deletes the deck" do
      user = user_fixture()
      deck = deck_fixture(user)

      assert {:ok, %Deck{}} = Decks.delete_deck(deck)

      assert_raise Ecto.NoResultsError, fn ->
        Decks.get_user_deck!(user, deck.id)
      end
    end
  end

  describe "add_card/3" do
    test "creates a new entry when the card is not already in the section" do
      deck = deck_fixture()
      card = card_fixture()

      assert {:ok, %DeckEntry{} = entry} = Decks.add_card(deck, card)

      assert entry.deck_id == deck.id
      assert entry.card_id == card.id
      assert entry.quantity == 1
      assert entry.section == "mainboard"
    end

    test "increments quantity when the same card already exists in the same section" do
      deck = deck_fixture()
      card = card_fixture()

      assert {:ok, %DeckEntry{} = entry1} = Decks.add_card(deck, card, %{quantity: 2})
      assert {:ok, %DeckEntry{} = entry2} = Decks.add_card(deck, card, %{quantity: 3})

      assert entry1.id == entry2.id
      assert entry2.quantity == 5
    end

    test "creates a separate entry when the same card is added to a different section" do
      deck = deck_fixture()
      card = card_fixture()

      assert {:ok, %DeckEntry{} = mainboard} =
               Decks.add_card(deck, card, %{section: "mainboard", quantity: 1})

      assert {:ok, %DeckEntry{} = maybeboard} =
               Decks.add_card(deck, card, %{section: "maybeboard", quantity: 1})

      assert mainboard.id != maybeboard.id
      assert mainboard.section == "mainboard"
      assert maybeboard.section == "maybeboard"
    end
  end

  describe "list_entries/1" do
    test "returns entries for the deck with cards preloaded" do
      deck = deck_fixture()
      card = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})

      assert {:ok, _entry} = Decks.add_card(deck, card)

      assert [%DeckEntry{} = entry] = Decks.list_entries(deck)
      assert entry.card.id == card.id
    end
  end

  describe "update_entry/2" do
    test "updates a deck entry" do
      deck = deck_fixture()
      card = card_fixture()
      {:ok, entry} = Decks.add_card(deck, card)

      assert {:ok, updated} =
               Decks.update_entry(entry, %{quantity: 4, section: "sideboard"})

      assert updated.quantity == 4
      assert updated.section == "sideboard"
    end
  end

  describe "remove_entry/1" do
    test "deletes the entry" do
      deck = deck_fixture()
      card = card_fixture()
      {:ok, entry} = Decks.add_card(deck, card)

      assert {:ok, %DeckEntry{}} = Decks.remove_entry(entry)
      assert_raise Ecto.NoResultsError, fn -> Decks.get_entry!(entry.id) end
    end
  end

  describe "cards_query/1" do
    test "returns only cards in the given deck" do
      deck = deck_fixture()
      other_deck = deck_fixture()
      card_in_deck = card_fixture(%{name: "Island", normalized_name: "island"})
      card_not_in_deck = card_fixture(%{name: "Mountain", normalized_name: "mountain"})

      {:ok, _} = Decks.add_card(deck, card_in_deck)
      {:ok, _} = Decks.add_card(other_deck, card_not_in_deck)

      results = deck |> Decks.cards_query() |> TopDeckTutor.Repo.all()

      assert Enum.map(results, & &1.id) == [card_in_deck.id]
    end
  end

  describe "entries_by_section/1" do
    test "groups entries by section" do
      deck = deck_fixture()
      card1 = card_fixture(%{name: "Plains", normalized_name: "plains"})

      card2 =
        card_fixture(%{name: "Swords to Plowshares", normalized_name: "swords to plowshares"})

      {:ok, _} = Decks.add_card(deck, card1, %{section: "mainboard"})
      {:ok, _} = Decks.add_card(deck, card2, %{section: "sideboard"})

      grouped = Decks.entries_by_section(deck)

      assert Map.has_key?(grouped, "mainboard")
      assert Map.has_key?(grouped, "sideboard")
      assert length(grouped["mainboard"]) == 1
      assert length(grouped["sideboard"]) == 1
    end
  end
end
