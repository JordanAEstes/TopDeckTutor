defmodule TopDeckTutorWeb.SearchLiveTest do
  use TopDeckTutorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TopDeckTutor.CardsFixtures
  import TopDeckTutor.DecksFixtures

  test "renders advanced-submitted results on the main search page", %{conn: conn} do
    matching = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})
    _other = card_fixture(%{name: "Arcane Signet", normalized_name: "arcane signet"})

    {:ok, view, _html} = live(conn, ~p"/search?#{[q: ~s(name:"Sol Ring")]}")

    assert has_element?(view, "#search-result-#{matching.id}")

    assert has_element?(
             view,
             ~s(#global-search-form input[name="search[q]"][value="name:\\"Sol Ring\\""])
           )
  end

  test "filters global search results with the game selector and keeps it in the URL", %{
    conn: conn
  } do
    paper_match =
      card_fixture(%{
        name: "Paper Search Match",
        normalized_name: "paper search match",
        games: ["paper", "mtgo"]
      })

    arena_match =
      card_fixture(%{
        name: "Arena Search Match",
        normalized_name: "arena search match",
        games: ["arena"]
      })

    {:ok, view, _html} = live(conn, ~p"/search?#{[q: "search match"]}")

    assert has_element?(view, "#search-result-#{paper_match.id}")
    assert has_element?(view, "#search-result-#{arena_match.id}")

    view
    |> element("#global-search-game-filter [phx-value-game=\"paper\"]")
    |> render_click()

    assert_patch(view, ~p"/search?#{[q: "search match", game: "paper"]}")
    assert has_element?(view, "#search-result-#{paper_match.id}")
    refute has_element?(view, "#search-result-#{arena_match.id}")
  end

  test "submitting the search form preserves the selected game filter", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/search?#{[game: "arena"]}")

    view
    |> form("#global-search-form", %{"search" => %{"q" => "ward"}})
    |> render_submit()

    assert_patch(view, ~p"/search?#{[q: "ward", game: "arena"]}")
  end

  test "oracle id searches can show all printings in image view", %{conn: conn} do
    oracle_id = Ecto.UUID.generate()

    first_printing =
      card_fixture(%{
        oracle_id: oracle_id,
        name: "Lightning Bolt",
        normalized_name: "lightning bolt",
        set_code: "lea",
        collector_number: "161",
        image_uris: %{"normal" => "https://example.com/lea.jpg"}
      })

    second_printing =
      card_fixture(%{
        oracle_id: oracle_id,
        name: "Lightning Bolt",
        normalized_name: "lightning bolt",
        set_code: "m11",
        collector_number: "146",
        image_uris: %{"normal" => "https://example.com/m11.jpg"}
      })

    _different_card = card_fixture(%{name: "Shock", normalized_name: "shock"})

    {:ok, view, _html} = live(conn, ~p"/search?#{[q: "oracle:#{oracle_id}", view: "images"]}")

    assert has_element?(view, "#search-result-#{first_printing.id} img")
    assert has_element?(view, "#search-result-#{second_printing.id} img")
    assert has_element?(view, "[phx-value-mode='images'].bg-\\[var\\(--brand\\)\\]")
  end

  describe "selected deck scope" do
    setup :register_and_log_in_user

    test "limits main search results to the selected deck ids", %{conn: conn, user: user} do
      selected_deck = deck_fixture(user, %{name: "Deck One"})
      other_deck = deck_fixture(user, %{name: "Deck Two"})

      matching = card_fixture(%{name: "Sol Ring", normalized_name: "sol ring"})
      excluded = card_fixture(%{name: "Soul Ring", normalized_name: "soul ring"})

      assert {:ok, _} = TopDeckTutor.Decks.add_card(selected_deck, matching)
      assert {:ok, _} = TopDeckTutor.Decks.add_card(other_deck, excluded)

      {:ok, view, _html} =
        live(
          conn,
          ~p"/search?#{[q: "ring", scope: "selected_decks", deck_ids: [Integer.to_string(selected_deck.id)]]}"
        )

      assert has_element?(view, "#search-result-#{matching.id}")
      refute render(view) =~ "Soul Ring"
    end
  end
end
