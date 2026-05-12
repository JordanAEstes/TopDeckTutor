defmodule TopDeckTutor.Repo.Migrations.AddLegendaryCreatureNameIndex do
  use Ecto.Migration

  def change do
    create index(:cards, ["normalized_name text_pattern_ops"],
             name: :cards_legendary_creature_normalized_name_prefix_index,
             where: "is_legendary = true AND is_creature = true"
           )
  end
end
