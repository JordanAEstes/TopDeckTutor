defmodule TopDeckTutorWeb.UserLive.Confirmation do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="mx-auto max-w-md px-4 py-12">
        <div class="space-y-6">
          <div class="space-y-2 text-center">
            <p class="text-sm font-medium uppercase tracking-[0.16em] app-muted">
              Account confirmation
            </p>

            <h1 class="text-3xl font-semibold tracking-tight">
              Welcome {@user.email}
            </h1>

            <p class="text-sm app-muted">
              <%= if !@user.confirmed_at do %>
                Confirm your account to finish signing in.
              <% else %>
                Your account is already confirmed. Continue to log in.
              <% end %>
            </p>
          </div>

          <div class="app-panel p-6 sm:p-8">
            <.form
              :if={!@user.confirmed_at}
              for={@form}
              id="confirmation_form"
              phx-mounted={JS.focus_first()}
              phx-submit="submit"
              action={~p"/users/log-in?_action=confirmed"}
              phx-trigger-action={@trigger_submit}
              class="space-y-3"
            >
              <input type="hidden" name={@form[:token].name} value={@form[:token].value} />

              <.button
                name={@form[:remember_me].name}
                value="true"
                phx-disable-with="Confirming..."
                class="app-button-primary w-full"
              >
                Confirm and stay logged in
              </.button>

              <.button
                phx-disable-with="Confirming..."
                class="app-button-secondary mt-2 w-full"
              >
                Confirm and log in only this time
              </.button>
            </.form>

            <.form
              :if={@user.confirmed_at}
              for={@form}
              id="login_form"
              phx-submit="submit"
              phx-mounted={JS.focus_first()}
              action={~p"/users/log-in"}
              phx-trigger-action={@trigger_submit}
              class="space-y-3"
            >
              <input type="hidden" name={@form[:token].name} value={@form[:token].value} />

              <%= if @current_scope do %>
                <.button phx-disable-with="Logging in..." class="app-button-primary w-full">
                  Log in
                </.button>
              <% else %>
                <.button
                  name={@form[:remember_me].name}
                  value="true"
                  phx-disable-with="Logging in..."
                  class="app-button-primary w-full"
                >
                  Keep me logged in on this device
                </.button>

                <.button
                  phx-disable-with="Logging in..."
                  class="app-button-secondary mt-2 w-full"
                >
                  Log me in only this time
                </.button>
              <% end %>
            </.form>

            <%= if !@user.confirmed_at do %>
              <div class="mt-6 rounded-xl border border-[var(--border)] bg-[var(--surface-muted)] p-4 text-sm app-muted">
                <span class="font-medium text-[var(--text)]">Tip:</span>
                If you prefer passwords, you can enable them in user settings later.
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
