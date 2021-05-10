---
version: 1.1.0
title: StreamData
---

[ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) のような例ベース(example-base)のユニットテストライブラリは、考えている通りにコードが動くことを保証できる素晴らしいツールです。
しかし、例ベースのユニットテストにはいくつかの問題があります:

* 限られた数の入力でのみテストをするため、エッジケースを見逃しやすい
* 要件を入念に考えることをせずにテストを書けてしまう
* 1つの関数を複数の例でテストする場合はとても冗長になりやすい

このレッスンでは、 [StreamData](https://github.com/whatyouhide/stream_data) を使うことでこれらの問題をどのように克服できるかを見ていきます。

{% include toc.html %}

## StreamDataとは?

[StreamData](https://github.com/whatyouhide/stream_data) はステートレスなプロパティベースのテストを実行するライブラリです。

StreamDataライブラリは、ランダムな値を使用して各テストを [デフォルトで100回](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options) 実行します。
テストが失敗すると、StreamDataはテストの失敗を引き起こす最小値へと入力値を [縮小しようとします](https://hexdocs.pm/stream_data/StreamData.html#module-shrinking) 。
これはコードのデバッグ時に役立ちます！
もし50個のリストによって関数が壊れ、リスト要素の1つのみに問題がある場合、StreamDataを使用することで問題のある要素を特定することができます。

このテストライブラリは2つのメインモジュールを持っています。 
[`StreamData`](https://hexdocs.pm/stream_data/StreamData.html) はランダムデータのストリームを生成します。
 [`ExUnitProperties`](https://hexdocs.pm/stream_data/ExUnitProperties.html) は、生成されたデータを用いた関数のテスト実行を可能にします。

入力値がわからないのに、関数のテストとして意味があるのか疑問に思うかもしれません。続きを読んでください！

## StreamDataのインストール

まずは、新しいMixプロジェクトを作成します。
必要に応じて [新しいプロジェクト](https://elixirschool.com/ja/lessons/basics/mix/#%E6%96%B0%E3%81%97%E3%81%84%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88) を参考にしてください。

続いて、 `mix.exs` にStreamDataを依存として追加します:

```elixir
defp deps do
  [{:stream_data, "~> x.y", only: :test}]
end
```

`x` と `y` はライブラリの [インストール手順](https://github.com/whatyouhide/stream_data#installation) に記載されたバージョンに従って置き換えてください。

次に、以下のコマンドをターミナルで実行してください:

```
mix deps.get
```

## StreamDataの使用

StreamDataの機能を説明するために、値を繰り返す簡単なユーティリティ関数をいくつか作ります。
文字列、リスト、タプルを複製する [`String.duplicate/2`](https://hexdocs.pm/elixir/String.html#duplicate/2) のような関数を作ると仮定しましょう。

### 文字列

まずは、文字列を複製する関数を作りましょう。
この関数にはどのような要件があるでしょうか？

1. 1つ目の引数は文字列である。
これが複製対象とする文字列である。
2. 2つ目の引数は正の整数である。
これは1つ目の引数を何回繰り返すかを表す。
3. 関数は文字列を返す。
この新しい文字列は、単にオリジナルの文字列を0回以上繰り返す文字列である。
4. オリジナルの文字列が空文字列であれば、返される文字列も空文字列となる
5. 2つ目の引数が `0` であれば、返される文字列は空文字列となる

関数の実行は、次のように行いたいものとします:

```elixir
Repeater.duplicate("a", 4)
# "aaaa"
```

Elixirはこの動作を行う `String.duplicate/2` 関数を持っているので、 `duplicate/2` は単にその関数をデリゲートするものにします:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end
end
```

通常のシナリオは [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) で簡単にテストすることができます。

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicate/2" do
    test "creates a new string, with the first argument duplicated a specified number of times" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end
  end
end
```

ただし、これは包括的なテストではありません。
2つ目の引数に `0` が渡された場合はどうなるべきでしょう？
1つ目の引数が空文字列の場合は何が返されるべきでしょう？
空文字列を繰り返すとはそもそも何を意味するのでしょう？
UTF-8の文字列はどのように扱うべきでしょう？
巨大なサイズの文字列でも関数は動作するのでしょうか？

エッジケースと巨大文字列の例を書くこともできますが、ここではStreamDataを使い、コードを増やすことなくこの関数をより厳密にテストできるかどうか見てみましょう。

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do

        assert ??? == Repeater.duplicate(str, times)
      end
    end
  end
end
```

これは何をしているのでしょう？

* `test` を [`property`](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109) で置き換えました。
これによってテストしているプロパティをドキュメント化できます。
* [`check/1`](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1) はテストで使用するデータのセットアップを可能にするマクロです。
* [`StreamData.string/2`](https://hexdocs.pm/stream_data/StreamData.html#string/2) はランダムな文字列を生成します。
`use ExUnitProperties` によって [StreamData関数をインポート](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109) しているので、 `string/2` のモジュール名を省略できます。
* `StreamData.integer/0` はランダムな整数を生成します。
* `times >= 0` はガード句のようなもので、テストで生成するランダムな整数が0以上となることを保証します。
[`SreamData.positive_integer/0`](https://hexdocs.pm/stream_data/StreamData.html#positive_integer/0) もあるのですが、 `0` も関数で受け入れ可能としているので、私たちが欲しいものとは少し違います。

`???` は単なる擬似コードです。
何をアサート(assert)するべきでしょうか？
ここでは次にように _書くこともできます_:

```elixir
assert String.duplicate(str, times) == Repeater.duplicate(str, times)
```

...ですが、これは単に関数の実装を使用しているだけで、意味がありません。
ここでは文字列の長さを検証するだけで、アサーションを緩めることができます:

```elixir
expected_length = String.length(str) * times
actual_length =
  str
  |> Repeater.duplicate(times)
  |> String.length()

assert actual_length == expected_length
```

これは無いよりはましですが、理想的ではありません。
このテストは、関数がランダムな文字列を正しい長さで生成してもパスしてしまいます。

本当にテストしたいのは次の2点です:

1. 関数が正しい長さの文字列を生成している
2. 最終的な文字列の中身はオリジナルの文字列が延々と繰り返されるものである

これは [プロパティの言い換え](https://www.propertesting.com/book_what_is_a_property.html#_alternate_wording_of_properties) の別の方法です。
#1を検証するコードは既に持っています。
#2を検証するために、最終的な文字列をオリジナルの文字列で分割し、0回以上の空文字列が繰り返されていることを検証しましょう。

```elixir
list =
  str
  |> Repeater.duplicate(times)
  |> String.split(str)

assert Enum.all?(list, &(&1 == ""))
```

これをアサーションと組み合わせてみましょう:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end
  end
end
```

元のテストと比較すると、StreamDataバージョンでは倍の長さになっていることがわかります。
しかし、元のテストにもっとテストを追加した場合は...

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicating a string" do
    test "duplicates the first argument a number of times equal to the second argument" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end

    test "returns an empty string if the first argument is an empty string" do
      assert "" == Repeater.duplicate("", 4)
    end

    test "returns an empty string if the second argument is zero" do
      assert "" == Repeater.duplicate("a", 0)
    end

    test "works with longer strings" do
      alphabet = "abcdefghijklmnopqrstuvwxyz"

      assert "#{alphabet}#{alphabet}" == Repeater.duplicate(alphabet, 2)
    end
  end
end
```

...StreamDataバージョンの方が実際には短いのです。
さらにStreamDataは、開発者が忘れるかもしれないエッジケースのテストもカバーしてくれます。

### リスト

それでは、リストを繰り返す関数を書いてみましょう。
関数には次のような動作を期待します:

```elixir
Repeater.duplicate([1, 2, 3], 3)
# [1, 2, 3, 1, 2, 3, 1, 2, 3]
```

正しいものの、少し非効率な実装は次の通りです:

```elixir
defmodule Repeater do
  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end
end
```

StreamDataのテストは次のようになるでしょう:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end
  end
end
```

ここでは `StreamData.list_of/1` と `StreamData.term/0` を使いました。これによって、どのような型にもなるランダムな長さのリストを生成します。

文字列の繰り返しにおけるプロパティベースのテストのように、新しいリストの長さ、およびソースとなるリストと `times` の結果を比較しています。
2つ目のアサーションについては少し説明します:

1. 新しいリストを複数のリストに分割し、それぞれが `list` と同じ数の要素を持つようにしています
2. 分割されたリストが `list` と同じであることを検証します

言い換えると、オリジナルのリストが最終的なリストに正しい数だけ存在し、 _それ以外の_ 要素が入っていないことを確認しています。

なぜ条件式を使ったのでしょう？
最初のアサーションと条件式の組み合わせは、オリジナルのリストと最終的なリストが共に空であることを示しているので、それ以上の比較が必要ないことがわかります。
さらに言えば、 `Enum.chunk_every/2` は2つ目の引数に正の整数を必要とします。

### タプル

最後に、タプルの要素を繰り返す関数を実装しましょう。
関数は次のように動作するべきです:

```elixir
Repeater.duplicate({:a, :b, :c}, 3)
# {:a, :b, :c, :a, :b, :c, :a, :b, :c}
```

これにアプローチできる1つの方法は、タプルをリストに変換し、リストを複製し、そしてデータ構造をタプルに戻すことです。

```elixir
defmodule Repeater do
  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

これをどのようにテストしましょう？
今回は、今までとは違う方法でアプローチしてみましょう。
文字列やリストでは、最終的なデータの長さと、データに含まれるコンテンツのないようをアサートしていました。
タプルでも同様のアプローチを使うことは可能ですが、テストコードはそこまで簡単にはならないかもしれません。

タプルに対して実行できる2つの操作シーケンスを考えてみましょう:

1. タプルに対して `Repeater.duplicate/2` を呼び、結果をリストへと変換する
2. タプルをリストに変換し、そのリストを `Repeater.duplicate/2` に渡す

これはScott Wlaschinが ["Different Paths, Same Destination"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/#different-paths-same-destination) と呼んでいるのパターンの応用です。
これら両方の操作シーケンスで同じ結果が得られることを期待します。
私たちのテストでこのアプローチを使ってみましょう。

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

## まとめ

これで、文字列、リスト要素、タプル要素を繰り返す3つの関数ができました。
プロパティベースのテストがいくつかあることで、実装が正しいことを強く確信できます。

これが最終的なアプリケーションの実装です:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end

  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end

  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

これがプロパティベースのテストです:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end

    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end

    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

ターミナルのコマンドラインで次のコマンドを入力するとテストを実行できます:

```
mix test
```

あなたが書いたStreamDataのテストはデフォルトで100回実行されるということを覚えておいてください。
加えて、いくつかのStreamDataのランダムデータは他のものよりも生成するのに時間がかかります。
これらの効果が累積して、このようなの種類のテストは例ベースのユニットテストよりも実行が遅くなります。

それでも、プロパティベースのテストは例ベースのユニットテストの良い補完になります。
様々な種類の入力をカバーする簡潔なテストを書くことができます。
テスト実行の間で状態を維持する必要がないのであれば、StreamDataはプロパティベースのテストを記述するための優れた構文を提供します。
