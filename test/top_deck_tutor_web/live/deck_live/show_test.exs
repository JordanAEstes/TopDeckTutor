defmodule TopDeckTutorWeb.DeckLive.ShowTest do
  use TopDeckTutorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  alias TopDeckTutor.Decks

  setup :register_and_log_in_user

  test "add-card search uses a name-only dropdown after three characters", %{
    conn: conn,
    user: user
  } do
    deck = deck_fixture(user)

    card =
      card_fixture(%{
        name: "Sol Ring",
        normalized_name: "sol ring",
        type_line: "Artifact"
      })

    _duplicate_printing =
      card_fixture(%{
        name: "Sol Ring",
        normalized_name: "sol ring",
        set_code: "clu",
        type_line: "Artifact"
      })

    _other =
      card_fixture(%{
        name: "Solemn Simulacrum",
        normalized_name: "solemn simulacrum"
      })

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#card-search-input")
    |> render_keyup(%{"value" => "So"})

    refute has_element?(view, "#card-search-option-#{card.id}")

    view
    |> element("#card-search-input")
    |> render_keyup(%{"value" => "Sol R"})

    assert has_element?(view, "#card-search-option-#{card.id}", "Sol Ring")
    refute render(view) =~ "Artifact"
    assert render(view) =~ "card-search-results"
  end

  test "clicking a card in the dropdown adds one copy to the mainboard", %{
    conn: conn,
    user: user
  } do
    deck = deck_fixture(user)
    card = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#card-search-input")
    |> render_keyup(%{"value" => "Sol"})

    view
    |> element("#card-search-option-#{card.id}")
    |> render_click()

    refute has_element?(view, "#add-card-form")

    assert [%{card_id: card_id, section: "mainboard", quantity: 1}] = Decks.list_entries(deck)
    assert card_id == card.id
  end

  test "shows an import decklist button and opens the import modal", %{
    conn: conn,
    user: user
  } do
    deck = deck_fixture(user)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    assert has_element?(view, "#open-deck-importer", "Import Decklist")

    view
    |> element("#open-deck-importer")
    |> render_click()

    assert has_element?(view, "#deck-import-modal")
    assert has_element?(view, "#deck-import-form")
    assert has_element?(view, "#deck-import-textarea")
  end

  test "successful import updates rendered deck contents", %{
    conn: conn,
    user: user
  } do
    deck = deck_fixture(user)
    sol_ring = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})
    brainstorm = card_fixture(%{name: "Brainstorm", normalized_name: "brainstorm"})

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#open-deck-importer")
    |> render_click()

    view
    |> element("#deck-import-form")
    |> render_submit(%{"import" => %{"decklist" => "Sol Ring\n2 Brainstorm"}})

    entries = Decks.list_entries(deck)
    sol_ring_entry = Enum.find(entries, &(&1.card_id == sol_ring.id))
    brainstorm_entry = Enum.find(entries, &(&1.card_id == brainstorm.id))

    assert sol_ring_entry.quantity == 1
    assert brainstorm_entry.quantity == 2
    assert has_element?(view, "#deck-entry-#{sol_ring_entry.id}", "Sol Ring")
    assert has_element?(view, "#deck-entry-#{brainstorm_entry.id}", "Brainstorm")
    refute has_element?(view, "#deck-import-modal")
  end

  test "import errors are displayed and existing cards remain", %{
    conn: conn,
    user: user
  } do
    deck = deck_fixture(user)
    sol_ring = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})
    assert {:ok, existing_entry} = Decks.add_card(deck, sol_ring, %{quantity: 1})

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#open-deck-importer")
    |> render_click()

    view
    |> element("#deck-import-form")
    |> render_submit(%{"import" => %{"decklist" => "2 Missing Card"}})

    assert has_element?(view, "#deck-import-errors", "line 1 (Missing Card): card not found")
    assert has_element?(view, "#deck-import-modal")

    assert [%{id: entry_id, card_id: card_id, quantity: 1}] = Decks.list_entries(deck)
    assert entry_id == existing_entry.id
    assert card_id == sol_ring.id
  end

  test "commander decks only show cards within the commander's color identity", %{
    conn: conn,
    user: user
  } do
    deck = deck_fixture(user, %{format: "commander"})

    commander =
      card_fixture(%{
        name: "Alela, Artful Provocateur",
        normalized_name: "alela artful provocateur",
        color_identity: ["W", "U", "B"]
      })

    white_card =
      card_fixture(%{
        name: "Light of Hope",
        normalized_name: "light of hope",
        color_identity: ["W"]
      })

    red_card =
      card_fixture(%{
        name: "Lightning Bolt",
        normalized_name: "lightning bolt",
        color_identity: ["R"]
      })

    colorless_card =
      card_fixture(%{
        name: "Lightwheel Enhancements",
        normalized_name: "lightwheel enhancements",
        color_identity: []
      })

    assert {:ok, _entry} = Decks.set_commander(deck, commander)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#card-search-input")
    |> render_keyup(%{"value" => "Light"})

    assert has_element?(view, "#card-search-option-#{white_card.id}", white_card.name)
    assert has_element?(view, "#card-search-option-#{colorless_card.id}", colorless_card.name)
    refute has_element?(view, "#card-search-option-#{red_card.id}")
  end
end
