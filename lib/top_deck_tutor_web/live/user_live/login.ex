defmodule TopDeckTutorWeb.UserLive.Login do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md px-4 py-12">
        <div class="space-y-6">
          <div class="space-y-2 text-center">
            <p class="text-sm font-medium uppercase tracking-[0.16em] app-muted">
              Welcome back
            </p>

            <h1 class="text-3xl font-semibold tracking-tight">
              Log in
            </h1>

            <p class="text-sm app-muted">
              <%= if @current_scope do %>
                Reauthenticate to continue with this sensitive action.
              <% else %>
                Sign in to manage decks and search your cards.
              <% end %>
            </p>
          </div>

          <div :if={local_mail_adapter?()} class="app-panel p-4">
            <div class="flex items-start gap-3">
              <.icon name="hero-information-circle" class="mt-0.5 size-5 shrink-0 app-muted" />
              <div class="space-y-1 text-sm">
                <p class="font-medium">Local mail adapter enabled</p>
                <p class="app-muted">
                  To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
                </p>
              </div>
            </div>
          </div>

          <div class="app-panel p-6 sm:p-8">
            <div class="space-y-6">
              <div class="space-y-3">
                <div>
                  <h2 class="text-lg font-medium">Magic link</h2>
                  <p class="text-sm app-muted">
                    Get a one-time login link by email.
                  </p>
                </div>

                <.form
                  :let={f}
                  for={@form}
                  id="login_form_magic"
                  action={~p"/users/log-in"}
                  phx-submit="submit_magic"
                  class="space-y-4"
                >
                  <.input
                    readonly={!!@current_scope}
                    field={f[:email]}
                    type="email"
                    label="Email"
                    autocomplete="username"
                    spellcheck="false"
                    required
                    phx-mounted={JS.focus()}
                    class="app-input"
                  />

                  <.button class="app-button-primary w-full">
                    Log in with email
                  </.button>
                </.form>
              </div>

              <div class="flex items-center gap-3">
                <div class="h-px flex-1 bg-[var(--border)]"></div>
                <span class="text-xs font-medium uppercase tracking-[0.16em] app-muted">or</span>
                <div class="h-px flex-1 bg-[var(--border)]"></div>
              </div>

              <div class="space-y-3">
                <div>
                  <h2 class="text-lg font-medium">Password</h2>
                  <p class="text-sm app-muted">
                    Use your email and password to sign in.
                  </p>
                </div>

                <.form
                  :let={f}
                  for={@form}
                  id="login_form_password"
                  action={~p"/users/log-in"}
                  phx-submit="submit_password"
                  phx-trigger-action={@trigger_submit}
                  class="space-y-4"
                >
                  <.input
                    readonly={!!@current_scope}
                    field={f[:email]}
                    type="email"
                    label="Email"
                    autocomplete="username"
                    spellcheck="false"
                    required
                    class="app-input"
                  />

                  <.input
                    field={@form[:password]}
                    type="password"
                    label="Password"
                    autocomplete="current-password"
                    spellcheck="false"
                    class="app-input"
                  />

                  <div class="space-y-3">
                    <.button
                      class="app-button-primary w-full"
                      name={@form[:remember_me].name}
                      value="true"
                    >
                      Log in and stay logged in
                    </.button>

                    <.button class="app-button-secondary mt-2 w-full">
                      Log in only this time
                    </.button>
                  </div>
                </.form>
              </div>
            </div>

            <%= if !@current_scope do %>
              <div class="mt-6 border-t pt-4 text-center text-sm">
                <span class="app-muted">Don’t have an account?</span>
                <.link
                  navigate={~p"/users/register"}
                  class="ml-1 font-medium app-muted hover:underline"
                >
                  Sign up
                </.link>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:top_deck_tutor, TopDeckTutor.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
