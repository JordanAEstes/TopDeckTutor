defmodule TopDeckTutorWeb.SyntaxGuideLive do
  use TopDeckTutorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Syntax Guide")}
  end
end
