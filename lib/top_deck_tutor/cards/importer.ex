defmodule TopDeckTutor.Cards.Importer do
  @moduledoc false

  import Ecto.Query, warn: false

  alias TopDeckTutor.Repo
  alias TopDeckTutor.Cards.Card
  alias TopDeckTutor.Cards.Normalizer

  @default_batch_size 1_000

  @updatable_fields [
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
    :raw,
    :updated_at
  ]

  def import_file(path, opts \\ []) when is_binary(path) do
    batch_size = Keyword.get(opts, :batch_size, @default_batch_size)

    path
    |> File.stream!([], 65_536)
    |> Jaxon.Stream.from_enumerable()
    |> Jaxon.Stream.query([:all])
    |> Stream.flat_map(&normalize_stream_item/1)
    |> Stream.chunk_every(batch_size)
    |> Enum.reduce(%{ok: 0, error: 0, batches: 0}, fn batch, acc ->
      case import_batch(batch) do
        {count, nil} ->
          %{
            ok: acc.ok + count,
            error: acc.error,
            batches: acc.batches + 1
          }

        {count, error} ->
          raise """
          Batch import failed after #{acc.ok} imported rows.
          Last successful batch count: #{count}
          Error: #{inspect(error)}
          """
      end
    end)
  end

  def import_batch([]), do: {0, nil}

  def import_batch(batch) when is_list(batch) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    placeholders = %{now: now}

    rows =
      Enum.map(batch, fn attrs ->
        attrs
        |> Map.put(:inserted_at, {:placeholder, :now})
        |> Map.put(:updated_at, {:placeholder, :now})
      end)

    {count, _returned_rows} =
      Repo.insert_all(
        Card,
        rows,
        placeholders: placeholders,
        on_conflict: {:replace, @updatable_fields},
        conflict_target: :id
      )

    {count, nil}
  rescue
    e -> {0, e}
  end

  defp normalize_stream_item(item) when is_map(item) do
    [Normalizer.from_scryfall(item)]
  end

  defp normalize_stream_item(items) when is_list(items) do
    Enum.map(items, &Normalizer.from_scryfall/1)
  end
end
