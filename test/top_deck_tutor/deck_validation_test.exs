defmodule TopDeckTutor.DeckValidationTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.DeckValidation
  alias TopDeckTutor.Decks.Deck

  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  describe "validate_deck/1" do
    test "validates a persisted deck through its format key" do
      deck = deck_fixture(nil, %{format: "Commander"})

      commander =
        card_fixture(%{
          name: "Alela, Artful Provocateur",
          color_identity: ["W", "U", "B"],
          legalities: %{"commander" => "legal"}
        })

      card =
        card_fixture(%{
          name: "Sol Ring",
          color_identity: [],
          legalities: %{"commander" => "legal"}
        })

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, commander, %{section: "command"})
      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card)

      assert DeckValidation.validate_deck(deck) == :ok
    end

    test "returns a structured error for an unknown format" do
      assert DeckValidation.validate_deck(%Deck{format: "frontier"}) ==
               {:error, ["Unsupported format: frontier"]}
    end

    test "returns legality errors from the selected format" do
      deck = deck_fixture(nil, %{format: "commander"})

      commander =
        card_fixture(%{
          name: "Alela, Artful Provocateur",
          color_identity: ["W", "U", "B"],
          legalities: %{"commander" => "legal"}
        })

      card =
        card_fixture(%{
          name: "Black Lotus",
          color_identity: [],
          legalities: %{"commander" => "banned"}
        })

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, commander, %{section: "command"})
      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card)

      assert DeckValidation.validate_deck(deck) ==
               {:error, ["Black Lotus is not legal in commander"]}
    end

    test "returns copy limit errors from the selected format" do
      deck = deck_fixture(nil, %{format: "commander"})

      commander =
        card_fixture(%{
          name: "Alela, Artful Provocateur",
          color_identity: ["W", "U", "B"],
          legalities: %{"commander" => "legal"}
        })

      card =
        card_fixture(%{
          name: "Sol Ring",
          color_identity: [],
          legalities: %{"commander" => "legal"}
        })

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, commander, %{section: "command"})
      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card, %{quantity: 2})

      assert DeckValidation.validate_deck(deck) ==
               {:error, ["Sol Ring exceeds commander copy limit of 1"]}
    end

    test "returns commander color identity errors from the selected format" do
      deck = deck_fixture(nil, %{format: "commander"})

      commander =
        card_fixture(%{
          name: "Alela, Artful Provocateur",
          color_identity: ["W", "U", "B"],
          legalities: %{"commander" => "legal"}
        })

      card =
        card_fixture(%{
          name: "Lightning Bolt",
          color_identity: ["R"],
          legalities: %{"commander" => "legal"}
        })

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, commander, %{section: "command"})
      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card)

      assert DeckValidation.validate_deck(deck) ==
               {:error, ["Lightning Bolt has color identity outside Alela, Artful Provocateur"]}
    end

    test "returns section errors from the selected format" do
      deck = deck_fixture(nil, %{format: "modern"})
      card = card_fixture(%{name: "Lightning Bolt", legalities: %{"modern" => "legal"}})

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card, %{section: "command"})

      assert DeckValidation.validate_deck(deck) ==
               {:error, ["Lightning Bolt is in command, which is not allowed in modern"]}
    end
  end
end
