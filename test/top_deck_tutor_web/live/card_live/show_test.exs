defmodule TopDeckTutorWeb.CardLive.ShowTest do
  use TopDeckTutorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TopDeckTutor.CardsFixtures

  test "renders mana symbols with Mana classes", %{conn: conn} do
    card =
      card_fixture(%{
        name: "Mana Test Card",
        normalized_name: "mana test card",
        mana_cost: "{4}{W}",
        oracle_text: "{T}: Draw a card.",
        type_line: "Artifact",
        image_uris: %{}
      })

    {:ok, _view, html} = live(conn, ~p"/cards/#{card}")

    assert html =~ "ms-4"
    assert html =~ "ms-w"
    refute html =~ "{4}{W}"
  end

  test "renders other printings above search shortcuts with the current printing highlighted", %{
    conn: conn
  } do
    oracle_id = Ecto.UUID.generate()

    current =
      card_fixture(%{
        oracle_id: oracle_id,
        name: "Lightning Bolt",
        normalized_name: "lightning bolt",
        set_name: "Limited Edition Alpha",
        set_code: "lea",
        collector_number: "161",
        released_at: ~D[1993-08-05],
        rarity: "common"
      })

    other_printing =
      card_fixture(%{
        oracle_id: oracle_id,
        name: "Lightning Bolt",
        normalized_name: "lightning bolt",
        set_name: "Magic 2011",
        set_code: "m11",
        collector_number: "146",
        released_at: ~D[2010-07-16],
        rarity: "common"
      })

    {:ok, view, _html} = live(conn, ~p"/cards/#{current}")

    assert has_element?(view, "#other-printings-card", "Other printings")

    assert has_element?(
             view,
             ~s(#other-printings-see-all[href="/search?q=oracle%3A#{oracle_id}&view=images"]),
             "See all"
           )

    assert has_element?(view, "#other-printings-card + #search-shortcuts-card")
    assert has_element?(view, "#printing-#{current.id}[aria-current='page']")
    assert has_element?(view, "#printing-#{current.id}", "Limited Edition Alpha")
    assert has_element?(view, "#printing-#{current.id}", "#161")
    assert has_element?(view, "#printing-#{other_printing.id}", "Magic 2011")
    assert has_element?(view, "#printing-#{other_printing.id}", "#146")
  end

  test "clicking another printing patches to that printing's card page", %{conn: conn} do
    oracle_id = Ecto.UUID.generate()

    current =
      card_fixture(%{
        oracle_id: oracle_id,
        name: "Lightning Bolt",
        normalized_name: "lightning bolt",
        set_name: "Limited Edition Alpha",
        set_code: "lea",
        collector_number: "161",
        released_at: ~D[1993-08-05]
      })

    other_printing =
      card_fixture(%{
        oracle_id: oracle_id,
        name: "Lightning Bolt",
        normalized_name: "lightning bolt",
        set_name: "Magic 2011",
        set_code: "m11",
        collector_number: "146",
        released_at: ~D[2010-07-16]
      })

    {:ok, view, _html} = live(conn, ~p"/cards/#{current}")

    view
    |> element("#printing-#{other_printing.id}")
    |> render_click()

    assert_patch(view, ~p"/cards/#{other_printing}")
    assert has_element?(view, "#printing-#{other_printing.id}[aria-current='page']")
  end
end
