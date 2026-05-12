defmodule TopDeckTutor.Decks.DeckImporterTest do
  use TopDeckTutor.DataCase, async: true

  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  alias TopDeckTutor.Decks
  alias TopDeckTutor.Decks.DeckImporter

  describe "parse_text/1" do
    test "parses quantity, card name, and set code" do
      assert {:ok, rows} = DeckImporter.parse_text("4 Lightning Bolt (M11)")

      assert [
               %{
                 line_number: 1,
                 quantity: 4,
                 card_name: "Lightning Bolt",
                 set_code: "m11",
                 collector_number: nil
               }
             ] = rows
    end

    test "parses quantity, card name, set code, and collector number" do
      assert {:ok, rows} = DeckImporter.parse_text("4 Lightning Bolt (M11) 149")

      assert [
               %{
                 line_number: 1,
                 quantity: 4,
                 card_name: "Lightning Bolt",
                 set_code: "m11",
                 collector_number: "149"
               }
             ] = rows
    end

    test "parses name-only lines and defaults quantity to one" do
      assert {:ok, rows} = DeckImporter.parse_text("Sol Ring")

      assert [
               %{
                 line_number: 1,
                 quantity: 1,
                 card_name: "Sol Ring",
                 set_code: nil,
                 collector_number: nil
               }
             ] = rows
    end

    test "ignores blank lines" do
      assert {:ok, rows} = DeckImporter.parse_text("\n2 Brainstorm\n\nSol Ring\n")

      assert Enum.map(rows, & &1.line_number) == [2, 4]
      assert Enum.map(rows, & &1.card_name) == ["Brainstorm", "Sol Ring"]
    end

    test "returns line-numbered errors for malformed lines" do
      assert {:error, errors} = DeckImporter.parse_text("4\n0 Sol Ring\n")

      assert errors == [
               %{line_number: 1, card_text: "4", message: "malformed line"},
               %{line_number: 2, card_text: "Sol Ring", message: "invalid quantity"}
             ]
    end
  end

  describe "import_text/3" do
    test "resolves exact printing when set code is present" do
      deck = deck_fixture()

      _other_printing =
        card_fixture(%{
          name: "Lightning Bolt",
          normalized_name: "lightning bolt",
          set_code: "lea",
          released_at: ~D[1993-08-05]
        })

      m11_printing =
        card_fixture(%{
          name: "Lightning Bolt",
          normalized_name: "lightning bolt",
          set_code: "m11",
          released_at: ~D[2010-07-16]
        })

      assert {:ok, %{imported_count: 4}} =
               DeckImporter.import_text(deck, "4 Lightning Bolt (M11)")

      assert [%{card_id: card_id, quantity: 4, section: "mainboard"}] = Decks.list_entries(deck)
      assert card_id == m11_printing.id
    end

    test "resolves exact collector number when set code and collector number are present" do
      deck = deck_fixture()

      _first_printing =
        card_fixture(%{
          name: "Lightning Bolt",
          normalized_name: "lightning bolt",
          set_code: "m11",
          collector_number: "149"
        })

      selected_printing =
        card_fixture(%{
          name: "Lightning Bolt",
          normalized_name: "lightning bolt",
          set_code: "m11",
          collector_number: "150"
        })

      assert {:ok, %{imported_count: 4}} =
               DeckImporter.import_text(deck, "4 Lightning Bolt (M11) 150")

      assert [%{card_id: card_id, quantity: 4, section: "mainboard"}] = Decks.list_entries(deck)
      assert card_id == selected_printing.id
    end

    test "resolves the lowest collector number when set code is present without collector number" do
      deck = deck_fixture()

      _higher_printing =
        card_fixture(%{
          name: "Island",
          normalized_name: "island",
          set_code: "unf",
          collector_number: "236"
        })

      lowest_printing =
        card_fixture(%{
          name: "Island",
          normalized_name: "island",
          set_code: "unf",
          collector_number: "235"
        })

      assert {:ok, %{imported_count: 1}} = DeckImporter.import_text(deck, "Island (UNF)")

      assert [%{card_id: card_id, quantity: 1, section: "mainboard"}] = Decks.list_entries(deck)
      assert card_id == lowest_printing.id
    end

    test "resolves a preferred deterministic printing when set code is omitted" do
      deck = deck_fixture()

      _digital =
        card_fixture(%{
          name: "Opt",
          normalized_name: "opt",
          set_code: "yneo",
          released_at: ~D[2024-01-01],
          digital: true,
          games: ["arena"]
        })

      older_paper =
        card_fixture(%{
          name: "Opt",
          normalized_name: "opt",
          set_code: "dom",
          released_at: ~D[2018-04-27],
          digital: false,
          games: ["paper"]
        })

      preferred =
        card_fixture(%{
          name: "Opt",
          normalized_name: "opt",
          set_code: "sta",
          released_at: ~D[2021-04-23],
          digital: false,
          games: ["paper"]
        })

      assert {:ok, %{imported_count: 1}} = DeckImporter.import_text(deck, "Opt")

      assert [%{card_id: card_id, quantity: 1}] = Decks.list_entries(deck)
      assert card_id == preferred.id
      refute card_id == older_paper.id
    end

    test "returns errors for unknown cards and unknown set codes" do
      deck = deck_fixture()
      card_fixture(%{name: "Sol Ring", normalized_name: "sol ring", set_code: "cmm"})

      assert {:error, errors} =
               DeckImporter.import_text(deck, "Missing Card\nSol Ring (ABC)")

      assert errors == [
               %{line_number: 1, card_text: "Missing Card", message: "card not found"},
               %{
                 line_number: 2,
                 card_text: "Sol Ring",
                 message: "no printing found for set ABC"
               }
             ]
    end

    test "appends cards and increments matching mainboard entries" do
      deck = deck_fixture()
      sol_ring = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})
      brainstorm = card_fixture(%{name: "Brainstorm", normalized_name: "brainstorm"})

      assert {:ok, _entry} = Decks.add_card(deck, sol_ring, %{quantity: 1})

      assert {:ok, %{imported_count: 4}} =
               DeckImporter.import_text(deck, "3 Sol Ring\n1 Brainstorm")

      entries = Decks.list_entries(deck)

      assert Enum.find(entries, &(&1.card_id == sol_ring.id)).quantity == 4
      assert Enum.find(entries, &(&1.card_id == brainstorm.id)).quantity == 1
    end

    test "does not partially import when any line fails" do
      deck = deck_fixture()
      sol_ring = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})

      assert {:error, [%{line_number: 2, card_text: "Missing Card", message: "card not found"}]} =
               DeckImporter.import_text(deck, "Sol Ring\nMissing Card")

      assert Decks.list_entries(deck) == []
      assert sol_ring.id
    end
  end
end
