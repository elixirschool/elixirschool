---
version: 0.9.0
title: Strings
---

Elixirにおいて文字列とは何でしょうか。文字のリスト、書記素、コードポイントとは。

{% include toc.html %}

## Elixirの文字列

Elixirにおいて文字列とはバイトのシーケンスに他なりません。例を見てみましょう:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"

iex> string = <<227, 129, 147, 227, 130, 147, 227, 129, 171, 227, 129, 161, 227, 130, 143>>
"こんにちわ"

```

>註: << >>記法はコンパイラにこれらのシンボルで囲まれた中身はバイト列であることを示します。

## 文字リスト

内部ではElixirの文字列は文字の配列というよりはバイトのシーケンスとして表現されており、Elixirは
(複数の文字のリストである)文字リストという型を別に持っています。Elixirの文字列はダブルクオートで生成され、一方文字リストは
シングルクオートで生成されます。

これらの違いは何でしょう？文字リストから得られる個々の値は文字のASCIIコードです。では掘り下げてみましょう:

```elixir
iex> char_list = 'hello'
'hello'

iex> [hd|tl] = char_list
'hello'

iex> {hd, tl}
{104, 'ello'}


iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

Elixirでプログラムするときは通常は文字リストを使わず文字列を使います。文字リストがサポートされているのは
一部のErlangモジュールがそれを必要としているからです。

## 書記素とコードポイント

コードポイントはただ単純にUnicodeの文字で、UTF-8のエンコーディングに応じて1バイトまたはそれ以上のバイトで表現されるものとして差し支えありません。
ASCIIの範囲外の文字は常に2バイト以上にエンコードされます。例えば、`á, ñ, è`のようなチルダやアクセントのついたラテン文字は2バイトにエンコードされます。アジアの言語の文字はしばしば3から4バイトにエンコードされます。
書記素は一文字にレンダリングされる複数のコードポイントから成ります。
Stringモジュールにはそれらを得るための2つのメソッド、`graphemes/1` と `codepoints/1`が用意されています。
例を見てみましょう:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]

iex> string = "\uFF76\uFF9E"    # 半角カタカナ
"ｶﾞ"

iex> String.codepoints string   # コードポイントは半角の"ｶ"と"ﾞﾞ"にわかれる
["ｶ", "ﾞ"]

iex> String.graphemes string    # 書記素では1つと数えられる
["ｶﾞ"]

```

## 文字列関数

では、Stringモジュールにある重要で役に立つ関数をいくつか見てみましょう。このレッスンでは数ある関数のうち一部のみ扱います。全ての関数を確認したい場合は、公式ドキュメントの [`String`](https://hexdocs.pm/elixir/String.html) を見てください。

### `length/1`

書記素の長さを返します。

```elixir
iex> String.length "Hello"
5

iex> String.length "こんにちわ"  # ひらがなでも正しく文字数が返る
5
```

### `replace/3`

文字列の中の検索パターンを新しい文字列に置き換えて得られた文字列を返します。

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

文字列をn回繰り返した文字列を返します。

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

パターンによって分割された文字列の配列を返します。

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## 練習問題

これでもう私たちはStringモジュールを使いこなせるようになったことを示すため2つ簡単な練習問題をやってみましょう。

### アナグラム

文字列Aと文字列Bは、もしAまたはBを並び替えて同じにできるならばアナグラムであると考えられます。例えば:

+ A = super
+ B = perus

文字列Aを並び替えれば文字列Bにできますし逆もまた同様です。

ではElixirで2つの文字列がアナグラムかどうか調べるにはどうすればいいでしょうか。
一番簡単な解は文字列をアルファベット順に並び替えてそれらが等しいかどうか調べるやり方です。次の例を見てみましょう:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

まずは `anagrams?/2` を見てみましょう。　まず受け取った2つのパラメータがバイナリかそうでないかチェックします。
これによりパラメータがElixirでの文字列かどうかを見るわけです。

その後、文字列をアルファベット順に並び替える関数を呼び出しますが、その関数では最初に文字列を小文字に変換し、次に文字列の書記素の配列を返す `String.graphemes` を使います。単純でしょう？

ではiexで出力を確認しましょう:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2
    iex:2: Anagram.anagrams?(3, 5)
```

見ての通り、最後の `anagrams?` の呼び出しがFunctionClauseErrorを引き起こしています。このエラーは2つのバイナリでない引数を受け取る関数がモジュール内にないと教えてくれています。これは我々が意図したとおりで、2つの文字列だけを受け取りそれ以外は受け取らないようになっています。
