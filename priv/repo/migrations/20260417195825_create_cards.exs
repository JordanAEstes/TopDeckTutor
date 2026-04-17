defmodule TopDeckTutor.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :oracle_id, :binary_id, null: false

      add :name, :string, null: false
      add :normalized_name, :string, null: false
      add :lang, :string, null: false, default: "en"

      add :mana_cost, :string
      add :mana_value, :decimal, null: false, default: 0
      add :type_line, :string
      add :oracle_text, :text

      add :colors, {:array, :string}, null: false, default: []
      add :color_identity, {:array, :string}, null: false, default: []
      add :keywords, {:array, :string}, null: false, default: []
      add :produced_mana, {:array, :string}, null: false, default: []

      add :power, :string
      add :toughness, :string
      add :loyalty, :string

      add :layout, :string
      add :released_at, :date

      add :set_code, :string
      add :set_name, :string
      add :set_type, :string
      add :collector_number, :string
      add :rarity, :string

      add :legalities, :map, null: false, default: %{}
      add :games, {:array, :string}, null: false, default: []
      add :finishes, {:array, :string}, null: false, default: []

      add :reserved, :boolean, null: false, default: false
      add :game_changer, :boolean, null: false, default: false
      add :digital, :boolean, null: false, default: false
      add :foil, :boolean, null: false, default: false
      add :nonfoil, :boolean, null: false, default: false
      add :oversized, :boolean, null: false, default: false
      add :promo, :boolean, null: false, default: false
      add :reprint, :boolean, null: false, default: false
      add :variation, :boolean, null: false, default: false
      add :full_art, :boolean, null: false, default: false
      add :textless, :boolean, null: false, default: false
      add :booster, :boolean, null: false, default: false
      add :story_spotlight, :boolean, null: false, default: false

      add :is_creature, :boolean, null: false, default: false
      add :is_land, :boolean, null: false, default: false
      add :is_instant, :boolean, null: false, default: false
      add :is_sorcery, :boolean, null: false, default: false
      add :is_artifact, :boolean, null: false, default: false
      add :is_enchantment, :boolean, null: false, default: false
      add :is_planeswalker, :boolean, null: false, default: false
      add :is_legendary, :boolean, null: false, default: false

      add :image_uris, :map, null: false, default: %{}
      add :artist, :string
      add :border_color, :string
      add :frame, :string

      add :edhrec_rank, :integer
      add :penny_rank, :integer

      add :raw, :map, null: false, default: %{}

      timestamps()
    end

    create index(:cards, [:oracle_id])
    create index(:cards, [:normalized_name])
    create index(:cards, [:set_code])
    create index(:cards, [:released_at])
    create index(:cards, [:mana_value])
    create index(:cards, [:layout])
    create index(:cards, [:rarity])

    create unique_index(:cards, [:oracle_id, :set_code, :collector_number, :lang],
             name: :cards_oracle_set_collector_lang_index
           )
  end
end
