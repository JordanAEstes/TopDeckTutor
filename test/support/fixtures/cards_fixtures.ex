defmodule TopDeckTutor.CardsFixtures do
  alias TopDeckTutor.Cards

  def unique_card_name, do: "Card #{System.unique_integer([:positive])}"

  def card_fixture(attrs \\ %{}) do
    name = Map.get(attrs, :name) || Map.get(attrs, "name") || unique_card_name()

    attrs =
      Enum.into(attrs, %{
        id: Ecto.UUID.generate(),
        oracle_id: Ecto.UUID.generate(),
        name: name,
        normalized_name: normalize_name(name),
        mana_value: Decimal.new("0")
      })

    {:ok, card} = Cards.create_card(attrs)
    card
  end

  defp normalize_name(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/u, "")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end
end
