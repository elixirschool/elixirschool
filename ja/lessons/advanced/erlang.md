---
version: 1.0.1
title: Erlang との相互運用
---

Erlang VM (BEAM)の上で開発することによって得られる利点の1つに、既にある大量のライブラリが利用できるという事があげられます。相互運用できることで、そうしたライブラリや Erlang の標準ライブラリを Elixir コードから活用することができます。このレッスンではサードパーティの Erlang パッケージも併せ、標準ライブラリの関数へアクセスする方法を見ていきます。

{% include toc.html %}

## 標準ライブラリ

Erlang の豊富な標準ライブラリはアプリケーション内のどの Elixir コードからもアクセスすることができます。 Erlang モジュールは `:os` や `:timer` のように小文字のアトムで表されます。

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

## Erlang パッケージ

以前のレッスンで Mix と依存関係の管理を扱いましたが、 Erlang ライブラリを組み込むのも同様の方法で動作します。万が一 Erlang ライブラリが [Hex](https://hex.pm) に上がっていない(プッシュされていない)場合には、代わりに git リポジトリを参照することができます:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

これで Erlang ライブラリにアクセスできるようになりました:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## 注目すべき違い

Erlang を用いる方法について理解したので、 Erlang との相互運用に伴って生じる直感的ではない部分についても扱うべきでしょう。

### アトム

Erlang のアトムは Elixir のものにとてもよく似ていますが、コロン(`:`)がありません。小文字とアンダースコアで表されます:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### 文字列

Elixir の文字列は UTF-8 でエンコードされたバイナリを意味しています。 Erlang でもstringはダブルクオートを使って表しますが、文字リストのことを指します:

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

重要なので注記しておくと、古い Erlang ライブラリではバイナリに対応していないものが多いため、 Elixir の文字列は文字リストに変換する必要があります。ありがたいことに、これは `to_charlist/1` 関数を用いて簡単に行うことができます:

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

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

おしまいです！  Erlang を Elixir アプリケーション内部から活用するのは簡単ですし、利用可能なライブラリの数が事実上倍になります。
