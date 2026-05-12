defmodule TopDeckTutor.Formats.Format do
  @moduledoc """
  Behaviour for deck construction rules keyed by `decks.format`.
  """

  @callback key() :: String.t()
  @callback display_name() :: String.t()
  @callback validate_deck(struct()) :: :ok | {:error, [String.t()]}
  @callback legal_card?(struct(), String.t()) :: boolean()
  @callback max_copies(struct(), String.t()) :: pos_integer() | :unlimited
  @callback allowed_sections() :: [String.t()]
end
