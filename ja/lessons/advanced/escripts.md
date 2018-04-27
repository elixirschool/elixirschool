---
version: 1.0.1
title: 実行ファイル
---

Elixir で実行ファイルをビルドするには escript を利用します。 escript は Erlang がインストールされているあらゆるシステム上で動作する実行ファイルを生み出します。

{% include toc.html %}

## 始めに

escript で実行ファイルを作るために、必要な事はほんの少ししかありません。 `main/1` 関数を実装し、 Mixfile を更新するというものです。

実行ファイルのエントリポイント(最初に実行する位置)として扱うモジュールを作成することから始めましょう。ここが `main/1` を実装するところになります:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

次に Mixfile を更新して、 `:main_module` を一緒に指定した `:escript` オプションをプロジェクトに組み込みます:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## 引数の解析

アプリケーションのセットアップが済んだら、コマンドライン引数の解析へと移ります。 Elixir の `OptionParser.parse/2` と `:switches` オプションを用いて、私たちのフラグが真理値であることを示します:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## ビルド

escript を用いるようにアプリケーションを設定し終えたら、実行ファイルのビルドは Mix のおかげで楽勝です:

```elixir
$ mix escript.build
```

試しに実行してみましょう:

```elixir
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

おしまいです。 escript を使って Elixir の最初の実行ファイルをビルドできました。
