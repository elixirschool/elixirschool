---
version: 1.0.2
title: Sigils
---

シギル(sigil)を使う/作る

{% include toc.html %}

## シギルの概要

Elixirには文字列リテラルを表現したり取り扱うための別の構文があります。シギル(sigil)はチルダ `~` から始まり文字が一つそれに続きます。Elixirのコアには予め組み込まれたシギルがありますが、それだけではなく言語を拡張したい場合には独自のシギルを作ることもできます。

利用できるシギルのリストには以下のものが含まれます:

- `~C` **エスケープや埋め込みを含まない**文字のリストを生成する
- `~c` **エスケープや埋め込みを含む**文字のリストを生成する
- `~R` **エスケープや埋め込みを含まない**正規表現を生成する
- `~r` **エスケープや埋め込みを含む**正規表現を生成する
- `~S` **エスケープや埋め込みを含まない**文字列を生成する
- `~s` **エスケープや埋め込みを含む**文字列を生成する
- `~W` **エスケープや埋め込みを含まない**単語のリストを生成する
- `~w` **エスケープや埋め込みを含む**単語のリストを生成する
- `~N` `NaiveDateTime` 構造体を生成する

デリミタのリストには以下のものが含まれます:

- `<...>` カギ括弧のペア
- `{...}` 中括弧のペア
- `[...]` 大括弧のペア
- `(...)` 小括弧のペア
- `|...|` パイプ記号のペア
- `/.../` スラッシュのペア
- `"..."` ダブルクォートのペア
- `'...'` シングルクォートのペア

### 文字のリスト

`~c` 及び `~C` シギルはそれぞれ文字のリストを生成します。例えば:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

小文字の `~c` は計算結果を埋め込みますが一方で大文字の `~C` は埋め込まないことがわかります。この大文字/小文字による結果は組み込まれたシギル全てに共通するものであることが以降を見ていくとわかるでしょう。

### 正規表現

`~r` 及び `~R` シギルはそれぞれ正規表現を生成します。正規表現は動的にも `Regex` 関数内で使うためにも生成できます。 例えば:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

値が等しいか調べるテストの一番目で `Elixir` は与えられた正規表現と一致しないことがわかります。それは大文字で始まっているからです。ElixirはPerl Compatible Regular Expressions (Perl互換正規表現式, PCRE)をサポートしているのでシギルの末尾に `i` を追加することで大文字・小文字の区別をしないように指定できます。

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

さらに、ElixirはErlangの正規表現ライブラリを元に作られた [Regex](https://hexdocs.pm/elixir/Regex.html) APIを提供しています。
`Regex.split/2` で正規表現シギルを使ってみましょう。

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

ご覧のとおり `~r/_/` シギルによってアンダースコアで文字列 `"100_000_000"` が分割されました。 `Regex.split` はリストを返します。

### 文字列

`~s` 及び `~S` シギルは文字列データを生成するのに使われます。例えば：

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

ところで違いは何でしょうか。それは文字リストのシギルで既に見たのと同じです。つまり埋め込みとエスケープシーケンスを使うか使わないか、ということです。他の例を見てみましょう:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### 単語のリスト

単語のリストのシギルは時々役立ちます。費やす時間、キーを打つ回数、それと間違いなくコードベースの複雑さを減らすことができます。以下に簡単な例を挙げます：

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

デリミタ間の、空白で区切られた単語がリストになったのがわかりますね。でも２つの例に違いはありません。そう、違いはまたも埋め込みとエスケープシーケンスを使うか使わないかなのです。次の例を見てください:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

[NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) は **タイムゾーンがない** `DateTime` を表現する構造体を手早く作るときに有用です。

ほとんどの場合、 `NaiveDateTime` 構造体を直接作ることは避けるべきです。ですが、パターンマッチングには有用です。例をあげます:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

### シギルを作る

Elixirのゴールの一つは拡張性のあるプログラミング言語になることです。独自のシギルを簡単に作ることができても全く驚くには当たりません。この例では文字列を大文字に変換するシギルを作ります。Elixirのコアには既にこのための関数(`String.upcase/1`)が用意されているのでシギルでこの関数をラップします。

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

最初に `MySigils` という名前のモジュールを定義し、そのモジュールの中で `sigil_u` という名前の関数を作ります。既存のシギルの名前空間には `~u` シギルはないのでそれを使いましょう。 `_u` はチルダの後に文字 `u` を使うということを示します。関数定義には2つの引数が必要です。入力とリストです。
