defmodule TopDeckTutorWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use TopDeckTutorWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true
  attr :current_scope, :any, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-white text-zinc-900">
      <header class="sticky top-0 z-40 border-b bg-white/90 backdrop-blur">
        <div class="mx-auto flex max-w-6xl items-center justify-between px-4 py-4">
          <div class="flex items-center gap-6">
            <.link navigate={~p"/"} class="text-lg font-semibold tracking-tight">
              TopDeckTutor
            </.link>

            <nav class="hidden md:flex items-center gap-4 text-sm">
              <.link navigate={~p"/search"} class="hover:text-zinc-900 hover:underline">
                Global Search
              </.link>

              <%= if @current_scope do %>
                <.link navigate={~p"/decks"} class="hover:text-zinc-900 hover:underline">
                  My Decks
                </.link>
              <% end %>
            </nav>
          </div>

          <div class="flex items-center gap-3 text-sm">
            <%= if @current_scope do %>
              <span class="hidden sm:inline text-zinc-500">
                {@current_scope.user.email}
              </span>

              <.link
                navigate={~p"/users/settings"}
                class="hover:text-zinc-900 hover:underline"
              >
                Settings
              </.link>

              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="rounded-md border px-3 py-2 font-medium transition hover:bg-zinc-50"
              >
                Log out
              </.link>
            <% else %>
              <.link
                navigate={~p"/users/register"}
                class="hover:text-zinc-900 hover:underline"
              >
                Register
              </.link>

              <.link
                navigate={~p"/users/log-in"}
                class="rounded-md bg-zinc-900 px-3 py-2 font-medium text-white transition hover:bg-zinc-700"
              >
                Log in
              </.link>
            <% end %>
          </div>
        </div>
      </header>

      <main class="flex-1">
        {render_slot(@inner_block)}
      </main>

      <footer class="border-t bg-zinc-50">
        <div class="mx-auto max-w-6xl px-4 py-4 text-sm text-zinc-500">
          TopDeckTutor
        </div>
      </footer>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
