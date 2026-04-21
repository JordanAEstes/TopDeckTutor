defmodule TopDeckTutor.Search.Tokenizer do
  @token_regex ~r/\w+:"[^"]*"|"[^"]*"|\S+/u

  def tokenize(query) when is_binary(query) do
    tokens =
      @token_regex
      |> Regex.scan(query)
      |> List.flatten()
      |> Enum.map(&normalize_token/1)

    {:ok, tokens}
  end

  defp normalize_token(<<"\"", rest::binary>>) do
    String.trim_trailing(rest, "\"")
  end

  defp normalize_token(token), do: token
end
