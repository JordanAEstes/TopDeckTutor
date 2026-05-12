defmodule TopDeckTutor.Formats.CommanderTest do
  use ExUnit.Case, async: true

  alias TopDeckTutor.Cards.Card
  alias TopDeckTutor.Decks.{Deck, DeckEntry}
  alias TopDeckTutor.Formats.Commander

  describe "metadata" do
    test "defines the commander format" do
      assert Commander.key() == "commander"
      assert Commander.display_name() == "Commander"
      assert Commander.allowed_sections() == ["mainboard", "sideboard", "maybeboard", "command"]
    end
  end

  describe "legal_card?/2" do
    test "uses card legalities for the selected format" do
      legal_card = %Card{legalities: %{"commander" => "legal"}}
      banned_card = %Card{legalities: %{"commander" => "banned"}}
      missing_legality = %Card{legalities: %{"modern" => "legal"}}

      assert Commander.legal_card?(legal_card, "commander")
      refute Commander.legal_card?(banned_card, "commander")
      refute Commander.legal_card?(missing_legality, "commander")
    end
  end

  describe "max_copies/2" do
    test "allows one copy of non-basic cards" do
      card = %Card{name: "Sol Ring", type_line: "Artifact"}

      assert Commander.max_copies(card, "commander") == 1
    end

    test "does not limit basic lands" do
      card = %Card{name: "Island", type_line: "Basic Land — Island"}

      assert Commander.max_copies(card, "commander") == :unlimited
    end
  end

  describe "validate_deck/1" do
    test "requires a commander in the command section" do
      deck = %Deck{deck_entries: []}

      assert Commander.validate_deck(deck) ==
               {:error, ["Commander decks must include a commander"]}
    end

    test "allows cards within the commander's color identity" do
      deck =
        deck_with_entries([
          entry("command", "Alela, Artful Provocateur", ["W", "U", "B"]),
          entry("mainboard", "Swords to Plowshares", ["W"]),
          entry("mainboard", "Counterspell", ["U"]),
          entry("mainboard", "Arcane Signet", [])
        ])

      assert Commander.validate_deck(deck) == :ok
    end

    test "rejects cards outside the commander's color identity" do
      deck =
        deck_with_entries([
          entry("command", "Alela, Artful Provocateur", ["W", "U", "B"]),
          entry("mainboard", "Lightning Bolt", ["R"])
        ])

      assert Commander.validate_deck(deck) ==
               {:error, ["Lightning Bolt has color identity outside Alela, Artful Provocateur"]}
    end
  end

  defp deck_with_entries(entries), do: %Deck{deck_entries: entries}

  defp entry(section, name, color_identity) do
    %DeckEntry{
      section: section,
      quantity: 1,
      card: %Card{name: name, color_identity: color_identity}
    }
  end
end
