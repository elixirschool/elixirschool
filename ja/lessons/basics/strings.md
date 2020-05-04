---
version: 1.2.0
title: 文字列
---

文字列、文字のリスト、書記素、コードポイントとは。

{% include toc.html %}

## 文字列

Elixirにおいて文字列とはバイトのシーケンスに他なりません。例を見てみましょう:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

文字列に `0` というバイトを追加すればIExは文字列をバイナリとして表示します。これはもう有効な文字列ではないからです。このトリックは文字列を表現するバイトがなんなのか確認したい時に有用です。

> 註: << >> 記法はコンパイラにこれらのシンボルで囲まれた中身はバイト列であることを示します。

## 文字リスト

内部ではElixirの文字列は文字の配列というよりはバイトのシーケンスとして表現されており、Elixirは(複数の文字のリストである)文字リストという型を別に持っています。Elixirの文字列はダブルクオートで生成され、一方文字リストはシングルクオートで生成されます。

これらの違いは何でしょう？文字リストから得られる個々の値はバイナリで表現されているコードポイントで、UTF-8でエンコードされています。では掘り下げてみましょう:

```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` は ł のコードポイントですが、UTF-8でエンコードされているので `197` 、 `130` という２つのバイトになっています。

`?` を使って、文字のコードポイントを取得することができます。

```elixir
iex> ?Z
90
```

これにより、シンボルには 'Z' ではなく、 `?Z` という表記を使用できることがわかります。

Elixirでプログラムするときは通常は文字リストを使わず文字列を使います。文字リストがサポートされているのは一部のErlangモジュールがそれを必要としているからです。

詳しい情報が必要なら公式の [`Getting Started Guide`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html) を見てください。

## 書記素とコードポイント

コードポイントはただ単純にUnicodeの文字で、UTF-8のエンコーディングに応じて1バイト以上のバイトで表現されるものとして差し支えありません。ASCIIの範囲外の文字は常に2バイト以上にエンコードされます。例えば、 `á, ñ, è` のようなチルダやアクセントのついたラテン文字は2バイトにエンコードされます。アジアの言語の文字はしばしば3から4バイトにエンコードされます。書記素は一文字にレンダリングされる複数のコードポイントから成ります。

Stringモジュールにはそれらを得るための2つの関数、 `graphemes/1` と `codepoints/1` が用意されています。例を見てみましょう:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## 文字列関数

では、Stringモジュールにある重要で役に立つ関数をいくつか見てみましょう。このレッスンでは数ある関数のうち一部のみ扱います。全ての関数を確認したい場合は、公式ドキュメントの [`String`](https://hexdocs.pm/elixir/String.html) を見てください。

### `length/1`

書記素の長さを返します。

```elixir
iex> String.length "Hello"
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

これでもうStringモジュールを使いこなせるようになったことを示すため2つ簡単な練習問題をやってみましょう。

### アナグラム

文字列Aと文字列Bは、もしAまたはBを並び替えて同じにできるならばアナグラムであると考えられます。例えば:

- A = super
- B = perus

文字列Aを並び替えれば文字列Bにできますし逆もまた同様です。

ではElixirで2つの文字列がアナグラムかどうか調べるにはどうすればいいでしょうか。一番簡単な解は文字列をアルファベット順に並び替えてそれらが等しいかどうか調べるやり方です。次の例を見てみましょう:

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

まずは `anagrams?/2` を見てみましょう。まず受け取った2つのパラメータがバイナリかそうでないかチェックします。これによりパラメータがElixirでの文字列かどうかを見るわけです。

その後、文字列をアルファベット順に並び替える関数を呼び出しますが、その関数では最初に文字列を小文字に変換し、次に文字列の書記素の配列を返す `String.graphemes/1` を使います。最後にこのリストを `Enum.sort/1` に渡します。単純でしょう？

ではiexで出力を確認しましょう:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

見ての通り、最後の `anagrams?` の呼び出しがFunctionClauseErrorを引き起こしています。このエラーは2つのバイナリでない引数を受け取る関数がモジュール内にないと教えてくれています。これは我々が意図したとおりで、2つの文字列だけを受け取りそれ以外は受け取らないようになっています。
