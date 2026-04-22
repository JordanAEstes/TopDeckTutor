defmodule TopDeckTutorWeb.ErrorHTMLTest do
  use TopDeckTutorWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    html = render_to_string(TopDeckTutorWeb.ErrorHTML, "404", "html", [])

    assert html =~ ~s(src="/images/text-logo.png")
    assert html =~ "Page not found"
  end

  test "renders 500.html" do
    assert render_to_string(TopDeckTutorWeb.ErrorHTML, "500", "html", []) ==
             "Internal Server Error"
  end
end
