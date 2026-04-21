defmodule TopDeckTutor.Cards do
  import Ecto.Query, warn: false

  alias TopDeckTutor.Repo
  alias TopDeckTutor.Cards.Card

  def list_cards do
    Repo.all(Card)
  end

  def get_card!(id), do: Repo.get!(Card, id)

  def get_card_by_oracle_id(oracle_id) do
    Repo.get_by(Card, oracle_id: oracle_id)
  end

  def get_card_by_name(name) do
    normalized_name = normalize_name(name)

    Repo.get_by(Card, normalized_name: normalized_name)
  end

  def search_cards(term) when is_binary(term) do
    normalized_term = normalize_name(term)

    Card
    |> where(
      [c],
      ilike(c.name, ^"%#{term}%") or
        ilike(c.normalized_name, ^"%#{normalized_term}%") or
        ilike(c.oracle_text, ^"%#{term}%") or
        ilike(c.type_line, ^"%#{term}%")
    )
    |> order_by([c], asc: c.name)
    |> limit(50)
    |> Repo.all()
  end

  def search_scope do
    from c in Card,
      order_by: [asc: c.name]
  end

  def search_ast(ast) when is_list(ast) do
    ast
    |> TopDeckTutor.Search.Compiler.compile(search_scope())
    |> limit(100)
    |> Repo.all()
  end

  def search_query(query_string) when is_binary(query_string) do
    with {:ok, ast} <- TopDeckTutor.Search.parse(query_string) do
      {:ok, search_ast(ast)}
    end
  end

  def create_card(attrs \\ %{}) do
    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert()
  end

  def update_card(%Card{} = card, attrs) do
    card
    |> Card.changeset(attrs)
    |> Repo.update()
  end

  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  def change_card(%Card{} = card, attrs \\ %{}) do
    Card.changeset(card, attrs)
  end

  def upsert_card(attrs) do
    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :id,
      returning: true
    )
  end

  defp normalize_name(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/u, "")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end
end
