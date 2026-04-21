defmodule TopDeckTutor.Search.Parser do
  def parse(tokens) when is_list(tokens) do
    tokens
    |> Enum.reduce_while({:ok, []}, fn token, {:ok, acc} ->
      case parse_token(token) do
        {:ok, node} -> {:cont, {:ok, [node | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, ast} -> {:ok, Enum.reverse(ast)}
      error -> error
    end
  end

  defp parse_token(token) when is_binary(token) do
    cond do
      String.starts_with?(token, "type:") ->
        parse_type(token)

      String.starts_with?(token, "is:") ->
        parse_flag(token)

      Regex.match?(~r/^mv(<=|>=|=)-?\d+(\.\d+)?$/, token) ->
        parse_mv(token)

      true ->
        {:ok, {:text, token}}
    end
  end

  defp parse_type("type:"), do: {:error, "Missing value for type:"}

  defp parse_type(token) do
    value =
      token
      |> String.replace_prefix("type:", "")
      |> String.trim()
      |> String.downcase()

    if value == "" do
      {:error, "Missing value for type:"}
    else
      {:ok, {:field_eq, :type, value}}
    end
  end

  defp parse_flag("is:"), do: {:error, "Missing value for is:"}

  defp parse_flag(token) do
    value =
      token
      |> String.replace_prefix("is:", "")
      |> String.trim()
      |> String.downcase()

    case value do
      "legendary" -> {:ok, {:flag, :legendary}}
      other -> {:error, "Unknown flag: #{other}"}
    end
  end

  defp parse_mv(token) do
    case Regex.run(~r/^mv(<=|>=|=)(-?\d+(\.\d+)?)$/, token) do
      [_, op, value, _] ->
        {:ok, {:cmp, :mana_value, to_op(op), Decimal.new(value)}}

      [_, op, value] ->
        {:ok, {:cmp, :mana_value, to_op(op), Decimal.new(value)}}

      _ ->
        {:error, "Invalid mana value comparison: #{token}"}
    end
  end

  defp to_op("<="), do: :<=
  defp to_op(">="), do: :>=
  defp to_op("="), do: :==
end
