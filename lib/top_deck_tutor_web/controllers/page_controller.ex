defmodule TopDeckTutorWeb.PageController do
  use TopDeckTutorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(html: TopDeckTutorWeb.ErrorHTML)
    |> render(:"404")
  end
end
