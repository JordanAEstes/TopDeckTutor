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
end
