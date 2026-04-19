defmodule Mix.Tasks.Mtg.ImportCards do
  use Mix.Task

  @shortdoc "Imports Scryfall card JSON into the database"

  def run(args) do
    Mix.Task.run("app.start")

    {opts, rest, _invalid} =
      OptionParser.parse(args,
        strict: [batch_size: :integer]
      )

    case rest do
      [path] ->
        batch_size = Keyword.get(opts, :batch_size, 1_000)

        Mix.shell().info("Importing from #{path}")
        Mix.shell().info("Batch size: #{batch_size}")

        result = TopDeckTutor.Cards.Importer.import_file(path, batch_size: batch_size)

        Mix.shell().info("Imported rows: #{result.ok}")
        Mix.shell().info("Processed batches: #{result.batches}")

      _ ->
        Mix.raise("Usage: mix mtg.import_cards path/to/cards.json [--batch-size 1000]")
    end
  end
end
