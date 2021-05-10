---
version: 1.7.0
title: Enum
---

コレクションを列挙していくために用いる一連のアルゴリズム。

{% include toc.html %}

## Enum

`Enum` モジュールはおよそ70個以上の関数を含んでいます。[前回のレッスン](../collections/)で学習した、タプルを除く全てのコレクションを列挙できます。

このレッスンは利用可能な関数のうち一部分しか取り上げませんが、実は全ての関数を自分自身で調べることができます。
IExでちょっとした実験をしてみましょう。

```elixir
iex
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

このように、 `Enum` モジュールが非常に多くの機能を持っていることは一目瞭然ですが、これには明確な理由があります。
列挙は関数型プログラミングの中核であり、Elixirが開発者にもたらす驚くべきその他の恩恵と基部で統合的に用意されているおかげです。

全ての関数を知りたい場合は公式ドキュメントの[`Enum`](https://hexdocs.pm/elixir/Enum.html)を参照してください。尚、列挙の遅延処理では[`Stream`](https://hexdocs.pm/elixir/Stream.html)モジュールを利用してください。

### all?

通常、 `all?/2` にはコレクションの要素に対して適用する関数を渡します。 `all?/2` の場合、コレクションの全体が `true` と評価されなければならず、そうでなければ `false` が返されます。

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

上記と違って、 `any?` は少なくとも1つの要素が `true` と評価された場合に `true` を返します:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

コレクションを小さなグループに分割する必要があるなら、恐らく `chunk_every/2` こそが探し求めている関数でしょう:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk_every/4` にはいくつかのオプションがありますが、ここでは触れないので[`この関数の公式ドキュメント`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4)を調べてください。

### chunk_by

要素数ではない他の何かでコレクションを分類したい場合には、 `chunk_by/2` 関数を使うことができます。この関数は列挙可能なコレクションと関数を引数に取り、その関数の戻り値が変化することによってコレクションの分類もそれに倣いながら開始されます。

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

時にはコレクションをグループに別けるだけでは充分ではない場合があります。 `nth` 毎のアイテムに対して何かの処理をしたい時には `map_every/3` が有用です。これは最初の要素にかならず触れます。

```elixir
# 関数を最初に適用してから3つ毎に同様の処理
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

新しい値を生成することなく、コレクションを反復する必要があるかもしれません。こうした場合には `each/2` を使います:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

**注記**: `each` 関数は `:ok` というアトムを返します。

### map

関数を各要素に適用して新しいコレクションを生み出すなら `map/2` 関数です:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

コレクションの中で最小の(`min/1`)値を探します:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` も同様ですが、コレクションが空であった場合にあらかじめ最小値を生成する為の関数を渡すことができます。

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

コレクションの中で最大の(`max/1`)値を返します:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` と `max/1` の関係は `min/2` と `min/1` の関係と同じです:

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### filter

`filter/2` を使うと、与えられた関数によって `true` と評価された要素だけを得る為に、それ以外の要素を取り除くことができます。

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

`reduce/3` を用いることで、コレクションをまとめ、そこから単一の値へと抽出することができます。この処理には任意のアキュムレータを関数に渡します。アキュムレータとは、前の演算結果を一時的に保持するものです(この例では `10`)。アキュムレータが与えられない場合にはコレクションの最初の要素が用いられます。

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

コレクションのソートに、関数を1つだけでなく2つ使うと容易になります。

`sort/1` はソートの順序を決める為にErlangの [Term優先順位](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) を使います:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

一方で `sort/2` には、自分で順序を決める為の関数を渡すことができます:

```elixir
# ソート関数あり
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# なし
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

便宜上, `sort/2` に `:asc` または `:desc` をソート関数として渡すことができます：

```elixir
Enum.sort([2, 3, 1], :desc)
[3, 2, 1]
```

### uniq

`uniq/1` を使ってコレクションから重複した要素を取り除くことができます:

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

### uniq_by

`uniq_by/2` もコレクションから重複した要素を削除しますが、ユニークかどうか比較を行う関数を渡せます。

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```

### キャプチャ演算子（&）を使用したEnum
ElixirのEnumモジュール内の多くの関数は、渡されるEnum型のオブジェクトを処理するための引数として無名関数を取ります。

これらの無名関数は、多くの場合、キャプチャ演算子（&）を使用して省略形で記述されます。

Enumモジュールを使用してキャプチャ演算子を実装する方法を示すいくつかの例を次に示します。
各バージョンは機能的に同等です。

#### 無名関数でのキャプチャ演算子の使用

以下は、無名関数を `Enum.map/2` に渡すときの標準構文の典型的な例です。

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

次に、キャプチャ演算子（&）を実装します。数値のリスト（[1,2,3]）の各要素をキャプチャし、マッピング関数を通過するときに各要素を変数&1に割り当てます。

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

これをさらにリファクタリングして、キャプチャ演算子を特徴とする以前の無名関数を変数に割り当て、 `Enum.map/2` 関数から呼び出すことができます。

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

#### 名前付き関数でのキャプチャ演算子の使用
まず、名前付き関数を作成し、 `Enum.map/2` で定義されている無名関数内で呼び出します。

```elixir
defmodule Adding do
  def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

次に、キャプチャ演算子を使用するようにリファクタリングできます。

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1))
[4, 5, 6]
```

最も簡潔な構文の場合、変数を明示的にキャプチャせずに、名前付き関数を直接呼び出すことができます。

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1)
[4, 5, 6]
```
