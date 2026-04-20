defmodule TopDeckTutor.Cards.NormalizerTest do
  use ExUnit.Case, async: true

  alias TopDeckTutor.Cards.Normalizer

  describe "from_scryfall/1" do
    test "maps a Scryfall card payload into app attrs" do
      payload = %{
        "id" => "70afcfca-c065-4a33-95b1-ec2b08bcb493",
        "oracle_id" => "5eb8b497-ec9a-4a89-ad29-1ec3ca82da7c",
        "name" => "Brushland",
        "lang" => "en",
        "cmc" => 0.0,
        "mana_cost" => "",
        "type_line" => "Land",
        "oracle_text" => "{T}: Add {C}.",
        "colors" => [],
        "color_identity" => ["G", "W"],
        "keywords" => [],
        "produced_mana" => ["C", "G", "W"],
        "layout" => "normal",
        "released_at" => "2007-07-13",
        "set" => "10e",
        "set_name" => "Tenth Edition",
        "set_type" => "core",
        "collector_number" => "349",
        "rarity" => "rare",
        "legalities" => %{"commander" => "legal"},
        "games" => ["paper", "mtgo"],
        "finishes" => ["nonfoil", "foil"],
        "reserved" => false,
        "game_changer" => false,
        "digital" => false,
        "foil" => true,
        "nonfoil" => true,
        "oversized" => false,
        "promo" => false,
        "reprint" => true,
        "variation" => false,
        "full_art" => false,
        "textless" => false,
        "booster" => true,
        "story_spotlight" => false,
        "image_uris" => %{"normal" => "https://example.com/brushland.jpg"},
        "artist" => "Scott Bailey",
        "border_color" => "black",
        "frame" => "2003",
        "edhrec_rank" => 250,
        "penny_rank" => 109
      }

      attrs = Normalizer.from_scryfall(payload)

      assert attrs.id == payload["id"]
      assert attrs.oracle_id == payload["oracle_id"]
      assert attrs.name == "Brushland"
      assert attrs.normalized_name == "brushland"
      assert attrs.mana_value == Decimal.new("0.0")
      assert attrs.is_land
      refute attrs.is_creature
      assert attrs.released_at == ~D[2007-07-13]
      assert attrs.set_code == "10e"
      assert attrs.raw == payload
    end

    test "falls back to the first face for reversible or multiface cards" do
      payload = %{
        "id" => "018830b2-dff9-45f3-9cc2-dc5b2eec0e54",
        "name" => "Jinnie Fay, Jetmir's Second // Jinnie Fay, Jetmir's Second",
        "lang" => "en",
        "cmc" => 0.0,
        "layout" => "reversible_card",
        "released_at" => "2024-01-22",
        "set" => "sld",
        "set_name" => "Secret Lair Drop",
        "set_type" => "box",
        "collector_number" => "1556",
        "rarity" => "rare",
        "legalities" => %{"commander" => "legal"},
        "games" => ["paper"],
        "finishes" => ["nonfoil"],
        "artist" => "Jack Hughes",
        "border_color" => "borderless",
        "frame" => "2015",
        "card_faces" => [
          %{
            "oracle_id" => "d3c08efa-f2f9-4f3c-86b5-34c60ae72d74",
            "name" => "Jinnie Fay, Jetmir's Second",
            "mana_cost" => "{R}{G}{W}",
            "type_line" => "Legendary Creature - Elf Druid",
            "oracle_text" =>
              "If you would create one or more tokens, you may instead create that many 2/2 green Cat creature tokens with haste.",
            "colors" => ["G", "R", "W"],
            "power" => "3",
            "toughness" => "3",
            "image_uris" => %{"normal" => "https://example.com/jinnie-fay.jpg"}
          }
        ]
      }

      attrs = Normalizer.from_scryfall(payload)

      assert attrs.oracle_id == "d3c08efa-f2f9-4f3c-86b5-34c60ae72d74"
      assert attrs.name == "Jinnie Fay, Jetmir's Second"
      assert attrs.normalized_name == "jinnie fay jetmirs second"
      assert attrs.mana_cost == "{R}{G}{W}"
      assert attrs.type_line == "Legendary Creature - Elf Druid"
      assert attrs.oracle_text =~ "create one or more tokens"
      assert attrs.colors == ["G", "R", "W"]
      assert attrs.power == "3"
      assert attrs.toughness == "3"
      assert attrs.image_uris == %{"normal" => "https://example.com/jinnie-fay.jpg"}
      assert attrs.is_creature
      assert attrs.is_legendary
    end
  end

  describe "normalize_name/1" do
    test "normalizes punctuation and spacing" do
      assert Normalizer.normalize_name("Atraxa, Grand Unifier") == "atraxa grand unifier"
    end
  end
end
