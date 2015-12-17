---
layout: page
title: 関数
category: basics
order: 6
lang: jp
---

Elixirや多くの関数型言語では、関数は第一級市民(≒ファーストクラスオブジェクト)です。Elixirにおける関数の種類について、それぞれどう異なっていて、どのように使うのかを学んでいきます。

## 目次

- [匿名関数](#section-1)
  - [&省略記法](#section-2)
- [パターンマッチング](#section-3)
- [名前付き関数](#section-4)
  - [プライベート関数](#section-5)
  - [ガード](#section-6)
  - [デフォルト引数](#section-7)

## 匿名関数

その名前が暗に示している通り、匿名関数は名前を持ちません。`Enum`のレッスンで見たように、匿名関数はたびたび他の関数に渡されます。Elixirで匿名関数を定義するには、`fn`と`end`のキーワードが必要です。これらの内側で、任意の数の引数と`->`で隔てられた関数の本体とを定義することができます。

基本的な例を見てみましょう:

```elixirre
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### &省略記法

匿名関数を利用するのはElixirでは日常茶飯事なので、そのための省略記法があります:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

おそらく見当が付いているでしょうが、省略記法では引数を`&1`、`&2`、`&3`などとして扱うことができます。

## パターンマッチング

Elixirではパターンマッチングは変数だけに限定されているわけではなく、次の項にあるように、関数へと適用することができます。

Elixirはパターンマッチングを用いて最初の引数がマッチするものを特定し、その関数を実行することができます:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## 名前付き関数

関数を名前付きで定義して後から呼び出せるようにすることができます。こうした名前付き関数はモジュール内部で`def`キーワードを用いて定義されます。モジュールについては次のレッスンで学習しますので、今のところ名前付き単体に着目しておきます。

モジュール内部で定義される関数は他のモジュールからも使用することができ、これはElixirでは特に有用な組み立て部品になります:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

関数本体が1行で済むなら、`do:`を使ってより短くすることができます:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

パターンマッチングの知識を身にまとったので、名前付き関数を使った再帰を探検しましょう:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_|t]), do: 1 + of(t)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### プライベート関数

他のモジュールから関数へアクセスさせたくない時にはプライベート関数を使うことができます。これは自身のモジュール内部からのみ呼び出せるようにするものです。Elixirでは`defp`を用いて定義することができます:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) undefined function: Greeter.phrase/0
    Greeter.phrase()
```

### ガード

[制御構造](/control-structures.md)レッスンでもガードについて少しだけ触れましたが、これを名前付き関数に適用する方法を見ていきます。Elixirはある関数にマッチするとそのガードを全てテストします。

以下の例では同じ名前を持つ2つの関数があります。ガードを頼りにして、引数の型に基づいてどちらを使うべきか決定します:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### デフォルト引数

引数にデフォルト値が欲しい場合、`引数 \\ デフォルト値`の記法を用います:

```elixir
defmodule Greeter do
  def hello(name, country \\ "en") do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

先ほどのガードの例をデフォルト引数と組み合わせると、問題にぶつかります。どんな風になるか見てみましょう:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country \\ "en") when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) def hello/2 has default values and multiple clauses, define a function head with the defaults
```

Elixirは複数のマッチング関数にデフォルト引数があるのを好みません。混乱の元になる可能性があります。これに対処するには、デフォルト引数付きの関数を先頭に追加します:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en")
  def hello(names, country) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country) when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
