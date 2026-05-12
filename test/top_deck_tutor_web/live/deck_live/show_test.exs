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
    assert has_element?(view, "#import-decklist-submit.app-button-primary")
  end

  test "shows an export decklist button and opens the export modal", %{
    conn: conn,
    user: user
  } do
    deck = deck_fixture(user)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    assert has_element?(view, "#open-deck-exporter", "Export Decklist")

    view
    |> element("#open-deck-exporter")
    |> render_click()

    assert has_element?(view, "#deck-export-modal")
    assert has_element?(view, "#deck-export-options")
    assert has_element?(view, "#deck-export-textarea")
    assert has_element?(view, "#copy-deck-export.app-button-primary")
  end

  test "successful copy closes the export modal and shows a flash", %{conn: conn, user: user} do
    deck = deck_fixture(user)
    card = card_fixture(%{name: "Brainstorm", normalized_name: "brainstorm"})
    {:ok, _entry} = Decks.add_card(deck, card, %{quantity: 2})

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#open-deck-exporter")
    |> render_click()

    view
    |> element("#copy-deck-export")
    |> render_hook("deck_export_copied")

    refute has_element?(view, "#deck-export-modal")
    assert has_element?(view, "#flash-group", "Decklist copied")
  end

  test "export modal renders the current decklist text", %{conn: conn, user: user} do
    deck = deck_fixture(user)

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

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#open-deck-exporter")
    |> render_click()

    assert has_element?(view, "#deck-export-textarea", "4 Lightning Bolt (M11) 146")
    assert has_element?(view, "#deck-export-textarea", "1 Sol Ring (CMM) 396")
  end

  test "export options update the rendered output", %{conn: conn, user: user} do
    deck = deck_fixture(user)

    card =
      card_fixture(%{
        name: "Lightning Bolt",
        normalized_name: "lightning bolt",
        set_code: "m11",
        collector_number: "146"
      })

    {:ok, _entry} = Decks.add_card(deck, card, %{quantity: 4})

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#open-deck-exporter")
    |> render_click()

    view
    |> element("#deck-export-options")
    |> render_change(%{
      "export" => %{"include_set_code" => "false", "include_collector_number" => "true"}
    })

    assert has_element?(view, "#deck-export-textarea", "4 Lightning Bolt 146")

    view
    |> element("#deck-export-options")
    |> render_change(%{
      "export" => %{"include_set_code" => "true", "include_collector_number" => "false"}
    })

    assert has_element?(view, "#deck-export-textarea", "4 Lightning Bolt (M11)")

    view
    |> element("#deck-export-options")
    |> render_change(%{
      "export" => %{"include_set_code" => "false", "include_collector_number" => "false"}
    })

    assert has_element?(view, "#deck-export-textarea", "4 Lightning Bolt")
  end

  test "empty deck export renders an empty state", %{conn: conn, user: user} do
    deck = deck_fixture(user)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#open-deck-exporter")
    |> render_click()

    assert has_element?(view, "#deck-export-empty", "This deck has no cards to export.")
    assert has_element?(view, "#deck-export-textarea")
  end

  test "export flow does not modify deck contents", %{conn: conn, user: user} do
    deck = deck_fixture(user)

    card =
      card_fixture(%{
        name: "Brainstorm",
        normalized_name: "brainstorm",
        set_code: "mh2",
        collector_number: "267"
      })

    {:ok, entry} = Decks.add_card(deck, card, %{quantity: 2})

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#open-deck-exporter")
    |> render_click()

    view
    |> element("#deck-export-options")
    |> render_change(%{
      "export" => %{"include_set_code" => "false", "include_collector_number" => "false"}
    })

    assert [%{id: entry_id, card_id: card_id, quantity: 2}] = Decks.list_entries(deck)
    assert entry_id == entry.id
    assert card_id == card.id
  end

  test "shows a sort by type toggle and leaves deck entries ungrouped by default", %{
    conn: conn,
    user: user
  } do
    {deck, _entries_by_name} = deck_with_type_entries(user)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    assert has_element?(view, "#deck-sort-type-toggle", "Sort by type")
    refute has_element?(view, "#deck-type-group-mainboard-Creature")
  end

  test "toggling sort by type groups details view entries within deck sections", %{
    conn: conn,
    user: user
  } do
    {deck, _entries_by_name} = deck_with_type_entries(user)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}")

    view
    |> element("#deck-sort-type-toggle")
    |> render_click()

    assert_patch(view, ~p"/decks/#{deck}?sort=type")
    assert has_element?(view, "#deck-section-mainboard", "mainboard")
    assert has_element?(view, "#deck-type-group-mainboard-Creature", "Creature")
    assert has_element?(view, "#deck-type-group-mainboard-Creature", "2 cards")
    assert has_element?(view, "#deck-type-group-mainboard-Instant", "Instant")
    assert has_element?(view, "#deck-type-group-mainboard-Instant", "1 card")
    assert has_element?(view, "#deck-type-group-mainboard-Land", "Land")
    assert has_element?(view, "#deck-type-group-mainboard-Land", "1 card")
    assert has_element?(view, "#deck-type-group-sideboard-Artifact", "Artifact")
    assert has_element?(view, "#deck-type-group-sideboard-Artifact", "1 card")
    refute has_element?(view, "#deck-type-group-mainboard-Planeswalker")
  end

  test "sort by type groups image view entries", %{conn: conn, user: user} do
    {deck, entries_by_name} = deck_with_type_entries(user)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}?view=images")

    view
    |> element("#deck-sort-type-toggle")
    |> render_click()

    assert_patch(view, ~p"/decks/#{deck}?sort=type&view=images")

    assert has_element?(
             view,
             "#deck-type-group-mainboard-Creature #deck-entry-#{entries_by_name["Solemn Simulacrum"].id}"
           )

    assert has_element?(view, "#deck-type-group-mainboard-Creature", "2 cards")

    assert has_element?(
             view,
             "#deck-type-group-mainboard-Instant #deck-entry-#{entries_by_name["Opt"].id}"
           )

    assert has_element?(
             view,
             "#deck-type-group-mainboard-Land #deck-entry-#{entries_by_name["Island"].id}"
           )
  end

  test "sort by type groups list view entries", %{conn: conn, user: user} do
    {deck, entries_by_name} = deck_with_type_entries(user)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}?view=list")

    view
    |> element("#deck-sort-type-toggle")
    |> render_click()

    assert_patch(view, ~p"/decks/#{deck}?sort=type&view=list")

    assert has_element?(
             view,
             "#deck-list-column-1 #deck-type-group-mainboard-Creature",
             "Creature"
           )

    assert has_element?(
             view,
             "#deck-list-column-1 #deck-type-group-mainboard-Creature",
             "2 cards"
           )

    assert has_element?(
             view,
             "#deck-list-column-1 #deck-entry-#{entries_by_name["Solemn Simulacrum"].id}"
           )

    assert has_element?(view, "#deck-list-column-1 #deck-type-group-mainboard-Instant", "Instant")
    assert has_element?(view, "#deck-list-column-1 #deck-entry-#{entries_by_name["Opt"].id}")
    assert has_element?(view, "#deck-list-column-1 #deck-type-group-mainboard-Land", "Land")
    assert has_element?(view, "#deck-list-column-1 #deck-entry-#{entries_by_name["Island"].id}")
  end

  test "card preview hook ignores missing card ids", %{conn: conn, user: user} do
    {deck, entries_by_name} = deck_with_type_entries(user)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}?view=list")

    view
    |> element("#deck-entry-#{entries_by_name["Island"].id}")
    |> render_hook("preview_card", %{})

    assert has_element?(view, "#deck-list-columns")
  end

  test "list view flows sections through shared columns and wraps after fifty card entries", %{
    conn: conn,
    user: user
  } do
    deck = deck_fixture(user, %{format: "standard"})

    mainboard_entries =
      for index <- 1..51 do
        card =
          card_fixture(%{
            name: "Mainboard Card #{index}",
            normalized_name: "mainboard card #{index}",
            type_line: "Creature"
          })

        {:ok, entry} = Decks.add_card(deck, card, %{section: "mainboard"})
        entry
      end

    sideboard_card =
      card_fixture(%{
        name: "Sideboard Card",
        normalized_name: "sideboard card",
        type_line: "Instant"
      })

    {:ok, sideboard_entry} = Decks.add_card(deck, sideboard_card, %{section: "sideboard"})
    first_mainboard_entry = List.first(mainboard_entries)
    fifty_first_mainboard_entry = List.last(mainboard_entries)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}?view=list")

    assert has_element?(view, "#deck-list-column-1 #deck-section-heading-mainboard", "mainboard")
    assert has_element?(view, "#deck-list-column-1 #deck-entry-#{first_mainboard_entry.id}")
    assert has_element?(view, "#deck-list-column-2 #deck-entry-#{fifty_first_mainboard_entry.id}")
    assert has_element?(view, "#deck-list-column-2 #deck-section-heading-sideboard", "sideboard")
    assert has_element?(view, "#deck-list-column-2 #deck-entry-#{sideboard_entry.id}")
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

  defp deck_with_type_entries(user) do
    deck = deck_fixture(user, %{format: "standard"})

    land =
      card_fixture(%{
        name: "Island",
        normalized_name: "island",
        type_line: "Basic Land"
      })

    instant =
      card_fixture(%{
        name: "Opt",
        normalized_name: "opt",
        type_line: "Instant"
      })

    creature =
      card_fixture(%{
        name: "Solemn Simulacrum",
        normalized_name: "solemn simulacrum",
        type_line: "Artifact Creature — Golem"
      })

    artifact =
      card_fixture(%{
        name: "Sol Ring",
        normalized_name: "sol ring",
        type_line: "Artifact"
      })

    {:ok, land_entry} = Decks.add_card(deck, land, %{section: "mainboard"})
    {:ok, instant_entry} = Decks.add_card(deck, instant, %{section: "mainboard"})
    {:ok, creature_entry} = Decks.add_card(deck, creature, %{section: "mainboard", quantity: 2})
    {:ok, artifact_entry} = Decks.add_card(deck, artifact, %{section: "sideboard"})

    entries_by_name = %{
      "Island" => land_entry,
      "Opt" => instant_entry,
      "Solemn Simulacrum" => creature_entry,
      "Sol Ring" => artifact_entry
    }

    {deck, entries_by_name}
  end
end
