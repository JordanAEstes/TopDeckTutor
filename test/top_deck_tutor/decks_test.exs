defmodule TopDeckTutor.DecksTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.{Deck, DeckEntry}

  import TopDeckTutor.AccountsFixtures
  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  @colors ["W", "U", "B", "R", "G"]

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

  describe "search_query_in_deck/2" do
    test "supports quoted name filters within a deck" do
      deck = deck_fixture()
      other_deck = deck_fixture()

      matching =
        card_fixture(%{
          name: "Sol Ring",
          normalized_name: "sol ring",
          oracle_text: "Add two colorless mana."
        })

      _other_name_match =
        card_fixture(%{
          name: "Sol Talisman",
          normalized_name: "sol talisman",
          oracle_text: "Suspend 3."
        })

      other_deck_card =
        card_fixture(%{
          name: "Sol Ring",
          normalized_name: "sol ring",
          oracle_text: "Reprint in another deck."
        })

      {:ok, _} = Decks.add_card(deck, matching)
      {:ok, _} = Decks.add_card(other_deck, other_deck_card)

      assert {:ok, results} = Decks.search_query_in_deck(deck, ~s(name:"Sol Ring"))
      assert Enum.map(results, & &1.card.id) == [matching.id]
    end

    test "supports quoted text filters within a deck" do
      deck = deck_fixture()

      matching =
        card_fixture(%{
          name: "Divination",
          normalized_name: "divination",
          oracle_text: "Draw a card, then draw a card."
        })

      _other =
        card_fixture(%{
          name: "Shock",
          normalized_name: "shock",
          oracle_text: "Deal 2 damage to any target."
        })

      {:ok, _} = Decks.add_card(deck, matching)

      assert {:ok, results} = Decks.search_query_in_deck(deck, ~s(text:"draw a card"))
      assert Enum.map(results, & &1.card.id) == [matching.id]
    end

    test "supports negated type filters within a deck" do
      deck = deck_fixture()

      excluded =
        card_fixture(%{
          name: "Llanowar Elves",
          normalized_name: "llanowar elves",
          type_line: "Creature — Elf Druid"
        })

      included =
        card_fixture(%{
          name: "Wrath of God",
          normalized_name: "wrath of god",
          type_line: "Sorcery"
        })

      {:ok, _} = Decks.add_card(deck, excluded)
      {:ok, _} = Decks.add_card(deck, included)

      assert {:ok, results} = Decks.search_query_in_deck(deck, "-type:creature")
      assert Enum.map(results, & &1.card.id) == [included.id]
    end

    test "supports negated text filters within a deck" do
      deck = deck_fixture()

      excluded =
        card_fixture(%{
          name: "Counterspell",
          normalized_name: "counterspell",
          oracle_text: "Counter target spell."
        })

      included =
        card_fixture(%{
          name: "Divination",
          normalized_name: "divination",
          oracle_text: "Draw two cards."
        })

      {:ok, _} = Decks.add_card(deck, excluded)
      {:ok, _} = Decks.add_card(deck, included)

      assert {:ok, results} = Decks.search_query_in_deck(deck, "-text:counter")
      assert Enum.map(results, & &1.card.id) == [included.id]
    end

    test "supports negated name filters within a deck" do
      deck = deck_fixture()

      excluded =
        card_fixture(%{
          name: "Ajani, Mentor of Heroes",
          normalized_name: "ajani mentor of heroes"
        })

      included =
        card_fixture(%{
          name: "Elspeth, Sun's Champion",
          normalized_name: "elspeth suns champion"
        })

      {:ok, _} = Decks.add_card(deck, excluded)
      {:ok, _} = Decks.add_card(deck, included)

      assert {:ok, results} = Decks.search_query_in_deck(deck, "-name:ajani")
      assert Enum.map(results, & &1.card.id) == [included.id]
    end

    test "supports every non-empty color identity combination within a deck" do
      deck = deck_fixture()
      other_deck = deck_fixture()

      cards_by_colors =
        for colors <- color_combinations(@colors), into: %{} do
          name = "Deck CI #{Enum.join(colors)}"

          card =
            card_fixture(%{
              name: name,
              normalized_name: String.downcase(name),
              color_identity: colors
            })

          {:ok, _} = Decks.add_card(deck, card)

          other_deck_card =
            card_fixture(%{
              name: "#{name} Other",
              normalized_name: String.downcase("#{name} Other"),
              color_identity: colors
            })

          {:ok, _} = Decks.add_card(other_deck, other_deck_card)

          {colors, card}
        end

      for colors <- color_combinations(@colors) do
        token = colors |> Enum.join() |> String.downcase()

        expected_ids =
          cards_by_colors
          |> expected_color_identity_matches(colors)
          |> Enum.map(& &1.id)
          |> Enum.sort()

        assert {:ok, results} = Decks.search_query_in_deck(deck, "ci:#{token}")
        assert Enum.map(results, & &1.card.id) |> Enum.sort() == expected_ids
      end
    end

    test "supports rarity and set filters within a deck" do
      deck = deck_fixture()
      other_deck = deck_fixture()

      rare_match =
        card_fixture(%{
          name: "Deck Rare Match",
          normalized_name: "deck rare match",
          rarity: "rare",
          set_code: "m19"
        })

      mythic_match =
        card_fixture(%{
          name: "Deck Mythic Match",
          normalized_name: "deck mythic match",
          rarity: "mythic",
          set_code: "mh3"
        })

      other_deck_match =
        card_fixture(%{
          name: "Other Deck Rare",
          normalized_name: "other deck rare",
          rarity: "rare",
          set_code: "m19"
        })

      {:ok, _} = Decks.add_card(deck, rare_match)
      {:ok, _} = Decks.add_card(deck, mythic_match)
      {:ok, _} = Decks.add_card(other_deck, other_deck_match)

      assert {:ok, rare_results} = Decks.search_query_in_deck(deck, "rarity:rare")
      assert Enum.map(rare_results, & &1.card.id) == [rare_match.id]

      assert {:ok, mythic_results} = Decks.search_query_in_deck(deck, "rarity:mythic")
      assert Enum.map(mythic_results, & &1.card.id) == [mythic_match.id]

      assert {:ok, m19_results} = Decks.search_query_in_deck(deck, "set:m19")
      assert Enum.map(m19_results, & &1.card.id) == [rare_match.id]

      assert {:ok, mh3_results} = Decks.search_query_in_deck(deck, "set:mh3")
      assert Enum.map(mh3_results, & &1.card.id) == [mythic_match.id]
    end

    test "supports legality filters within a deck" do
      deck = deck_fixture()
      other_deck = deck_fixture()

      commander_match =
        card_fixture(%{
          name: "Deck Commander Legal",
          normalized_name: "deck commander legal",
          legalities: %{"commander" => "legal"}
        })

      modern_match =
        card_fixture(%{
          name: "Deck Modern Legal",
          normalized_name: "deck modern legal",
          legalities: %{"modern" => "legal"}
        })

      legacy_banned_match =
        card_fixture(%{
          name: "Deck Legacy Banned",
          normalized_name: "deck legacy banned",
          legalities: %{"legacy" => "banned"}
        })

      vintage_restricted_match =
        card_fixture(%{
          name: "Deck Vintage Restricted",
          normalized_name: "deck vintage restricted",
          legalities: %{"vintage" => "restricted"}
        })

      other_deck_card =
        card_fixture(%{
          name: "Other Deck Commander Legal",
          normalized_name: "other deck commander legal",
          legalities: %{"commander" => "legal"}
        })

      {:ok, _} = Decks.add_card(deck, commander_match)
      {:ok, _} = Decks.add_card(deck, modern_match)
      {:ok, _} = Decks.add_card(deck, legacy_banned_match)
      {:ok, _} = Decks.add_card(deck, vintage_restricted_match)
      {:ok, _} = Decks.add_card(other_deck, other_deck_card)

      assert {:ok, commander_results} = Decks.search_query_in_deck(deck, "legal:commander")
      assert Enum.map(commander_results, & &1.card.id) == [commander_match.id]

      assert {:ok, modern_results} = Decks.search_query_in_deck(deck, "legal:modern")
      assert Enum.map(modern_results, & &1.card.id) == [modern_match.id]

      assert {:ok, banned_results} = Decks.search_query_in_deck(deck, "banned:legacy")
      assert Enum.map(banned_results, & &1.card.id) == [legacy_banned_match.id]

      assert {:ok, restricted_results} = Decks.search_query_in_deck(deck, "restricted:vintage")
      assert Enum.map(restricted_results, & &1.card.id) == [vintage_restricted_match.id]
    end

    test "supports color filters within a deck and keeps color distinct from color identity" do
      deck = deck_fixture()
      other_deck = deck_fixture()

      color_match =
        card_fixture(%{
          name: "Deck Color Match",
          normalized_name: "deck color match",
          colors: ["W", "U"],
          color_identity: ["W", "U"]
        })

      white_match =
        card_fixture(%{
          name: "Deck White Match",
          normalized_name: "deck white match",
          colors: ["W"],
          color_identity: ["W"]
        })

      colorless_match =
        card_fixture(%{
          name: "Deck Colorless Match",
          normalized_name: "deck colorless match",
          colors: [],
          color_identity: []
        })

      color_identity_only =
        card_fixture(%{
          name: "Deck Identity Only",
          normalized_name: "deck identity only",
          colors: [],
          color_identity: ["G"]
        })

      other_deck_card =
        card_fixture(%{
          name: "Other Deck White Match",
          normalized_name: "other deck white match",
          colors: ["W"],
          color_identity: ["W"]
        })

      {:ok, _} = Decks.add_card(deck, color_match)
      {:ok, _} = Decks.add_card(deck, white_match)
      {:ok, _} = Decks.add_card(deck, colorless_match)
      {:ok, _} = Decks.add_card(deck, color_identity_only)
      {:ok, _} = Decks.add_card(other_deck, other_deck_card)

      assert {:ok, white_results} = Decks.search_query_in_deck(deck, "color:w")

      assert Enum.map(white_results, & &1.card.id) |> Enum.sort() ==
               Enum.sort([color_match.id, white_match.id])

      assert {:ok, azorius_results} = Decks.search_query_in_deck(deck, "color:wu")
      assert Enum.map(azorius_results, & &1.card.id) == [color_match.id]

      assert {:ok, colorless_results} = Decks.search_query_in_deck(deck, "color:c")

      assert Enum.map(colorless_results, & &1.card.id) |> Enum.sort() ==
               Enum.sort([colorless_match.id, color_identity_only.id])

      assert {:ok, ci_results} = Decks.search_query_in_deck(deck, "ci:g")
      assert Enum.map(ci_results, & &1.card.id) == [color_identity_only.id]
    end
  end

  defp color_combinations(colors) do
    1..length(colors)
    |> Enum.flat_map(&combinations(colors, &1))
  end

  defp combinations(_colors, 0), do: [[]]
  defp combinations([], _count), do: []

  defp combinations([head | tail], count) do
    with_head = Enum.map(combinations(tail, count - 1), &[head | &1])
    without_head = combinations(tail, count)
    with_head ++ without_head
  end

  defp expected_color_identity_matches(cards_by_colors, required_colors) do
    required_set = MapSet.new(required_colors)

    cards_by_colors
    |> Enum.filter(fn {colors, _card} ->
      MapSet.subset?(required_set, MapSet.new(colors))
    end)
    |> Enum.map(fn {_colors, card} -> card end)
  end
end
