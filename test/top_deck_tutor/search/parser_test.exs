defmodule TopDeckTutor.Search.ParserTest do
  use ExUnit.Case, async: true

  alias TopDeckTutor.Search.Parser

  @colors ["w", "u", "b", "r", "g"]

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

  test "parses single-color color identity filters" do
    assert {:ok, [{:color_identity, ["W"]}]} = Parser.parse(["ci:w"])
  end

  test "parses multi-color color identity filters" do
    assert {:ok, [{:color_identity, ["W", "U"]}]} = Parser.parse(["ci:wu"])
  end

  test "parses three-color color identity filters" do
    assert {:ok, [{:color_identity, ["U", "B", "R"]}]} = Parser.parse(["ci:ubr"])
  end

  test "parses every non-empty color identity combination" do
    for colors <- color_combinations(@colors) do
      token = Enum.join(colors)
      expected = Enum.map(colors, &String.upcase/1)

      assert {:ok, [{:color_identity, ^expected}]} = Parser.parse(["ci:#{token}"])
    end
  end

  test "errors on invalid color identity filters" do
    assert {:error, "Invalid color identity: x"} = Parser.parse(["ci:x"])
    assert {:error, "Invalid color identity: wx"} = Parser.parse(["ci:wx"])
    assert {:error, "Missing value for ci:"} = Parser.parse(["ci:"])
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

  defp color_combinations(colors) do
    1..length(colors)
    |> Enum.flat_map(&combinations(colors, &1))
  end

  defp combinations(_colors, 0), do: [[]]
  defp combinations([], _count), do: []

  defp combinations([head | tail], count) do
    with_head = Enum.map(combinations(tail, count - 1), &[head | &1])
    without_head = combinations(tail, count)
    with_head ++ without_head
  end
end
