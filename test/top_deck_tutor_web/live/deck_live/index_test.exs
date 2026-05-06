defmodule TopDeckTutorWeb.DeckLive.IndexTest do
  use TopDeckTutorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  alias TopDeckTutor.Decks

  setup :register_and_log_in_user

  test "shows commander search only when commander format is selected", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/decks/new")

    refute has_element?(view, "#deck-commander-picker")

    view
    |> element("#deck-form")
    |> render_change(%{"deck" => %{"name" => "Esper", "format" => "commander"}})

    assert has_element?(view, "#deck-commander-picker")
  end

  test "searches legendary creatures by name after three characters", %{conn: conn} do
    commander =
      card_fixture(%{
        name: "Alela, Artful Provocateur",
        normalized_name: "alela artful provocateur",
        type_line: "Legendary Creature — Faerie Warlock",
        is_legendary: true,
        is_creature: true
      })

    _nonlegendary =
      card_fixture(%{
        name: "Alela's Vanguard",
        normalized_name: "alelas vanguard",
        type_line: "Creature — Faerie Knight",
        is_legendary: false,
        is_creature: true
      })

    {:ok, view, _html} = live(conn, ~p"/decks/new")

    view
    |> element("#deck-form")
    |> render_change(%{"deck" => %{"name" => "Esper", "format" => "commander"}})

    view
    |> element("#deck-commander-search")
    |> render_keyup(%{"value" => "Al"})

    refute has_element?(view, "#deck-commander-option-#{commander.id}")

    view
    |> element("#deck-commander-search")
    |> render_keyup(%{"value" => "Ale"})

    assert has_element?(view, "#deck-commander-option-#{commander.id}", commander.name)
    refute render(view) =~ "Alela's Vanguard"
    refute render(view) =~ "Legendary Creature"
  end

  test "creates a command entry for the selected commander", %{conn: conn, user: user} do
    commander =
      card_fixture(%{
        name: "Alela, Artful Provocateur",
        normalized_name: "alela artful provocateur",
        type_line: "Legendary Creature — Faerie Warlock",
        is_legendary: true,
        is_creature: true
      })

    {:ok, view, _html} = live(conn, ~p"/decks/new")

    view
    |> element("#deck-form")
    |> render_change(%{"deck" => %{"name" => "Esper", "format" => "commander"}})

    view
    |> element("#deck-commander-search")
    |> render_keyup(%{"value" => "Ale"})

    view
    |> element("#deck-commander-option-#{commander.id}")
    |> render_click()

    view
    |> form("#deck-form", %{
      "deck" => %{"name" => "Esper", "format" => "commander", "visibility" => "private"}
    })
    |> render_submit()

    [deck] = Decks.list_decks_for_user(user)

    assert [%{card_id: commander_id, section: "command", quantity: 1}] =
             Enum.filter(Decks.list_entries(deck), &(&1.section == "command"))

    assert commander_id == commander.id
  end

  test "edit form shows and replaces the selected commander", %{conn: conn, user: user} do
    deck = deck_fixture(user, %{format: "commander"})

    first =
      card_fixture(%{
        name: "Alela, Artful Provocateur",
        normalized_name: "alela artful provocateur",
        type_line: "Legendary Creature — Faerie Warlock",
        is_legendary: true,
        is_creature: true
      })

    second =
      card_fixture(%{
        name: "Muldrotha, the Gravetide",
        normalized_name: "muldrotha the gravetide",
        type_line: "Legendary Creature — Elemental Avatar",
        is_legendary: true,
        is_creature: true
      })

    assert {:ok, _entry} = Decks.set_commander(deck, first)

    {:ok, view, _html} = live(conn, ~p"/decks/#{deck}/edit")

    assert has_element?(view, "#deck-commander-picker")
    assert has_element?(view, "#deck-selected-commander", first.name)

    view
    |> element("#deck-commander-search")
    |> render_keyup(%{"value" => "Mul"})

    view
    |> element("#deck-commander-option-#{second.id}")
    |> render_click()

    view
    |> form("#deck-form", %{
      "deck" => %{"name" => deck.name, "format" => "commander", "visibility" => "private"}
    })
    |> render_submit()

    command_entries =
      deck
      |> Decks.list_entries()
      |> Enum.filter(&(&1.section == "command"))

    assert Enum.map(command_entries, & &1.card_id) == [second.id]
  end
end
