defmodule TopDeckTutor.Search.ParserTest do
  use ExUnit.Case, async: true

  alias TopDeckTutor.Search.Parser

  test "parses free text" do
    assert {:ok, [{:text, "draw"}]} = Parser.parse(["draw"])
  end

  test "parses type filters" do
    assert {:ok, [{:field_eq, :type, "creature"}]} = Parser.parse(["type:creature"])
  end

  test "parses mana value comparisons" do
    assert {:ok, [{:cmp, :mana_value, :<=, value}]} = Parser.parse(["mv<=3"])
    assert Decimal.equal?(value, Decimal.new("3"))
  end

  test "parses flags" do
    assert {:ok, [{:flag, :legendary}]} = Parser.parse(["is:legendary"])
  end

  test "errors on unknown flags" do
    assert {:error, "Unknown flag: funny"} = Parser.parse(["is:funny"])
  end
end
