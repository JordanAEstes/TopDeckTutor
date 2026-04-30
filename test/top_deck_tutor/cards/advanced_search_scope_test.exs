defmodule TopDeckTutor.Cards.AdvancedSearchScopeTest do
  use TopDeckTutor.DataCase, async: true

  alias TopDeckTutor.Cards
  alias TopDeckTutor.Search.AdvancedForm

  import TopDeckTutor.AccountsFixtures
  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  test "catalog scope searches the full card catalog" do
    matching = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})
    _other = card_fixture(%{name: "Arcane Signet", normalized_name: "arcane signet"})

    result = AdvancedForm.build(%{"name" => "Sol Ring"}, %{user: nil})

    page = Cards.search_ast_page(result.ast, scope: :catalog)

    assert Enum.map(page.results, & &1.id) == [matching.id]
  end

  test "catalog scope supports advanced mana cost filters through the shared compiler" do
    matching =
      card_fixture(%{
        name: "Negate",
        normalized_name: "negate",
        mana_cost: "{1}{U}"
      })

    _other =
      card_fixture(%{
        name: "Shock",
        normalized_name: "shock",
        mana_cost: "{R}"
      })

    result = AdvancedForm.build(%{"mana_cost" => "{1}{U}"}, %{user: nil})

    page = Cards.search_ast_page(result.ast, scope: :catalog)

    assert Enum.map(page.results, & &1.id) == [matching.id]
  end

  test "selected deck scope only returns cards in the chosen deck" do
    user = user_fixture()
    selected_deck = deck_fixture(user)
    other_deck = deck_fixture(user)

    matching =
      card_fixture(%{
        name: "Swords to Plowshares",
        normalized_name: "swords to plowshares"
      })

    excluded =
      card_fixture(%{
        name: "Swords to Dust",
        normalized_name: "swords to dust"
      })

    {:ok, _} = TopDeckTutor.Decks.add_card(selected_deck, matching)
    {:ok, _} = TopDeckTutor.Decks.add_card(other_deck, excluded)

    result =
      AdvancedForm.build(
        %{"name" => "Swords", "scope" => "selected_decks", "deck_ids" => [selected_deck.id]},
        %{user: user}
      )

    page = Cards.search_ast_page(result.ast, scope: {:decks, {user, elem(result.scope, 1)}})

    assert Enum.map(page.results, & &1.id) == [matching.id]
  end

  test "selected deck scope can search across multiple chosen decks" do
    user = user_fixture()
    first_deck = deck_fixture(user)
    second_deck = deck_fixture(user)

    first_match = card_fixture(%{name: "Counterspell", normalized_name: "counterspell"})

    second_match =
      card_fixture(%{name: "Countervailing Winds", normalized_name: "countervailing winds"})

    _outside = card_fixture(%{name: "Counterlash", normalized_name: "counterlash"})

    {:ok, _} = TopDeckTutor.Decks.add_card(first_deck, first_match)
    {:ok, _} = TopDeckTutor.Decks.add_card(second_deck, second_match)

    result =
      AdvancedForm.build(
        %{
          "name" => "Counter",
          "scope" => "selected_decks",
          "deck_ids" => [first_deck.id, second_deck.id]
        },
        %{user: user}
      )

    page = Cards.search_ast_page(result.ast, scope: {:decks, {user, elem(result.scope, 1)}})

    assert Enum.map(page.results, & &1.id) == [first_match.id, second_match.id]
  end
end
