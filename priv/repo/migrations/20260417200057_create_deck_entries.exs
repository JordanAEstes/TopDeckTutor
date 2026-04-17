defmodule TopDeckTutor.Repo.Migrations.CreateDeckEntries do
  use Ecto.Migration

  def change do
    create table(:deck_entries) do
      add :deck_id, references(:decks, on_delete: :delete_all), null: false
      add :card_id, references(:cards, type: :binary_id, on_delete: :nothing), null: false
      add :quantity, :integer, null: false, default: 1
      add :section, :string, null: false, default: "mainboard"

      timestamps()
    end

    create index(:deck_entries, [:deck_id])
    create index(:deck_entries, [:card_id])
    create index(:deck_entries, [:deck_id, :section])

    create unique_index(:deck_entries, [:deck_id, :card_id, :section],
             name: :deck_entries_unique_card_per_section
           )
  end
end
