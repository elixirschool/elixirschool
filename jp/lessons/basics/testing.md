---
version: 0.9.0
title: テスト
---

テストはソフトウェア開発の重要な一部です。このレッスンではElixirコードをExUnitを用いてテストする方法と、そのためのベストプラクティスをいくつか見てきます。

{% include toc.html %}

## ExUnit

Elixirに組み込まれているテストフレームワークはExUnitといい、コードを全面的にテストするのに必要なもの全てを含んでいます。ExUnitを見ていく前に重要なので言及しておきますが、テストはElixirスクリプトとして実装されるため、`.exs`をファイルの拡張子として使用する必要があります。テストを走らせる前にExUnitを`ExUnit.start()`で開始する必要があり、これは通常`test/test_helper.exs`内で行われます。

プロジェクトを生成した時点で、mixは単純なテストを作ってくれていて、`test/example_test.exs`で見ることができます:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

プロジェクトのテストは`mix test`で走らせることができます。実行すると下記のような出力が得られるでしょう:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

以前からテストを書いているのでしたら、`assert`をご存知でしょう。あるいは、`should`や`expect`が`assert`の役割を担っているフレームワークもあります。

`assert`マクロは式が真であることをテストするために使います。真ではない場合は、エラーが発生してテストが失敗します。失敗するのを試すために、先ほどの例を変更して`mix test`を実行してみましょう:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

今度は先ほどとはかなり異なった形の出力が得られるはずです:

```shell
  1) test the truth (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnitは失敗したアサーションがどこにあるか、期待された値と実際の値が何であったのかを、正確に教えてくれます。

### refute

`refute`は`assert`の、`if`に対する`unless`のようなものです。文が常に偽となることを確かめたい場合には`refute`を使ってください。

### assert_raise

たまに、エラーが発生することをアサートする必要があるかもしれませんが、`assert_raise`で行うことができます。Plugに関するレッスンで`assert_raise`の例を見ていきます。

## テストのセットアップ

いくつかの場合に、テスト前にセットアップを行う必要があるかもしれません。セットアップを行うために、`setup`と`setup_all`マクロを使うことができます。`setup`は各テストの前、`setup_all`は全体のテストの前に一度だけ実行されます。どちらも`{:ok, state}`のタプルを返すことが期待されていて、stateはテスト内で利用可能です。

この例として、`setup_all`を使うようにコードを変更します:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

## モック

Elixirでのモックに対する単純な解答は、使うな、です。本能のままにモックへと手を伸ばしているかもしれませんが、Elixirのコミュニティや正当な理由からはとても推奨されていないものです。良いデザインの原則に従えば、その結果書かれるコードは個別の部品としてテストしやすいものになるでしょう。

衝動を抑えましょう。
