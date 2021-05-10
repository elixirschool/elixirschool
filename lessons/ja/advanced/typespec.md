---
version: 1.0.3
title: 仕様と型
---

このレッスンでは `@spec` と `@type` の文法について学びます。最初の `@spec` はツールによって解析できるドキュメントを書くための文法をより完全にするものです。二番目の `@type` はコードをより読みやすく理解しやすいものにする手助けをしてくれます。

{% include toc.html %}

## イントロダクション

あなたが自分で書いた関数のインターフェイスを記述したいというのはそんなに珍しいことではないでしょう。もちろん [@docアノテーション](../../basics/documentation)を使うこともできますが、他の開発者にとってそれはコンパイル時にチェックされない単なる情報に過ぎません。この目的のために、Elixirには `@spec` アノテーションがあり、コンパイラによってチェックされる関数の仕様を記述することができます。

しかしながらいくつかのケースにおいて仕様は相当に大きくなったり複雑になったりしがちです。複雑さを少なくしたいのなら独自の型の定義を導入したくなるかもしれません。そのためにElixirには `@type` アノテーションがあります。一方でElixirは結局のところ動的言語です。このことは型に関する情報は全てコンパイラには無視されますが、別のツールによって使われるということを意味します。

## 仕様(specification)

もし、あなたがJavaの経験をお持ちなら仕様を `interface` だと考えてよいでしょう。仕様は関数の取るべき引数と戻り値の型を定義します。

入出力の型を定義するには `@spec` ディレクティブを関数定義の直前に置いて `引数` として関数名、引数の型のリスト、そして `::` の後に戻り値の型を描きます。

例を見てみましょう:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3]
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
end
```

この関数を呼べば有効な結果が返って万事OKそう、に見えますが、関数 `Enum.sum` は `integer` ではなく `number` を返します。バグの元になるところでした! コードを静的解析してこのようなバグを見つける手助けをしてくれるDialyzerのようなツールもあります。それについてはまた別のレッスンで。

## 独自の型

仕様を書くのはよいことですが時として我々が作った関数は単なる数やコレクションよりも複雑なデータ構造を使って動作します。そのような関数を `@spec` で定義すると他の開発者が理解する、あるいは変更することが極めて難しくなってしまうかもしれません。関数は数多くの引数をとり複雑なデータを返さなければならないことがあります。長い引数のリストは潜在的にコードの中でヤバそうな匂いを漂わせるものです。RubyやJavaのようなオブジェクト指向言語ではこの問題を解決するのを助けるために容易にクラスを定義できます。Elixirにはクラスはありません。それは型を定義することで簡単に言語仕様が拡張できるからです。

Elixirには何もせずとも最初から `integer` や `pid` といった基本的な型があります。全ての利用できる型の一覧は[公式ドキュメント](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax)にあります。

### 独自の型を定義する

では先ほどの `sum_times` 関数を変更していくつか引数を新しく追加しましょう。

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

`Examples` というモジュールの中に `first` と `last` というフィールドを持った構造体を導入しました。これは `Range` モジュールの構造体の簡易版です。 `構造体` については[モジュール](../../basics/modules/#structs)で述べます。さて、 `Examples` 構造体の仕様をあちこちで書かなくてはならなくなったとしましょう。長くて複雑な仕様を書くのは面倒ですしバグの元になりかねません。この問題を解決するのが `@type` です。

Elixirには3つの型の指定方法があります:

- `@type` - 単純な、公開された(public)型です。型の内部の構造は公開されます。
- `@typep` - 型は非公開(private)で定義されたモジュール内部でのみ使えます。
- `@opaque` - 型は公開されますが内部の構造は非公開です。

では我々の型を定義してみましょう:

```elixir
defmodule Examples do
  defstruct first: nil, last: nil

  @type t(first, last) :: %Examples{first: first, last: last}

  @type t :: %Examples{first: integer, last: integer}
end
```

これで`t(first, last)`型、つまり構造体 `%Examples{first: first, last: last}` を表すものが定義できました。ここで型には引数を取ることができることが見て取れますが、型 `t` について今度は構造体 `%Examples{first: integer, last: integer}` を表すようにも定義しています。

この違いは何でしょう? 最初のものは構造体 `Examples` で2つの、任意の型になれるキーを持つものを表しています。2番めのものは構造体でキーがどちらも `integer` であるものを表しています。即ち以下のコードは:

```elixir
@spec sum_times(integer, Examples.t()) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

以下のコードと等価であるということを意味します。

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
  for i <- params.first..params.last do
    i
  end
  |> Enum.map(fn el -> el * a end)
  |> Enum.sum()
  |> round
end
```

### 型ドキュメント

最後にお話しなくてはいけない項目はどのように我々が定義した型をドキュメントにするかということです。我々は既に[ドキュメント](../../basics/documentation)のレッスンによって、関数やモジュールに関するドキュメントを作成するためには `@doc` 及び `@moduledoc` アノテーションがあることを知っていますね。型をドキュメント化するには `@typedoc` を使います:

```elixir
defmodule Examples do
  @typedoc """
      Type that represents Examples struct with :first as integer and :last as integer.
      Examplesを表す型は:firstを整数型、:lastを整数型として取る構造体を表す。
  """
  @type t :: %Examples{first: integer, last: integer}
end
```

命令 `@typedoc` は `@doc` 及び `@moduledoc` と同じようなものです。
