%{
  version: "1.2.0",
  title: "テスト",
  excerpt: """
  テストはソフトウェア開発の重要な一部です。このレッスンではElixirコードをExUnitを用いてテストする方法と、そのためのベストプラクティスをいくつか見てきます。
  """
}
---

## ExUnit

Elixirに組み込まれているテストフレームワークはExUnitといい、コードを全面的にテストするのに必要なもの全てを含んでいます。ExUnitを見ていく前に重要なので言及しておきますが、テストはElixirスクリプトとして実装されるため、 `.exs` をファイルの拡張子として使用する必要があります。テストを走らせる前にExUnitを `ExUnit.start()` で開始する必要があり、これは通常 `test/test_helper.exs` 内で行われます。

プロジェクトを生成した時点で、mixは単純なテストを作ってくれていて、 `test/example_test.exs` で見ることができます:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

プロジェクトのテストは `mix test` で走らせることができます。実行すると下記のような出力が得られるでしょう:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

テスト出力に2つのドットがあるのはなぜでしょうか？ `test/example_test.exs` でのテストに加えて、Mixは `lib/example.ex` でdoctestも生成したからです。

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

以前からテストを書いているのでしたら、 `assert` をご存知でしょう。あるいは、 `should` や `expect` が `assert` の役割を担っているフレームワークもあります。

`assert` マクロは式が真であることをテストするために使います。真ではない場合は、エラーが発生してテストが失敗します。失敗するのを試すために、先ほどの例を変更して `mix test` を実行してみましょう:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

今度は先ほどとはかなり異なった形の出力が得られるはずです:

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

ExUnitは失敗したアサーションがどこにあるか、期待された値と実際の値が何であったのかを、正確に教えてくれます。

### refute

`refute` は `assert` の、 `if` に対する `unless` のようなものです。文が常に偽となることを確かめたい場合には `refute` を使ってください。

### assert_raise

たまに、エラーが発生することをアサートする必要があるかもしれませんが、 `assert_raise` で行うことができます。Plugに関するレッスンで `assert_raise` の例を見ていきます。

### assert_receive

Elixirでは、アプリケーションは複数のアクターとプロセスによって構成されお互いメッセージを送るので、こういうメッセージの転送をテストしたいと思うはずです。ExUnitは自分のプロセスの内部で実行されるため、他のプロセスと同様にメッセージを受け取れます。そしてそれを `assert_received` マクロで宣言できます。

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` はメッセージを待ちませんが、 `assert_receive` はタイムアウトを指定できます。

### capture_ioとcapture_log

`ExUnit.CaptureIO` を利用して、元のアプリケーションに変更を加えずにアプリケーションの出力をキャッチャーできます。出力を生成する関数を渡してみましょう:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` は `Logger` への出力をキャッチャーします。

## テストのセットアップ

いくつかの場合に、テスト前にセットアップを行う必要があるかもしれません。セットアップを行うために、 `setup` と `setup_all` マクロを使うことができます。 `setup` は各テストの前、 `setup_all` は全体のテストの前に一度だけ実行されます。どちらも `{:ok, state}` のタプルを返すことが期待されていて、stateはテスト内で利用可能です。

この例として、 `setup_all` を使うようにコードを変更します:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## モック

Elixirでのモックに対する単純な解答は、使うな、です。本能のままにモックへと手を伸ばしているかもしれませんが、Elixirのコミュニティや正当な理由からはとても推奨されていないものです。

詳しい議論はこの[素晴らしい記事](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/)で見れます。掻い摘むと、テストのために依存性をモックにするより、明示的にインターフェース(ビヘイビア)を定義するほうがアプリケーションの外側のコードやクライアントコードのテストのためにモックを利用する際に大きいな利点があります。

アプリケーションコードの実装を変えたい時、好まれる方法はモジュールを引数として渡して、デフォルト値を使用することです。これが使えないのならビルトイン設定仕組みを使用してください。モックを実装するために、特別なモックライブラリーは必要ありません。ビヘイビアとコールバックで充分です。
