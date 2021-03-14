---
version: 1.0.2
title: Erlangとの相互運用
---

Erlang VM (BEAM)の上で開発することによって得られる利点の1つに、既にある大量のライブラリが利用できるという事があげられます。相互運用できることで、そうしたライブラリやErlangの標準ライブラリをElixirコードから活用することができます。このレッスンではサードパーティのErlangパッケージも併せ、標準ライブラリの関数へアクセスする方法を見ていきます。

{% include toc.html %}

## 標準ライブラリ

Erlangの豊富な標準ライブラリはアプリケーション内のどのElixirコードからもアクセスすることができます。Erlangモジュールは `:os` や `:timer` のように小文字のアトムで表されます。

`:timer.tc` を用いて、与えられた関数の実行時間を測定してみましょう:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

利用可能なモジュールの一覧は、 [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/) を参照してください。

## Erlangパッケージ

以前のレッスンでMixと依存関係の管理を扱いましたが、Erlangライブラリを組み込むのも同様の方法で動作します。万が一Erlangライブラリが [Hex](https://hex.pm) に上がっていない(プッシュされていない)場合には、代わりにgitリポジトリを参照することができます:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

これでErlangライブラリにアクセスできるようになりました:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## 注目すべき違い

Erlangを用いる方法について理解したので、Erlangとの相互運用に伴って生じる直感的ではない部分についても扱うべきでしょう。

### アトム

ErlangのアトムはElixirのものにとてもよく似ていますが、コロン(`:`)がありません。小文字とアンダースコアで表されます:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### 文字列

Elixirの文字列はUTF-8でエンコードされたバイナリを意味しています。Erlangでもstringはダブルクオートを使って表しますが、文字リストのことを指します:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

重要なので注記しておくと、古いErlangライブラリではバイナリに対応していないものが多いため、Elixirの文字列は文字リストに変換する必要があります。ありがたいことに、これは `to_charlist/1` 関数を用いて簡単に行うことができます:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### 変数

Erlangでは、変数は大文字で始まりバインドし直すことが出来ません。

Elixir:

```elixir
iex> x = 10
10

iex> x = 20
20

iex> x1 = x + 10
30
```

Erlang:

```erlang
1> X = 10.
10

2> X = 20.
** exception error: no match of right hand side value 20

3> X1 = X + 10.
20
```

おしまいです！ErlangをElixirアプリケーション内部から活用するのは簡単ですし、利用可能なライブラリの数が事実上倍になります。
