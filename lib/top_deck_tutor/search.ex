defmodule TopDeckTutor.Search do
  alias TopDeckTutor.Search.{Tokenizer, Parser, Compiler}

  def parse(query) when is_binary(query) do
    with {:ok, tokens} <- Tokenizer.tokenize(query),
         {:ok, ast} <- Parser.parse(tokens) do
      {:ok, ast}
    end
  end

  def compile(ast, queryable) when is_list(ast) do
    {:ok, Compiler.compile(ast, queryable)}
  end

  def run(query_string, queryable) when is_binary(query_string) do
    with {:ok, ast} <- parse(query_string),
         {:ok, query} <- compile(ast, queryable) do
      {:ok, %{ast: ast, query: query}}
    end
  end
end
