---
version: 1.4.0
title: Enum
redirect_from:
  - /jp/lessons/basics/enum/
---

コレクションを列挙していくために用いる一連のアルゴリズム。

{% include toc.html %}

## Enum

`Enum`モジュールはおよそ70個以上の関数を含んでいます。[前回のレッスン](../collections/)で学習した、タブルを除外した全てのコレクションは全て列挙可能です。

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

これを見れば`Enum`モジュールに大量の機能があるのが明らかで、これには明確な理由があります。
列挙は関数型プログラミングの核で、信じられないほど有用です。
おまけに列挙は、以前見たような言語レベルでサポートされているドキュメントといった、Elixirの他の要素と共に活用することで、信じられないような効果をもたらします。

全ての関数を知りたい場合は公式ドキュメントの[`Enum`](https://hexdocs.pm/elixir/Enum.html)を参照してください。尚、列挙の遅延処理では[`Stream`](https://hexdocs.pm/elixir/Stream.html)モジュールを利用してください。

### all?

`all?`を使うとき、そして`Enum`の多くのケースで、コレクションの要素に適用する関数を渡します。`all?`の場合には、コレクション全体でこの関数は`true`と評価されなければならず、これを満たさない場合は`false`が返ります。

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

上記と違って、`any?`は少なくとも1つの要素が`true`と評価された場合に`true`を返します:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

コレクションを小さなグループに分割する必要があるなら、恐らく`chunk_every/2`こそが探し求めている関数でしょう:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk_every/4`にはいくつかのオプションがありますが、ここでは触れないので[`この関数の公式ドキュメント`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4)を調べてください。

### chunk_by

コレクションを要素数ではない何か他のものでグループにする必要がある場合には、`chunk_by/2`関数を使うことができます。この関数は列挙可能な値と関数を引数に取り、その関数の返り値が変わると新しいグループが始まります:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

時にコレクションをグループに別けるだけでは充分ではない場合があります。`nth`毎のアイテムに対して何かの処理をしたい時には`map_every/3`が有用です。これは最初の要素にかならず触れます。

```elixir
# 毎回3個を飛び越えながら関数を呼び出す
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

新しい値を生成することなく、コレクションを反復する必要があるかもしれません。こうした場合には`each/2`を使います:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__注記__: `each`関数は`:ok`というアトムを返します。

### map

関数を各要素に適用して新しいコレクションを生み出すには、`map`関数に目を向けましょう:

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

`min/2`も同様ですが、コレクションが空である場合、最小値を生成するための関数を渡します:

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

`max/2`と`max/1`の関係は`min/2`と`min/1`の関係と同じです:

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### filter

`filter/2`を使用するとコレクションで与えられた関数で評価して `true` になる要素のみを返すことができます。

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

`reduce/3`を用いることで、コレクションをまとめ、そこから単一の値を抽出することができます。この処理を実行するにはオプションとしてアキュムレータ(積算器。この例では`10`)を関数に渡しますが、アキュムレータが与えられない場合にはコレクションの最初の値が用いられます:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

コレクションをソートするのは1つではなく、2つあるソート関数を使えば簡単です。

`sort/1`はErlangのterm orderingを使ってソート順序を決めるというものです:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

その反面、`sort/2`には順序決めに使う関数を渡すことができます:

```elixir
# ソート関数あり
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# なし
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

`uniq_by/2`を使ってコレクションから重複した要素を取り除くことができます:

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```
