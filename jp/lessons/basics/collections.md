---
version: 0.9.0
title: コレクション
---

リスト、タプル、キーワードリスト、マップ、そしてコンビネータ。

{% include toc.html %}

## リスト

リストは値の単純なコレクションで、複数の型を含むことができます。また、一意ではない値を含むことができます:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixirはリストを連結リストとして実装しています。すなわちリストの長さを得るのは`O(n)`の処理となります。このことから、リスト先頭への追加はほとんどの場合にリスト末尾への追加より高速です:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### リストの連結

リストの連結には`++/2`演算子を用います:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

上記の名前(`++/2`)の形式についての追記: Elixir(とその土台のErlang)において、関数や演算子の名前は2つの部分、与えられた名前(ここでは`++`)とその _アリティ_ から成ります。アリティはElixir(とErlang)のコードについて説明するときの中核となるものです。アリティは関数や演算子が取る引数の数(この場合は2)です。名前とアリティはスラッシュで繋げられます。後ほどより詳しく扱いますが、この知識は今のところこの表記法を理解する助けになるでしょう。

### リストの減算

減算に対応するために`--/2`演算子が用意されています。存在しない値を引いてしまっても安全です:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

重複した値に注意してください。右辺の要素のそれぞれに対し、左辺の要素のうち初めて登場した同じ値が順次削除されます:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**参考:** 値のマッチには [strict comparison](../basics/#comparison) が使われています。

### 頭部 / 尾部

リストを扱う際には、よくリストの頭部と尾部を利用したりします。頭部はそのリストの最初の要素で、尾部は残りの要素になります。Elixirはこれらを扱うために、`hd`と`tl`という2つの便利なメソッドを用意しています:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

前述した関数に加えて、リストを頭部と尾部に分けるのに[パターンマッチング](../pattern-matching/)やcons演算子(`|`)を使うこともできます。このパターンについては後のレッスンで取り上げます:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## タプル

タプルはリストに似ていますが、各要素はメモリ上に隣接して格納されます。このため、タプルの長さを得るのは高速ですが、修正を行うのは高コストとなります。というのも、新しいタプルは全ての要素がメモリにコピーされるからです。タプルは波括弧を用いて定義されます:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

タプルは関数から補助的な情報を返す仕組みとしてよく利用されます。この便利さは、パターンマッチングについて扱う時により明らかになるでしょう:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## キーワードリスト

キーワードとマップはElixirの連想コレクションです。Elixirでは、キーワードリストは最初の要素がアトムのタプルからなる特別なリストで、リストと同様の性能になります:

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

Elixir 1.2では変数をマップのキーにすることができます:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
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

マップのもう一つの興味深い特性は、マップの更新やアトムのキーへのアクセスのための固有の構文があることです:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
