---
layout: page
title: パターンマッチング
lang: jp
category: basics
order: 4
---

パターンマッチングはElixirの強力な部品で、単純な値やデータ構造、果ては関数でさえもマッチすることができます。このレッスンではパターンマッチングの使い方から見ていきます。

## 目次

- [マッチ演算子](#match-operator)
- [ピン演算子](#pin-operator)

## マッチ演算子

変化球への準備はいいですか？Elixirでは、`=`演算子は実際にはマッチ演算子です。このマッチ演算子を通して値を代入し、その後マッチさせることができます。見てみましょう:

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
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1|tail] = list
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

今学んだように、マッチ演算子は左辺に変数が含まれている時に代入操作を行います。この、変数を再び束縛するという挙動は望ましくない場合があります。そうした状況のために、`^`演算子があります:

_この例は公式のElixirの[Getting Started](http://elixir-lang.org/getting-started/pattern-matching.html)ガイドから直接持ってきています。_

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
