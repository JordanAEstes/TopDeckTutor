defmodule TopDeckTutor.CardsTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Cards.Card

  import TopDeckTutor.CardsFixtures

  describe "get_card!/1" do
    test "returns the card by id" do
      card = card_fixture()
      card_id = card.id

      assert %Card{id: ^card_id} = Cards.get_card!(card.id)
    end
  end

  describe "get_card_by_oracle_id/1" do
    test "returns the card by oracle_id" do
      card = card_fixture()
      card_id = card.id

      assert %Card{id: ^card_id} = Cards.get_card_by_oracle_id(card.oracle_id)
    end
  end

  describe "get_card_by_name/1" do
    test "matches by normalized name" do
      card =
        card_fixture(%{name: "Atraxa, Grand Unifier", normalized_name: "atraxa grand unifier"})

      card_id = card.id

      assert %Card{id: ^card_id} = Cards.get_card_by_name("Atraxa, Grand Unifier")
      assert %Card{id: ^card_id} = Cards.get_card_by_name("atraxa grand unifier")
    end
  end

  describe "search_cards/1" do
    test "searches by name" do
      matching = card_fixture(%{name: "Brushland", normalized_name: "brushland"})
      _other = card_fixture(%{name: "Island", normalized_name: "island"})

      results = Cards.search_cards("Brush")

      assert Enum.any?(results, &(&1.id == matching.id))
    end

    test "searches by type line" do
      matching =
        card_fixture(%{
          name: "Llanowar Elves",
          normalized_name: "llanowar elves",
          type_line: "Creature — Elf Druid"
        })

      _other =
        card_fixture(%{
          name: "Wrath of God",
          normalized_name: "wrath of god",
          type_line: "Sorcery"
        })

      results = Cards.search_cards("Creature")

      assert Enum.any?(results, &(&1.id == matching.id))
    end

    test "searches by oracle text" do
      matching =
        card_fixture(%{
          name: "Divination",
          normalized_name: "divination",
          oracle_text: "Draw two cards."
        })

      _other =
        card_fixture(%{
          name: "Shock",
          normalized_name: "shock",
          oracle_text: "Shock deals 2 damage to any target."
        })

      results = Cards.search_cards("Draw two")

      assert Enum.any?(results, &(&1.id == matching.id))
    end

    test "search_query/1 supports name and text filters" do
      matching =
        card_fixture(%{
          name: "Divination",
          normalized_name: "divination",
          oracle_text: "Draw two cards."
        })

      _other =
        card_fixture(%{
          name: "Shock",
          normalized_name: "shock",
          oracle_text: "Shock deals 2 damage to any target."
        })

      assert {:ok, results} = Cards.search_query(~s(name:divination text:"Draw two"))
      assert Enum.any?(results, &(&1.id == matching.id))
    end

    test "search_query/1 supports quoted name filters" do
      matching =
        card_fixture(%{
          name: "Sol Ring",
          normalized_name: "sol ring",
          oracle_text: "Add two colorless mana."
        })

      _other =
        card_fixture(%{
          name: "Sol Talisman",
          normalized_name: "sol talisman",
          oracle_text: "Suspend 3."
        })

      assert {:ok, results} = Cards.search_query(~s(name:"Sol Ring"))
      assert Enum.map(results, & &1.id) == [matching.id]
    end

    test "search_query/1 supports quoted text filters" do
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

      assert {:ok, results} = Cards.search_query(~s(text:"draw a card"))
      assert Enum.map(results, & &1.id) == [matching.id]
    end

    test "search_query/1 supports negated type filters" do
      _excluded =
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

      assert {:ok, results} = Cards.search_query("-type:creature")
      assert Enum.map(results, & &1.id) == [included.id]
    end

    test "search_query/1 supports negated text filters" do
      _excluded =
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

      assert {:ok, results} = Cards.search_query("-text:counter")
      assert Enum.map(results, & &1.id) == [included.id]
    end

    test "search_query/1 supports negated name filters" do
      _excluded =
        card_fixture(%{
          name: "Ajani, Mentor of Heroes",
          normalized_name: "ajani mentor of heroes"
        })

      included =
        card_fixture(%{
          name: "Elspeth, Sun's Champion",
          normalized_name: "elspeth suns champion"
        })

      assert {:ok, results} = Cards.search_query("-name:ajani")
      assert Enum.map(results, & &1.id) == [included.id]
    end
  end

  describe "create_card/1" do
    test "creates a card with valid data" do
      attrs = %{
        id: Ecto.UUID.generate(),
        oracle_id: Ecto.UUID.generate(),
        name: "Sol Ring",
        normalized_name: "sol ring",
        mana_value: Decimal.new("1")
      }

      assert {:ok, %Card{} = card} = Cards.create_card(attrs)
      assert card.name == "Sol Ring"
      assert card.normalized_name == "sol ring"
    end

    test "returns an error changeset with invalid data" do
      assert {:error, changeset} = Cards.create_card(%{})
      refute changeset.valid?
    end
  end

  describe "update_card/2" do
    test "updates a card" do
      card = card_fixture()

      assert {:ok, updated} =
               Cards.update_card(card, %{
                 name: "Updated Name",
                 normalized_name: "updated name"
               })

      assert updated.name == "Updated Name"
      assert updated.normalized_name == "updated name"
    end
  end

  describe "delete_card/1" do
    test "deletes the card" do
      card = card_fixture()

      assert {:ok, %Card{}} = Cards.delete_card(card)
      assert_raise Ecto.NoResultsError, fn -> Cards.get_card!(card.id) end
    end
  end

  describe "upsert_card/1" do
    test "inserts a new card when it does not exist" do
      attrs = %{
        id: Ecto.UUID.generate(),
        oracle_id: Ecto.UUID.generate(),
        name: "Arcane Signet",
        normalized_name: "arcane signet",
        mana_value: Decimal.new("2")
      }

      assert {:ok, card} = Cards.upsert_card(attrs)
      assert card.name == "Arcane Signet"
    end

    test "updates an existing card when the id already exists" do
      card =
        card_fixture(%{
          name: "Arcane Signet",
          normalized_name: "arcane signet"
        })

      assert {:ok, updated} =
               Cards.upsert_card(%{
                 id: card.id,
                 oracle_id: card.oracle_id,
                 name: "Arcane Signet Reprint",
                 normalized_name: "arcane signet reprint",
                 mana_value: Decimal.new("2")
               })

      assert updated.id == card.id
      assert updated.name == "Arcane Signet Reprint"
    end
  end
end
