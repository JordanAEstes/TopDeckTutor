defmodule TopDeckTutorWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use TopDeckTutorWeb, :html

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/top_deck_tutor_web/controllers/error_html/404.html.heex
  #   * lib/top_deck_tutor_web/controllers/error_html/500.html.heex
  #
  # embed_templates "error_html/*"

  def render("404.html", assigns) do
    ~H"""
    <div class="min-h-screen bg-[var(--bg)] px-4 py-20 text-[var(--text)]">
      <div class="mx-auto flex max-w-xl flex-col items-center text-center">
        <img
          src={~p"/images/text-logo.png"}
          alt="Top Deck Tutor"
          class="h-auto w-64 max-w-full"
        />

        <p class="mt-8 text-sm font-medium uppercase tracking-[0.16em] app-muted">
          404
        </p>

        <h1 class="mt-3 text-3xl font-semibold tracking-tight">
          Page not found
        </h1>

        <p class="mt-3 max-w-md app-muted">
          The page you are looking for does not exist or may have moved.
        </p>

        <.link navigate={~p"/"} class="app-button-primary mt-8">
          Return home
        </.link>
      </div>
    </div>
    """
  end

  # The default is to render a plain text page based on
  # the template name. For example, "500.html" becomes
  # "Internal Server Error".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
