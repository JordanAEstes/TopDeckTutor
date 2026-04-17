defmodule TopDeckTutor.DecksFixtures do
  alias TopDeckTutor.Decks
  alias TopDeckTutor.AccountsFixtures

  def deck_fixture(user \\ nil, attrs \\ %{})

  def deck_fixture(nil, attrs) do
    user = AccountsFixtures.user_fixture()
    deck_fixture(user, attrs)
  end

  def deck_fixture(user, attrs) do
    attrs =
      Enum.into(attrs, %{
        name: "Deck #{System.unique_integer([:positive])}",
        format: "commander",
        visibility: "private"
      })

    {:ok, deck} = Decks.create_deck(user, attrs)
    deck
  end
end
