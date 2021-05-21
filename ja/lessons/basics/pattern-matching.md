---
version: 1.0.2
title: パターンマッチング
---

パターンマッチングはElixirの強力な部品で、単純な値やデータ構造、果ては関数でさえもマッチすることができます。
このレッスンではパターンマッチングの使い方から見ていきます。

{% include toc.html %}

## マッチ演算子

変化球への準備はいいですか？Elixirでは、 `=` 演算子は実際には代数学での等号に値するマッチ演算子です。このマッチ演算子を通して値を代入し、その後マッチさせることができます。マッチングに成功すると方程式の結果を返します。失敗する場合はエラーを投げます。見てみましょう:

```elixir
iex> x = 1
1
```

では、いくつか単純なマッチングを試してみましょう:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

知っているコレクションで、いくつか試してみましょう:

```elixir
# リスト
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# タプル
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## ピン演算子

マッチ演算子は左辺に変数が含まれている時に代入操作を行います。
この変数を再び束縛するという挙動は望ましくない場合があります。
そうした状況のために、ピン演算子(`^`)があります。

ピン演算子で変数を固定すると、新しく再束縛するのではなく既存の値とマッチします。
これがどのような働きをするのか見てみましょう:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2ではマップのキーや関数の節でのピン演算子がサポートされました。

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

関数の節でのピン演算子の例:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
iex> greeting
"Hello"
```

`"Mornin'"` の例では、 `greeting` から `"Mornin'"` への再代入が発生するのは関数の中だけという点に注意しましょう。 `greeting` の外側では `"Hello"` のままとなっています。
