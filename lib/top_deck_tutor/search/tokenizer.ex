defmodule TopDeckTutor.Search.Tokenizer do
  @token_regex ~r/"([^"]*)"|(\S+)/u

  def tokenize(query) when is_binary(query) do
    tokens =
      @token_regex
      |> Regex.scan(query, capture: :all_but_first)
      |> Enum.map(fn
        [left, right] -> if left != "", do: left, else: right
        [token] -> token
      end)
      |> Enum.reject(&(&1 == ""))

    {:ok, tokens}
  end
end
