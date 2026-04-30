defmodule TopDeckTutor.Search.AdvancedFormTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.Search.AdvancedForm

  import TopDeckTutor.AccountsFixtures
  import TopDeckTutor.DecksFixtures

  describe "build/2" do
    test "maps populated params to AST nodes and selected deck scope" do
      user = user_fixture()
      deck = deck_fixture(user)

      result =
        AdvancedForm.build(
          %{
            "name" => "Sol",
            "oracle_text" => "draw",
            "mana_cost" => "{1}{U}",
            "mana_value" => "2",
            "card_type" => "creature",
            "colors" => ["W", "U"],
            "color_identity" => ["B", "R"],
            "keyword" => "flying",
            "power" => "3",
            "toughness" => "4",
            "rarity" => "rare",
            "legality_status" => "legal",
            "legality_format" => "commander",
            "scope" => "selected_decks",
            "deck_ids" => [deck.id]
          },
          %{user: user}
        )

      assert result.changeset.valid?

      assert result.ast == [
               {:field_contains, :name, "Sol"},
               {:field_contains, :oracle_text, "draw"},
               {:field_contains, :mana_cost, "{1}{U}"},
               {:cmp, :mana_value, :==, Decimal.new("2")},
               {:field_eq, :type, "creature"},
               {:color, ["W", "U"]},
               {:color_identity, ["B", "R"]},
               {:keyword, "flying"},
               {:cmp, :power, :==, 3},
               {:cmp, :toughness, :==, 4},
               {:field_eq, :rarity, "rare"},
               {:legality, "commander", "legal"}
             ]

      assert result.scope == {:decks, [deck.id]}
    end

    test "ignores empty fields and falls back to catalog scope for signed-out users" do
      result =
        AdvancedForm.build(
          %{
            "name" => "  ",
            "oracle_text" => "",
            "mana_value" => "",
            "colors" => [""],
            "color_identity" => [],
            "deck_ids" => [],
            "scope" => "selected_decks"
          },
          %{user: nil}
        )

      assert result.changeset.valid?
      assert result.ast == []
      assert result.scope == :catalog
    end

    test "maps legality, color, and color identity distinctly" do
      result =
        AdvancedForm.build(
          %{
            "colors" => ["C"],
            "color_identity" => ["G"],
            "legality_status" => "banned",
            "legality_format" => "legacy"
          },
          %{user: nil}
        )

      assert result.changeset.valid?

      assert result.ast == [
               {:color, []},
               {:color_identity, ["G"]},
               {:legality, "legacy", "banned"}
             ]
    end

    test "validates integer-only fields" do
      result =
        AdvancedForm.build(
          %{
            "mana_value" => "two",
            "power" => "3.5",
            "toughness" => "x"
          },
          %{user: nil}
        )

      refute result.changeset.valid?

      assert errors_on(result.changeset) == %{
               mana_value: ["must be a whole number"],
               power: ["must be a whole number"],
               toughness: ["must be a whole number"]
             }

      assert result.ast == []
      assert result.scope == :catalog
    end

    test "keeps only decks owned by the current user in selected deck scope" do
      user = user_fixture()
      owned_deck = deck_fixture(user)
      other_user = user_fixture()
      other_deck = deck_fixture(other_user)

      result =
        AdvancedForm.build(
          %{
            "scope" => "selected_decks",
            "deck_ids" => [owned_deck.id, other_deck.id]
          },
          %{user: user}
        )

      assert result.changeset.valid?
      assert result.scope == {:decks, [owned_deck.id]}
    end
  end

  describe "to_query/1" do
    test "serializes advanced AST into the main search query language" do
      ast = [
        {:field_contains, :name, "Sol Ring"},
        {:field_contains, :mana_cost, "{1}{U}"},
        {:cmp, :mana_value, :==, Decimal.new("2")},
        {:field_eq, :rarity, "rare"},
        {:color, ["W", "U"]},
        {:legality, "commander", "legal"}
      ]

      assert AdvancedForm.to_query(ast) ==
               ~s(name:"Sol Ring" mana:{1}{U} mv=2 rarity:rare color:wu legal:commander)
    end
  end
end
