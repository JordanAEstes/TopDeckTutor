defmodule TopDeckTutor.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "cards" do
    field :oracle_id, Ecto.UUID

    field :name, :string
    field :normalized_name, :string
    field :lang, :string

    field :mana_cost, :string
    field :mana_value, :decimal
    field :type_line, :string
    field :oracle_text, :string

    field :colors, {:array, :string}, default: []
    field :color_identity, {:array, :string}, default: []
    field :keywords, {:array, :string}, default: []
    field :produced_mana, {:array, :string}, default: []

    field :power, :string
    field :toughness, :string
    field :loyalty, :string

    field :layout, :string
    field :released_at, :date

    field :set_code, :string
    field :set_name, :string
    field :set_type, :string
    field :collector_number, :string
    field :rarity, :string

    field :legalities, :map, default: %{}
    field :games, {:array, :string}, default: []
    field :finishes, {:array, :string}, default: []

    field :reserved, :boolean, default: false
    field :game_changer, :boolean, default: false
    field :digital, :boolean, default: false
    field :foil, :boolean, default: false
    field :nonfoil, :boolean, default: false
    field :oversized, :boolean, default: false
    field :promo, :boolean, default: false
    field :reprint, :boolean, default: false
    field :variation, :boolean, default: false
    field :full_art, :boolean, default: false
    field :textless, :boolean, default: false
    field :booster, :boolean, default: false
    field :story_spotlight, :boolean, default: false

    field :is_creature, :boolean, default: false
    field :is_land, :boolean, default: false
    field :is_instant, :boolean, default: false
    field :is_sorcery, :boolean, default: false
    field :is_artifact, :boolean, default: false
    field :is_enchantment, :boolean, default: false
    field :is_planeswalker, :boolean, default: false
    field :is_legendary, :boolean, default: false

    field :image_uris, :map, default: %{}
    field :artist, :string
    field :border_color, :string
    field :frame, :string

    field :edhrec_rank, :integer
    field :penny_rank, :integer

    field :raw, :map, default: %{}

    has_many :deck_entries, TopDeckTutor.Decks.DeckEntry

    timestamps()
  end

  @fields [
    :id,
    :oracle_id,
    :name,
    :normalized_name,
    :lang,
    :mana_cost,
    :mana_value,
    :type_line,
    :oracle_text,
    :colors,
    :color_identity,
    :keywords,
    :produced_mana,
    :power,
    :toughness,
    :loyalty,
    :layout,
    :released_at,
    :set_code,
    :set_name,
    :set_type,
    :collector_number,
    :rarity,
    :legalities,
    :games,
    :finishes,
    :reserved,
    :game_changer,
    :digital,
    :foil,
    :nonfoil,
    :oversized,
    :promo,
    :reprint,
    :variation,
    :full_art,
    :textless,
    :booster,
    :story_spotlight,
    :is_creature,
    :is_land,
    :is_instant,
    :is_sorcery,
    :is_artifact,
    :is_enchantment,
    :is_planeswalker,
    :is_legendary,
    :image_uris,
    :artist,
    :border_color,
    :frame,
    :edhrec_rank,
    :penny_rank,
    :raw
  ]

  def changeset(card, attrs) do
    card
    |> cast(attrs, @fields)
    |> validate_required([:id, :oracle_id, :name, :normalized_name, :mana_value])
    |> unique_constraint(:id)
    |> unique_constraint(:oracle_id,
      name: :cards_oracle_set_collector_lang_index,
      message: "card print already exists"
    )
  end
end
