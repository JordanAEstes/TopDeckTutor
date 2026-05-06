defmodule TopDeckTutor.Formats do
  @moduledoc """
  Registry for supported deck construction formats.
  """

  alias TopDeckTutor.Formats.{Commander, Modern, Pauper, Standard}

  @formats [Commander, Modern, Pauper, Standard]

  def all, do: @formats

  def get(format_key) do
    normalized_key = normalize_key(format_key)

    Enum.find(@formats, fn format ->
      format.key() == normalized_key
    end)
  end

  def fetch!(format_key) do
    case get(format_key) do
      nil -> raise ArgumentError, "unsupported format: #{inspect(format_key)}"
      format -> format
    end
  end

  def normalize_key(format_key) when is_binary(format_key) do
    format_key
    |> String.trim()
    |> String.downcase()
  end

  def normalize_key(_format_key), do: nil
end
