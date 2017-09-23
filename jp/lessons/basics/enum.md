---
version: 0.9.0
title: Enum
---

コレクションを列挙していくために用いる一連のアルゴリズム。

{% include toc.html %}

## Enum

`Enum`モジュールは前回のレッスンで学習したコレクションを取り扱うための、およそ100の関数を含んでいます。

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
リストなどの列挙は関数型プログラミングの核で、信じられないほど有用です。
おまけにリストなどの列挙は、以前見たような言語レベルでサポートされているドキュメントといった、Elixirの他の要素と共に活用することで、信じられないような効果をもたらします。

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

### chunk_every/2

コレクションを小さなグループに分割する必要があるなら、恐らく`chunk_every/2`こそが探し求めている関数でしょう:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

`chunk_every/2`にはいくつかのオプションがありますが、ここでは触れませんので、詳しく学びたい場合には公式ドキュメントの[`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4)を調べてみてください。

### chunk_by

コレクションを要素数ではない何か他のものでグループにする必要がある場合には、`chunk_by/2`メソッドを使うことができます。この関数は列挙可能な値と関数を引数に取り、その関数の返り値が変わると新しいグループが始まります:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### each

新しい値を生成することなく、コレクションを反復する必要があるかもしれません。こうした場合には`each`を使います:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__注記__: `each`メソッドは`:ok`というアトムを返します。

### map

関数を各要素に適用して新しいコレクションを生み出すには、`map`関数に目を向けましょう:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

コレクションの中で最小の(`min`)値を探します:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

コレクションの中で最大の(`max`)値を返します:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

`reduce`を用いることで、コレクションをまとめ、そこから単一の値を抽出することができます。この処理を実行するにはオプションとしてアキュムレータ(積算器。この例では`10`)を関数に渡しますが、アキュムレータが与えられない場合にはコレクションの最初の値が用いられます:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

コレクションをソートするのは1つ、ではなく、2つある`sort`関数を使えば簡単です。1つ目の選択として用意されているのはElixirのterm orderingを使ってソート順序を決めるというものです:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

もう1つの選択肢はソート関数を与えてあげるというものです:

```elixir
# ソート関数あり
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# なし
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

`uniq`を使ってコレクションから重複した要素を取り除くことができます:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
