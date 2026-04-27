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
      String.starts_with?(token, "-") and token != "-" ->
        parse_negated(token)

      String.starts_with?(token, "name:") ->
        parse_contains_field(token, "name:", :name)

      String.starts_with?(token, "text:") ->
        parse_contains_field(token, "text:", :oracle_text)

      String.starts_with?(token, "type:") ->
        parse_type(token)

      String.starts_with?(token, "rarity:") ->
        parse_rarity(token)

      String.starts_with?(token, "set:") ->
        parse_exact_field(token, "set:", :set_code)

      String.starts_with?(token, "legal:") ->
        parse_legality(token, "legal:", "legal")

      String.starts_with?(token, "banned:") ->
        parse_legality(token, "banned:", "banned")

      String.starts_with?(token, "restricted:") ->
        parse_legality(token, "restricted:", "restricted")

      String.starts_with?(token, "color:") ->
        parse_color(token)

      String.starts_with?(token, "ci:") ->
        parse_color_identity(token)

      String.starts_with?(token, "is:") ->
        parse_flag(token)

      Regex.match?(~r/^mv(<=|>=|<|>|=)-?\d+(\.\d+)?$/, token) ->
        parse_mv(token)

      true ->
        {:ok, {:text, token}}
    end
  end

  defp parse_negated(token) do
    token
    |> String.replace_prefix("-", "")
    |> parse_token()
    |> case do
      {:ok, node} -> {:ok, {:not, node}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_contains_field(token, prefix, field) do
    value =
      token
      |> String.replace_prefix(prefix, "")
      |> String.trim()
      |> strip_wrapping_quotes()

    if value == "" do
      {:error, "Missing value for #{prefix}"}
    else
      {:ok, {:field_contains, field, value}}
    end
  end

  defp strip_wrapping_quotes(value) do
    case value do
      <<?", rest::binary>> ->
        String.trim_trailing(rest, "\"")

      other ->
        other
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

  defp parse_rarity("rarity:"), do: {:error, "Missing value for rarity:"}

  defp parse_rarity(token) do
    with {:ok, value} <- normalized_field_value(token, "rarity:"),
         :ok <- validate_rarity(value) do
      {:ok, {:field_eq, :rarity, value}}
    end
  end

  defp parse_exact_field(token, prefix, field) do
    with {:ok, value} <- normalized_field_value(token, prefix) do
      {:ok, {:field_eq, field, value}}
    end
  end

  defp parse_legality(token, prefix, status) do
    with {:ok, value} <- normalized_field_value(token, prefix) do
      {:ok, {:legality, value, status}}
    end
  end

  defp parse_color("color:"), do: {:error, "Missing value for color:"}

  defp parse_color(token) do
    value =
      token
      |> String.replace_prefix("color:", "")
      |> String.trim()
      |> String.upcase()

    cond do
      value == "" ->
        {:error, "Missing value for color:"}

      value == "C" ->
        {:ok, {:color, []}}

      true ->
        colors = String.graphemes(value)

        if Enum.all?(colors, &valid_color?/1) do
          {:ok, {:color, colors}}
        else
          {:error, "Invalid color: #{String.downcase(value)}"}
        end
    end
  end

  defp parse_color_identity("ci:"), do: {:error, "Missing value for ci:"}

  defp parse_color_identity(token) do
    value =
      token
      |> String.replace_prefix("ci:", "")
      |> String.trim()
      |> String.upcase()

    cond do
      value == "" ->
        {:error, "Missing value for ci:"}

      true ->
        colors = String.graphemes(value)

        if Enum.all?(colors, &valid_color?/1) do
          {:ok, {:color_identity, colors}}
        else
          {:error, "Invalid color identity: #{String.downcase(value)}"}
        end
    end
  end

  defp normalized_field_value(token, prefix) do
    value =
      token
      |> String.replace_prefix(prefix, "")
      |> String.trim()
      |> String.downcase()

    if value == "" do
      {:error, "Missing value for #{prefix}"}
    else
      {:ok, value}
    end
  end

  defp validate_rarity("common"), do: :ok
  defp validate_rarity("uncommon"), do: :ok
  defp validate_rarity("rare"), do: :ok
  defp validate_rarity("mythic"), do: :ok
  defp validate_rarity(other), do: {:error, "Unknown rarity: #{other}"}

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
    case Regex.run(~r/^mv(<=|>=|<|>|=)(-?\d+(\.\d+)?)$/, token) do
      [_, op, value, _] ->
        {:ok, {:cmp, :mana_value, to_op(op), Decimal.new(value)}}

      [_, op, value] ->
        {:ok, {:cmp, :mana_value, to_op(op), Decimal.new(value)}}

      _ ->
        {:error, "Invalid mana value comparison: #{token}"}
    end
  end

  defp valid_color?("W"), do: true
  defp valid_color?("U"), do: true
  defp valid_color?("B"), do: true
  defp valid_color?("R"), do: true
  defp valid_color?("G"), do: true
  defp valid_color?(_), do: false

  defp to_op("<="), do: :<=
  defp to_op(">="), do: :>=
  defp to_op("<"), do: :<
  defp to_op(">"), do: :>
  defp to_op("="), do: :==
end
