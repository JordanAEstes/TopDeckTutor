defmodule TopDeckTutor.DeckValidationTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.DeckValidation
  alias TopDeckTutor.Decks.Deck
  alias TopDeckTutor.Decks.ValidationResult

  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  describe "validate_deck/1" do
    test "returns a structured valid result for a persisted deck through its format key" do
      deck = deck_fixture(nil, %{format: "modern"})

      card = card_fixture(%{name: "Lightning Bolt", legalities: %{"modern" => "legal"}})

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card)

      assert %ValidationResult{valid?: true, errors: [], warnings: []} =
               DeckValidation.validate_deck(deck)
    end

    test "returns a structured error for an unknown format" do
      assert %ValidationResult{
               valid?: false,
               errors: [
                 %{code: :unsupported_format, message: "Unsupported format: frontier"}
               ],
               warnings: []
             } = DeckValidation.validate_deck(%Deck{format: "frontier"})
    end

    test "returns legality errors from the selected format" do
      deck = deck_fixture(nil, %{format: "modern"})

      card =
        card_fixture(%{
          name: "Black Lotus",
          color_identity: [],
          legalities: %{"modern" => "banned"}
        })

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card)

      assert %ValidationResult{
               valid?: false,
               errors: [
                 %{code: :illegal_card, message: "Black Lotus is not legal in modern"}
               ]
             } = DeckValidation.validate_deck(deck)
    end

    test "returns copy limit errors from the selected format" do
      deck = deck_fixture(nil, %{format: "modern"})

      card =
        card_fixture(%{
          name: "Sol Ring",
          color_identity: [],
          legalities: %{"modern" => "legal"}
        })

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card, %{quantity: 5})

      assert %ValidationResult{
               valid?: false,
               errors: [
                 %{code: :too_many_copies, message: "Sol Ring exceeds modern copy limit of 4"}
               ]
             } = DeckValidation.validate_deck(deck)
    end

    test "returns deck-size errors from commander rules" do
      deck = deck_fixture(nil, %{format: "commander"})

      commander =
        card_fixture(%{
          name: "Alela, Artful Provocateur",
          color_identity: ["W", "U", "B"],
          legalities: %{"commander" => "legal"}
        })

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, commander, %{section: "command"})

      assert %ValidationResult{
               valid?: false,
               errors: [
                 %{code: :deck_size, message: "Commander decks must contain exactly 100 cards"}
               ]
             } = DeckValidation.validate_deck(deck)
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

      assert %ValidationResult{
               valid?: false,
               errors: [
                 %{
                   code: :format_rule,
                   message: "Lightning Bolt has color identity outside Alela, Artful Provocateur"
                 },
                 %{code: :deck_size, message: "Commander decks must contain exactly 100 cards"}
               ]
             } = DeckValidation.validate_deck(deck)
    end

    test "returns section errors from the selected format" do
      deck = deck_fixture(nil, %{format: "modern"})
      card = card_fixture(%{name: "Lightning Bolt", legalities: %{"modern" => "legal"}})

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card, %{section: "command"})

      assert %ValidationResult{
               valid?: false,
               errors: [
                 %{
                   code: :invalid_section,
                   message: "Lightning Bolt is in command, which is not allowed in modern"
                 }
               ]
             } = DeckValidation.validate_deck(deck)
    end

    test "is exposed through the decks context" do
      deck = deck_fixture(nil, %{format: "modern"})
      card = card_fixture(%{name: "Lightning Bolt", legalities: %{"modern" => "legal"}})

      assert {:ok, _entry} = TopDeckTutor.Decks.add_card(deck, card)

      assert %ValidationResult{valid?: true} = TopDeckTutor.Decks.validate_deck(deck)
    end
  end
end
