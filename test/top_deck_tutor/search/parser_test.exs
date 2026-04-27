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

  test "parses mana value less than comparison" do
    assert {:ok, [{:cmp, :mana_value, :<, value}]} = Parser.parse(["mv<3"])
    assert Decimal.equal?(value, Decimal.new("3"))
  end

  test "parses mana value greater than comparison" do
    assert {:ok, [{:cmp, :mana_value, :>, value}]} = Parser.parse(["mv>5"])
    assert Decimal.equal?(value, Decimal.new("5"))
  end

  test "parses name contains filter" do
    assert {:ok, [{:field_contains, :name, "sol"}]} =
             Parser.parse(["name:sol"])
  end

  test "parses text contains filter" do
    assert {:ok, [{:field_contains, :oracle_text, "draw"}]} =
             Parser.parse(["text:draw"])
  end

  test "parses quoted text field filter" do
    assert {:ok, [{:field_contains, :oracle_text, "Draw two"}]} =
             Parser.parse([~s(text:"Draw two")])
  end

  test "parses negated type filters" do
    assert {:ok, [{:not, {:field_eq, :type, "creature"}}]} =
             Parser.parse(["-type:creature"])
  end

  test "parses negated text contains filters" do
    assert {:ok, [{:not, {:field_contains, :oracle_text, "draw a card"}}]} =
             Parser.parse([~s(-text:"draw a card")])
  end

  test "parses negated name contains filters" do
    assert {:ok, [{:not, {:field_contains, :name, "ajani"}}]} =
             Parser.parse(["-name:ajani"])
  end

  test "errors on missing negated field value" do
    assert {:error, "Missing value for type:"} = Parser.parse(["-type:"])
  end
end
