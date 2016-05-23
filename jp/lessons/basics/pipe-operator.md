---
layout: page
title: パイプライン演算子
category: basics
order: 6
lang: jp
---

パイプライン演算子(`|>`)はある式の結果を別の式に1つ目の引数として渡します。

{% include toc.html %}

## 導入

プログラミングは厄介になりえます。実際に、関数呼び出しの中に関数呼び出しを乱雑になるほど過度に埋め込むと把握するのがとても難しくなります。以下のネストされた関数を考えてみてください:

```elixir
foo(bar(baz(new_function(other_function()))))
```

ここでは、`other_function/1`の値を`new_function/1`に、`new_function/1`の値を`baz/1`に、`baz/1`の値を`bar/1`に、そして最後に`bar/1`の結果を`foo/1`に渡しています。
Elixirではパイプライン演算子を使うことによって構文的な混沌に対し現実的にアプローチします。
パイプライン演算子(`|>`)は *一つの式の結果を取り、それを渡します*。パイプライン演算子で書きなおされたコードスニペットを見なおしてみましょう。

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

パイプライン演算子は結果を左に取りそれを右側に渡します。

## 例

この例のセットのためにElixirのStringモジュールを使います。

- おおまかに文字列をトークン化する

```shell
iex> "Elixir rocks" |> String.split
["Elixir", "rocks"]
```

- 全てのトークンを大文字にする

```shell
iex> "Elixir rocks" |> String.split |> Enum.map( &String.upcase/1 )
["ELIXIR", "ROCKS"]
```

- 文字列の終わりを調べる

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## ベストプラクティス

関数のアリティが1より多いなら括弧を使うようにしてください。括弧の有無はElixirにおいてはたいした問題ではありませんが、あなたのコードを誤解するかもしれない他のプログラマにとっては問題です。もし2つ目の例で`Enum.map/2`から括弧を削除すると, 以下のように警告されます。

```shell
iex> "Elixir rocks" |> String.split |> Enum.map &String.upcase/1
iex: warning: you are piping into a function call without parentheses, which may be ambiguous. Please wrap the function you are piping into in parenthesis. For example:

foo 1 |> bar 2 |> baz 3

Should be written as:

foo(1) |> bar(2) |> baz(3)

["ELIXIR", "ROCKS"]
```
