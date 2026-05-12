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
