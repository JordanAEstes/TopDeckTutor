defmodule TopDeckTutor.Repo.Migrations.AddCardNamePrefixIndex do
  use Ecto.Migration

  def change do
    create index(:cards, ["normalized_name text_pattern_ops"],
             name: :cards_normalized_name_prefix_index
           )
  end
end
