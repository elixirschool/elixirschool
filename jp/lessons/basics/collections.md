---
layout: page
title: コレクション
category: basics
order: 2
lang: jp
---

リスト、タプル、キーワードリスト、マップ、ディクショナリ(辞書)、そしてコンビネータ。

## 目次

- [リスト](#section-1)
	- [リストの連結](#section-2)
	- [リストの減算](#section-3)
	- [頭部 / 尾部](#section-4)
- [タプル](#section-5)
- [キーワードリスト](#section-6)
- [マップ](#section-7)
- [ディクショナリ(辞書)](#section-8)

## リスト

リストは値の単純なコレクションで、複数の型を含むことができます。また、一意ではない値を含むことができます:

```elixir
iex> [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
```

Elixirはリストを連結リストとして実装しています。すなわちリストの長さを得るのは`O(n)`の処理となります。このことから、リスト先頭への追加はほとんどの場合にリスト末尾への追加より高速です:

```elixir
iex> list = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.41, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.41, :pie, "Apple", "Cherry"]
```


### リストの連結

リストの連結には`++/2`演算子を用います:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### リストの減算

減算に対応するために`--/2`演算子が用意されています。存在しない値を引いてしまっても安全です:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### 頭部 / 尾部

リストを扱う際には、よくリストの頭部と尾部を利用したりします。頭部はそのリストの最初の要素で、尾部は残りの要素になります。Elixirはこれらを扱うために、`hd`と`tl`という2つの便利なメソッドを用意しています:

```elixir
iex> hd [3.41, :pie, "Apple"]
3.41
iex> tl [3.41, :pie, "Apple"]
[:pie, "Apple"]
```

前述した関数に加えて、パイプ演算子`|`を使うこともできます。このパターンについては後のレッスンで取り上げます:

```elixir
iex> [h|t] = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> h
3.41
iex> t
[:pie, "Apple"]
```

## タプル

タプルはリストに似ていますが、各要素はメモリ上に隣接して格納されます。このため、タプルの長さを得るのは高速ですが、修正を行うのは高コストとなります。というのも、新しいタプルは全ての要素がメモリにコピーされるからです。タプルは波括弧を用いて定義されます:

```elixir
iex> {3.41, :pie, "Apple"}
{3.41, :pie, "Apple"}
```

タプルは関数から補助的な情報を返す仕組みとしてよく利用されます。この便利さは、パターンマッチングについて扱う時により明らかになるでしょう:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## キーワードリスト

キーワードとマップはElixirの連想コレクションで、どちらも`Dict`モジュールを実装しています。Elixirでは、キーワードリストは最初の要素がアトムのタプルからなる特別なリストで、リストと同様の性能になります:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

キーワードリストの重要性は次の3つの特徴によって強調づけられています:

+ キーはアトムです。
+ キーは順序付けされています。
+ キーは一意ではありません。

こうした理由から、キーワードリストは関数にオプションを渡すために非常に良く用いられます。

## マップ

Elixirではマップは"花形の"キーバリューストアで、キーワードリストとは違ってどんな型のキーも使え、順序付けされません。マップは`%{}`構文で定義することができます:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

重複したキーが追加された場合は、前の値が置き換えられます:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

上記の出力からわかるように、アトムのキーだけを含んだマップには特別な構文があります:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

## ディクショナリ(辞書)

Elixirでは、キーワードリストとマップはどちらも`Dict`モジュールを実装しますが、そういうわけでこれらはまとめてディクショナリ(辞書)として知られています。もし独自のキーバリューストアを作る必要があるなら、`Dict`モジュールを実装するのが手始めとしては良い方法です。

[`Dict`モジュール](http://elixir-lang.org/docs/stable/elixir/#!Dict.html)はこうしたディクショナリに触れたり、操作したりするために多くの便利な関数を用意しています:

```elixir
# キーワードリスト
iex> Dict.put([foo: "bar"], :hello, "world")
[hello: "world", foo: "bar"]

# マップ
iex> Dict.put(%{:foo => "bar"}, "hello", "world")
%{:foo => "bar", "hello" => "world"}

iex> Dict.has_key?(%{:foo => "bar"}, :foo)
true
```
