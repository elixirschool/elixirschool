---
version: 1.0.1
title: パイプライン演算子
---

パイプライン演算子(`|>`)はある式の結果を別の式に1つ目の引数として渡します。

{% include toc.html %}

## 導入

プログラミングは厄介になりえます。実際とても厄介なことに、関数呼び出しを深くしすぎると把握するのがとても難しくなります。以下のネストされた関数を考えてみてください:

```elixir
foo(bar(baz(new_function(other_function()))))
```

ここでは、 `other_function/0` の値を `new_function/1` に、 `new_function/1` の値を `baz/1` に、 `baz/1` の値を `bar/1` に、そして最後に `bar/1` の結果を `foo/1` に渡しています。
Elixirではパイプライン演算子を使うことによって構文的な混沌に対し現実的にアプローチします。
パイプライン演算子(`|>`)は _一つの式の結果を取り、それを渡します_ 。先ほどのコードスニペットをパイプライン演算子で書き直すとどうなるか、見てみましょう。

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

パイプライン演算子は結果を左に取りそれを右側に渡します。

## 例

この例のセットのためにElixirのStringモジュールを使います。

- おおまかに文字列をトークン化する

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- 全てのトークンを大文字にする

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- 文字列の終わりを調べる

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## ベストプラクティス

関数のアリティが1より多いなら括弧を使うようにしてください。括弧の有無はElixirにおいてはたいした問題ではありませんが、あなたのコードを誤解するかもしれない他のプログラマにとっては問題です。もし3つ目の例で `String.ends_with?/2` から括弧を削除すると, 以下のように警告されます。

```elixir
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
