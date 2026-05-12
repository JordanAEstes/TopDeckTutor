defmodule TopDeckTutor.Decks.DeckExporterTest do
  use TopDeckTutor.DataCase, async: true

  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.DeckExporter

  describe "export_text/2" do
    test "exports default format with quantity, name, set code, and collector number" do
      deck = deck_fixture()

      lightning_bolt =
        card_fixture(%{
          name: "Lightning Bolt",
          normalized_name: "lightning bolt",
          set_code: "m11",
          collector_number: "146"
        })

      sol_ring =
        card_fixture(%{
          name: "Sol Ring",
          normalized_name: "sol ring",
          set_code: "cmm",
          collector_number: "396"
        })

      {:ok, _entry} = Decks.add_card(deck, lightning_bolt, %{quantity: 4})
      {:ok, _entry} = Decks.add_card(deck, sol_ring, %{quantity: 1})

      assert DeckExporter.export_text(deck) == "4 Lightning Bolt (M11) 146\n1 Sol Ring (CMM) 396"
    end

    test "exports without set code when disabled" do
      deck = deck_fixture()

      card =
        card_fixture(%{
          name: "Lightning Bolt",
          normalized_name: "lightning bolt",
          set_code: "m11",
          collector_number: "146"
        })

      {:ok, _entry} = Decks.add_card(deck, card, %{quantity: 4})

      assert DeckExporter.export_text(deck, include_set_code: false) == "4 Lightning Bolt 146"
    end

    test "exports without collector number when disabled" do
      deck = deck_fixture()

      card =
        card_fixture(%{
          name: "Sol Ring",
          normalized_name: "sol ring",
          set_code: "cmm",
          collector_number: "396"
        })

      {:ok, _entry} = Decks.add_card(deck, card, %{quantity: 1})

      assert DeckExporter.export_text(deck, include_collector_number: false) == "1 Sol Ring (CMM)"
    end

    test "exports without both optional fields when both are disabled" do
      deck = deck_fixture()

      card =
        card_fixture(%{
          name: "Brainstorm",
          normalized_name: "brainstorm",
          set_code: "mh2",
          collector_number: "267"
        })

      {:ok, _entry} = Decks.add_card(deck, card, %{quantity: 2})

      assert DeckExporter.export_text(deck,
               include_set_code: false,
               include_collector_number: false
             ) == "2 Brainstorm"
    end

    test "handles empty decks" do
      deck = deck_fixture()

      assert DeckExporter.export_text(deck) == ""
    end

    test "exports in deterministic deck entry order" do
      deck = deck_fixture()

      sideboard =
        card_fixture(%{
          name: "Sideboard Card",
          normalized_name: "sideboard card",
          set_code: "abc",
          collector_number: "2"
        })

      mainboard =
        card_fixture(%{
          name: "Mainboard Card",
          normalized_name: "mainboard card",
          set_code: "abc",
          collector_number: "1"
        })

      {:ok, _entry} = Decks.add_card(deck, sideboard, %{section: "sideboard"})
      {:ok, _entry} = Decks.add_card(deck, mainboard, %{section: "mainboard"})

      assert DeckExporter.export_text(deck) ==
               "1 Mainboard Card (ABC) 1\n1 Sideboard Card (ABC) 2"
    end
  end
end
