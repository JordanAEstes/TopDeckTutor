defmodule TopDeckTutor.Repo.Migrations.CreateDecks do
  use Ecto.Migration

  def change do
    create table(:decks) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :format, :string, null: false
      add :description, :text
      add :visibility, :string, null: false, default: "private"

      timestamps()
    end

    create index(:decks, [:user_id])
    create index(:decks, [:format])
    create index(:decks, [:visibility])
  end
end
