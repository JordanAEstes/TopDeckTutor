defmodule TopDeckTutorWeb.SearchAdvancedLiveTest do
  use TopDeckTutorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  test "renders successfully for signed-out users", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/search/advanced")

    assert html =~ "Advanced Search"
    assert html =~ "advanced-search-form"
    refute html =~ "Search scope"
  end

  describe "signed-in scope controls" do
    setup :register_and_log_in_user

    test "signed-in users see scope controls and can reveal the deck picker", %{
      conn: conn,
      user: user
    } do
      deck = deck_fixture(user, %{name: "Azorius Control"})
      {:ok, view, _html} = live(conn, ~p"/search/advanced")

      assert has_element?(view, "#advanced-search-scope")
      refute has_element?(view, "#advanced-search-deck-ids")

      view
      |> element("#advanced-search-form")
      |> render_change(%{
        "advanced_search" => %{
          "scope" => "selected_decks",
          "deck_ids" => [Integer.to_string(deck.id)]
        }
      })

      assert has_element?(view, "#advanced-search-deck-ids")
    end

    test "submitting selected deck scope takes us to the main search page with scope params", %{
      conn: conn,
      user: user
    } do
      deck = deck_fixture(user, %{name: "Azorius Control"})
      {:ok, view, _html} = live(conn, ~p"/search/advanced")

      view
      |> element("#advanced-search-form")
      |> render_change(%{
        "advanced_search" => %{
          "name" => "Sol Ring",
          "scope" => "selected_decks",
          "deck_ids" => [Integer.to_string(deck.id)]
        }
      })

      view
      |> form("#advanced-search-form", %{
        "advanced_search" => %{
          "name" => "Sol Ring",
          "scope" => "selected_decks",
          "deck_ids" => [Integer.to_string(deck.id)]
        }
      })
      |> render_submit()

      assert_redirected(
        view,
        ~p"/search?#{[q: ~s(name:"Sol Ring"), scope: "selected_decks", deck_ids: [Integer.to_string(deck.id)]]}"
      )
    end
  end

  test "submitting a name search takes us to the main search page", %{conn: conn} do
    _matching = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})
    _other = card_fixture(%{name: "Arcane Signet", normalized_name: "arcane signet"})

    {:ok, view, _html} = live(conn, ~p"/search/advanced")

    view
    |> form("#advanced-search-form", %{"advanced_search" => %{"name" => "Sol Ring"}})
    |> render_submit()

    assert_redirected(view, ~p"/search?#{[q: ~s(name:"Sol Ring")]}")
  end

  test "reset clears the form, URL params, and results", %{conn: conn} do
    _matching = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})

    {:ok, view, _html} = live(conn, ~p"/search/advanced")

    view
    |> form("#advanced-search-form", %{"advanced_search" => %{"name" => "Sol Ring"}})
    |> render_submit()

    assert_redirected(view, ~p"/search?#{[q: ~s(name:"Sol Ring")]}")

    {:ok, view, _html} = live(conn, ~p"/search/advanced?#{[name: "Sol Ring"]}")

    view
    |> element("#advanced-search-reset")
    |> render_click()

    assert_patch(view, ~p"/search/advanced")
    assert has_element?(view, "#advanced-search-empty")
    refute render(view) =~ "Sol Ring"
  end

  test "submitting multiple filters redirects to the main search query", %{conn: conn} do
    _matching =
      card_fixture(%{
        name: "Serra Angel",
        normalized_name: "serra angel",
        rarity: "rare",
        type_line: "Creature — Angel"
      })

    {:ok, view, _html} = live(conn, ~p"/search/advanced")

    view
    |> form("#advanced-search-form", %{
      "advanced_search" => %{"name" => "Serra", "rarity" => "rare"}
    })
    |> render_submit()

    assert_redirected(view, ~p"/search?#{[q: "name:Serra rarity:rare"]}")
  end

  test "shows validation errors for invalid integer fields", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/search/advanced")

    html =
      view
      |> element("#advanced-search-form")
      |> render_change(%{
        "advanced_search" => %{"mana_value" => "two", "power" => "x"}
      })

    assert html =~ "must be a whole number"
  end
end
