defmodule TopDeckTutor.CardsTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Cards.Card

  import TopDeckTutor.CardsFixtures

  @colors ["W", "U", "B", "R", "G"]

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

    test "search_query/1 defaults plain text terms to name filters" do
      matching =
        card_fixture(%{
          name: "Divination",
          normalized_name: "divination",
          oracle_text: "Look at the top three cards of your library."
        })

      _oracle_text_only_match =
        card_fixture(%{
          name: "Strategic Planning",
          normalized_name: "strategic planning",
          oracle_text: "Draw two cards."
        })

      assert {:ok, results} = Cards.search_query("Divin")
      assert Enum.map(results, & &1.id) == [matching.id]
    end

    test "search_ast_page/2 paginates 60 results per page" do
      for index <- 1..65 do
        card_fixture(%{
          name: "Paged Result #{index}",
          normalized_name: "paged result #{index}"
        })
      end

      assert {:ok, ast} = TopDeckTutor.Search.parse("Paged Result")

      page_one = Cards.search_ast_page(ast, page: 1, page_size: 60)
      page_two = Cards.search_ast_page(ast, page: 2, page_size: 60)

      assert page_one.total_count == 65
      assert page_one.total_pages == 2
      assert page_one.page == 1
      assert length(page_one.results) == 60

      assert page_two.total_count == 65
      assert page_two.total_pages == 2
      assert page_two.page == 2
      assert length(page_two.results) == 5
    end

    test "search_query/1 returns unique results by name" do
      _first_printing =
        card_fixture(%{
          name: "Lightning Bolt",
          normalized_name: "lightning bolt",
          set_code: "lea"
        })

      _second_printing =
        card_fixture(%{
          name: "Lightning Bolt",
          normalized_name: "lightning bolt",
          set_code: "clu"
        })

      assert {:ok, results} = Cards.search_query("Lightning Bolt")
      assert length(results) == 1
      assert Enum.map(results, & &1.name) == ["Lightning Bolt"]
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

    test "search_query/1 supports every non-empty color identity combination" do
      cards_by_colors =
        for colors <- color_combinations(@colors), into: %{} do
          name = "CI #{Enum.join(colors)}"

          card =
            card_fixture(%{
              name: name,
              normalized_name: String.downcase(name),
              color_identity: colors
            })

          {colors, card}
        end

      for colors <- color_combinations(@colors) do
        token = colors |> Enum.join() |> String.downcase()

        expected_ids =
          cards_by_colors
          |> expected_color_identity_matches(colors)
          |> Enum.map(& &1.id)
          |> Enum.sort()

        assert {:ok, results} = Cards.search_query("ci:#{token}")
        assert Enum.map(results, & &1.id) |> Enum.sort() == expected_ids
      end
    end

    test "search_query/1 supports rarity and set filters" do
      rare_match =
        card_fixture(%{
          name: "Rare Match",
          normalized_name: "rare match",
          rarity: "rare",
          set_code: "m19"
        })

      mythic_match =
        card_fixture(%{
          name: "Mythic Match",
          normalized_name: "mythic match",
          rarity: "mythic",
          set_code: "mh3"
        })

      _other =
        card_fixture(%{
          name: "Other Card",
          normalized_name: "other card",
          rarity: "common",
          set_code: "neo"
        })

      assert {:ok, rare_results} = Cards.search_query("rarity:rare")
      assert Enum.map(rare_results, & &1.id) == [rare_match.id]

      assert {:ok, mythic_results} = Cards.search_query("rarity:mythic")
      assert Enum.map(mythic_results, & &1.id) == [mythic_match.id]

      assert {:ok, m19_results} = Cards.search_query("set:m19")
      assert Enum.map(m19_results, & &1.id) == [rare_match.id]

      assert {:ok, mh3_results} = Cards.search_query("set:mh3")
      assert Enum.map(mh3_results, & &1.id) == [mythic_match.id]
    end

    test "search_query/1 supports legality filters" do
      commander_match =
        card_fixture(%{
          name: "Commander Legal",
          normalized_name: "commander legal",
          legalities: %{"commander" => "legal"}
        })

      modern_match =
        card_fixture(%{
          name: "Modern Legal",
          normalized_name: "modern legal",
          legalities: %{"modern" => "legal"}
        })

      legacy_banned_match =
        card_fixture(%{
          name: "Legacy Banned",
          normalized_name: "legacy banned",
          legalities: %{"legacy" => "banned"}
        })

      vintage_restricted_match =
        card_fixture(%{
          name: "Vintage Restricted",
          normalized_name: "vintage restricted",
          legalities: %{"vintage" => "restricted"}
        })

      _other =
        card_fixture(%{
          name: "Legality Other",
          normalized_name: "legality other",
          legalities: %{"commander" => "not_legal", "legacy" => "legal", "vintage" => "legal"}
        })

      assert {:ok, commander_results} = Cards.search_query("legal:commander")
      assert Enum.map(commander_results, & &1.id) == [commander_match.id]

      assert {:ok, modern_results} = Cards.search_query("legal:modern")
      assert Enum.map(modern_results, & &1.id) == [modern_match.id]

      assert {:ok, banned_results} = Cards.search_query("banned:legacy")
      assert Enum.map(banned_results, & &1.id) == [legacy_banned_match.id]

      assert {:ok, restricted_results} = Cards.search_query("restricted:vintage")
      assert Enum.map(restricted_results, & &1.id) == [vintage_restricted_match.id]
    end

    test "search_query/1 supports color filters and keeps color distinct from color identity" do
      color_match =
        card_fixture(%{
          name: "Color Match",
          normalized_name: "color match",
          colors: ["W", "U"],
          color_identity: ["W", "U"]
        })

      colorless_match =
        card_fixture(%{
          name: "Colorless Match",
          normalized_name: "colorless match",
          colors: [],
          color_identity: []
        })

      color_identity_only =
        card_fixture(%{
          name: "Identity Only",
          normalized_name: "identity only",
          colors: [],
          color_identity: ["G"]
        })

      white_match =
        card_fixture(%{
          name: "Other Color",
          normalized_name: "other color",
          colors: ["W"],
          color_identity: ["W"]
        })

      assert {:ok, white_results} = Cards.search_query("color:w")

      assert Enum.map(white_results, & &1.id) |> Enum.sort() ==
               Enum.sort([color_match.id, white_match.id])

      assert {:ok, azorius_results} = Cards.search_query("color:wu")
      assert Enum.map(azorius_results, & &1.id) == [color_match.id]

      assert {:ok, colorless_results} = Cards.search_query("color:c")

      assert Enum.map(colorless_results, & &1.id) |> Enum.sort() ==
               Enum.sort([colorless_match.id, color_identity_only.id])

      assert {:ok, ci_results} = Cards.search_query("ci:g")
      assert Enum.map(ci_results, & &1.id) == [color_identity_only.id]
    end

    test "search_query/1 supports game filters" do
      paper_match =
        card_fixture(%{
          name: "Paper Match",
          normalized_name: "paper match",
          games: ["paper", "mtgo"]
        })

      arena_match =
        card_fixture(%{
          name: "Arena Match",
          normalized_name: "arena match",
          games: ["arena"]
        })

      _other =
        card_fixture(%{
          name: "No Paper",
          normalized_name: "no paper",
          games: ["mtgo"]
        })

      assert {:ok, paper_results} = Cards.search_query("game:paper")
      assert Enum.map(paper_results, & &1.id) == [paper_match.id]

      assert {:ok, arena_results} = Cards.search_query("game:arena")
      assert Enum.map(arena_results, & &1.id) |> Enum.sort() == Enum.sort([arena_match.id])
    end

    test "search_query/1 supports keyword filters" do
      flying_match =
        card_fixture(%{
          name: "Flying Match",
          normalized_name: "flying match",
          keywords: ["Flying", "Ward"]
        })

      trample_match =
        card_fixture(%{
          name: "Trample Match",
          normalized_name: "trample match",
          keywords: ["Trample"]
        })

      _other =
        card_fixture(%{
          name: "Keyword Other",
          normalized_name: "keyword other",
          keywords: ["Haste"]
        })

      assert {:ok, flying_results} = Cards.search_query("keyword:flying")
      assert Enum.map(flying_results, & &1.id) == [flying_match.id]

      assert {:ok, ward_results} = Cards.search_query("keyword:ward")
      assert Enum.map(ward_results, & &1.id) == [flying_match.id]

      assert {:ok, trample_results} = Cards.search_query("keyword:trample")
      assert Enum.map(trample_results, & &1.id) == [trample_match.id]
    end

    test "search_query/1 supports literal power and toughness comparisons for numeric values only" do
      power_three =
        card_fixture(%{
          name: "Power Three",
          normalized_name: "power three",
          power: "3",
          toughness: "2"
        })

      power_four =
        card_fixture(%{
          name: "Power Four",
          normalized_name: "power four",
          power: "4",
          toughness: "4"
        })

      toughness_two =
        card_fixture(%{
          name: "Toughness Two",
          normalized_name: "toughness two",
          power: "1",
          toughness: "2"
        })

      _non_numeric =
        card_fixture(%{
          name: "Variable Stats",
          normalized_name: "variable stats",
          power: "1+*",
          toughness: "*"
        })

      _nil_stats =
        card_fixture(%{
          name: "No Stats",
          normalized_name: "no stats"
        })

      assert {:ok, power_three_results} = Cards.search_query("power=3")
      assert Enum.map(power_three_results, & &1.id) == [power_three.id]

      assert {:ok, power_four_results} = Cards.search_query("power>=4")
      assert Enum.map(power_four_results, & &1.id) == [power_four.id]

      assert {:ok, toughness_two_results} = Cards.search_query("toughness<=2")

      assert Enum.map(toughness_two_results, & &1.id) |> Enum.sort() ==
               Enum.sort([power_three.id, toughness_two.id])
    end

    test "search_query/1 supports field-to-field power and toughness comparisons for numeric values only" do
      power_greater =
        card_fixture(%{
          name: "Power Greater",
          normalized_name: "power greater",
          power: "4",
          toughness: "2"
        })

      equal_stats =
        card_fixture(%{
          name: "Equal Stats",
          normalized_name: "equal stats",
          power: "3",
          toughness: "3"
        })

      toughness_greater =
        card_fixture(%{
          name: "Toughness Greater",
          normalized_name: "toughness greater",
          power: "1",
          toughness: "5"
        })

      _non_numeric =
        card_fixture(%{
          name: "Star Stats",
          normalized_name: "star stats",
          power: "*",
          toughness: "3"
        })

      _nil_stats =
        card_fixture(%{
          name: "No Field Stats",
          normalized_name: "no field stats"
        })

      assert {:ok, power_greater_results} = Cards.search_query("power>toughness")
      assert Enum.map(power_greater_results, & &1.id) == [power_greater.id]

      assert {:ok, equal_results} = Cards.search_query("power=toughness")
      assert Enum.map(equal_results, & &1.id) == [equal_stats.id]

      assert {:ok, toughness_greater_results} = Cards.search_query("toughness>power")
      assert Enum.map(toughness_greater_results, & &1.id) == [toughness_greater.id]
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
