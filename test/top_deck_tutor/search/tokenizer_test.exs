defmodule TopDeckTutor.Search.TokenizerTest do
  use ExUnit.Case, async: true

  alias TopDeckTutor.Search.Tokenizer

  test "tokenizes plain terms" do
    assert {:ok, ["draw", "type:creature", "mv<=3"]} =
             Tokenizer.tokenize("draw type:creature mv<=3")
  end

  test "keeps quoted phrases together" do
    assert {:ok, ["type:creature", "draw a card", "mv<=3"]} =
             TopDeckTutor.Search.Tokenizer.tokenize(~s(type:creature "draw a card" mv<=3))
  end

  test "tokenizes whitespace-seperated terms" do
    assert {:ok, ["sol", "ring"]} =
             TopDeckTutor.Search.Tokenizer.tokenize("sol ring")
  end

  test "treats quoted phrases as a single token" do
    assert {:ok, ["draw a card"]} =
             TopDeckTutor.Search.Tokenizer.tokenize(~s("draw a card"))
  end

  test "keeps field-prefixed quoted values together" do
    assert {:ok, ["name:divination", ~s(text:"Draw two")]} =
             TopDeckTutor.Search.Tokenizer.tokenize(~s(name:divination text:"Draw two"))
  end

  test "keeps quoted name field values together" do
    assert {:ok, [~s(name:"sol ring")]} =
             TopDeckTutor.Search.Tokenizer.tokenize(~s(name:"sol ring"))
  end

  test "keeps negated quoted field values together" do
    assert {:ok, [~s(-text:"draw a card")]} =
             TopDeckTutor.Search.Tokenizer.tokenize(~s(-text:"draw a card"))
  end

  test "keeps negated field terms together" do
    assert {:ok, ["-type:creature"]} =
             TopDeckTutor.Search.Tokenizer.tokenize("-type:creature")
  end
end
