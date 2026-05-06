defmodule TopDeckTutor.Formats.CommanderTest do
  use ExUnit.Case, async: true

  alias TopDeckTutor.Cards.Card
  alias TopDeckTutor.Formats.Commander

  describe "metadata" do
    test "defines the commander format" do
      assert Commander.key() == "commander"
      assert Commander.display_name() == "Commander"
      assert Commander.allowed_sections() == ["mainboard", "sideboard", "maybeboard", "command"]
    end
  end

  describe "legal_card?/2" do
    test "uses card legalities for the selected format" do
      legal_card = %Card{legalities: %{"commander" => "legal"}}
      banned_card = %Card{legalities: %{"commander" => "banned"}}
      missing_legality = %Card{legalities: %{"modern" => "legal"}}

      assert Commander.legal_card?(legal_card, "commander")
      refute Commander.legal_card?(banned_card, "commander")
      refute Commander.legal_card?(missing_legality, "commander")
    end
  end

  describe "max_copies/2" do
    test "allows one copy of non-basic cards" do
      card = %Card{name: "Sol Ring", type_line: "Artifact"}

      assert Commander.max_copies(card, "commander") == 1
    end

    test "does not limit basic lands" do
      card = %Card{name: "Island", type_line: "Basic Land — Island"}

      assert Commander.max_copies(card, "commander") == :unlimited
    end
  end
end
