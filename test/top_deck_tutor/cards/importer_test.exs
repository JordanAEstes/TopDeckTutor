defmodule TopDeckTutor.Cards.ImporterTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Cards.Importer

  describe "import_cards/1" do
    test "imports card payloads" do
      cards = [
        %{
          "id" => Ecto.UUID.generate(),
          "oracle_id" => Ecto.UUID.generate(),
          "name" => "Brushland",
          "lang" => "en",
          "cmc" => 0.0
        },
        %{
          "id" => Ecto.UUID.generate(),
          "oracle_id" => Ecto.UUID.generate(),
          "name" => "Sol Ring",
          "lang" => "en",
          "cmc" => 1.0
        }
      ]

      result = Importer.import_cards(cards)

      assert result.ok == 2
      assert result.error == 0

      assert Cards.get_card_by_name("Brushland")
      assert Cards.get_card_by_name("Sol Ring")
    end

    test "upserts an existing card by id" do
      id = Ecto.UUID.generate()

      first = [
        %{
          "id" => id,
          "oracle_id" => Ecto.UUID.generate(),
          "name" => "Arcane Signet",
          "lang" => "en",
          "cmc" => 2.0
        }
      ]

      second = [
        %{
          "id" => id,
          "oracle_id" => Ecto.UUID.generate(),
          "name" => "Arcane Signet Reprint",
          "lang" => "en",
          "cmc" => 2.0
        }
      ]

      assert %{ok: 1, error: 0} = Importer.import_cards(first)
      assert %{ok: 1, error: 0} = Importer.import_cards(second)

      card = Cards.get_card!(id)
      assert card.name == "Arcane Signet Reprint"
    end
  end
end
