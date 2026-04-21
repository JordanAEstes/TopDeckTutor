defmodule TopDeckTutor.Decks.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decks" do
    field :name, :string
    field :format, :string
    field :description, :string
    field :visibility, :string, default: "private"

    belongs_to :user, TopDeckTutor.Accounts.User
    has_many :deck_entries, TopDeckTutor.Decks.DeckEntry

    timestamps()
  end

  @fields [:name, :format, :description, :visibility]

  def changeset(deck, attrs) do
    deck
    |> cast(attrs, @fields)
    |> validate_required([:name, :format, :visibility, :user_id])
    |> validate_inclusion(:visibility, ["private", "unlisted", "public"])
    |> assoc_constraint(:user)
  end
end
