defmodule TopDeckTutor.Repo do
  use Ecto.Repo,
    otp_app: :top_deck_tutor,
    adapter: Ecto.Adapters.Postgres
end
