defmodule TopDeckTutorWeb.UserLive.Registration do
  use TopDeckTutorWeb, :live_view

  alias TopDeckTutor.Accounts
  alias TopDeckTutor.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md px-4 py-12">
        <div class="space-y-6">
          <div class="space-y-2 text-center">
            <img
              src={~p"/images/TDT-logo.png"}
              alt="Top Deck Tutor"
              class="mx-auto size-24"
            />

            <p class="text-sm font-medium uppercase tracking-[0.16em] app-muted">
              New account
            </p>

            <h1 class="text-3xl font-semibold tracking-tight">
              Create your account
            </h1>

            <p class="text-sm app-muted">
              Build decks, search cards, and organize your collection.
            </p>
          </div>

          <div class="app-panel p-6 sm:p-8">
            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              class="space-y-5"
            >
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
                phx-mounted={JS.focus()}
                class="app-input"
              />

              <.button phx-disable-with="Creating account..." class="app-button-primary w-full">
                Create account
              </.button>
            </.form>

            <div class="mt-5 border-t pt-4 text-center text-sm">
              <span class="app-muted">Already registered?</span>
              <.link navigate={~p"/users/log-in"} class="ml-1 font-medium app-muted hover:underline">
                Log in
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: TopDeckTutorWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
