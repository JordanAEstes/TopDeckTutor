defmodule TopDeckTutor.FormatsTest do
  use ExUnit.Case, async: true

  alias TopDeckTutor.Formats
  alias TopDeckTutor.Formats.{Commander, Modern, Pauper, Standard}

  describe "all/0" do
    test "lists supported format modules" do
      assert Formats.all() == [Commander, Modern, Pauper, Standard]
    end
  end

  describe "get/1" do
    test "resolves known format keys" do
      assert Formats.get("commander") == Commander
      assert Formats.get("modern") == Modern
      assert Formats.get("pauper") == Pauper
      assert Formats.get("standard") == Standard
    end

    test "normalizes display-name style format values" do
      assert Formats.get("Commander") == Commander
      assert Formats.get(" Standard ") == Standard
    end

    test "returns nil for unknown format keys" do
      assert Formats.get("frontier") == nil
      assert Formats.get(nil) == nil
    end
  end

  describe "fetch!/1" do
    test "returns known format modules" do
      assert Formats.fetch!("commander") == Commander
    end

    test "raises for unknown format keys" do
      assert_raise ArgumentError, ~r/unsupported format/i, fn ->
        Formats.fetch!("frontier")
      end
    end
  end
end
