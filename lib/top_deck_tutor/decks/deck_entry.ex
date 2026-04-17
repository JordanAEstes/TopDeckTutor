defmodule TopDeckTutor.Decks.DeckEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "deck_entries" do
    field :quantity, :integer, default: 1
    field :section, :string, default: "mainboard"

    belongs_to :deck, TopDeckTutor.Decks.Deck
    belongs_to :card, TopDeckTutor.Cards.Card, type: :binary_id

    timestamps()
  end

  @fields [:deck_id, :card_id, :quantity, :section]

  def changeset(deck_entry, attrs) do
    deck_entry
    |> cast(attrs, @fields)
    |> validate_required([:deck_id, :card_id, :quantity, :section])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_inclusion(:section, ["mainboard", "sideboard", "maybeboard", "command"])
    |> assoc_constraint(:deck)
    |> assoc_constraint(:card)
    |> unique_constraint([:deck_id, :card_id, :section],
      name: :deck_entries_unique_card_per_section
    )
  end
end
