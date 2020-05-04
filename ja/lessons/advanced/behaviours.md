---
version: 1.0.1
title: ビヘイビア
---

前の章では仕様と型について学びました。この章では、その仕様を実装するようにモジュールに要求する方法を学びます。Elixirでは、この機能はビヘイビア(振る舞い)と呼ばれます。

{% include toc.html %}

## 用途

公開APIをモジュール間で共有したい場合があります。Elixirでは、その手段としてビヘイビアが用意されています。ビヘイビアには主に次の2つの役割があります。

- 実装しなければならない関数一式を定義すること
- その関数一式が実際に実装されているかチェックすること

ElixirにはGenServerのような組み込みのビヘイビアがいくつもありますが、この章では我々自身で作ってみましょう。

## ビヘイビアを定義する

理解を深めるために、ワーカーモジュール用のビヘイビアを実装してみましょう。ワーカーには2個の関数 `init/1` と `perform/2` が実装されることが期待されます。

これを達成するため、 `@spec` と文法の似た `@callback` ディレクティブを使い、 **要求される** 関数を定義します。マクロの場合には `@macrocallback` が使えます。 `init/1` と `perform/2` をワーカー用に指定してみましょう。

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

これで `init/1` は任意の値を受け取り、 `{:ok, state}` または `{:error, reason}` というタプルを返す関数として定義されました。これは至って標準的な初期化です。 `perform/2` 関数はワーカー用の引数と初期化時のステートを受け取り、GenServerと同じように `{:ok, result, state}` または `{:error, reason, state}` を返すことが期待されます。

## ビヘイビアを利用する

我々の定義したビヘイビアを使って、さまざまなモジュールに同じ公開APIを共有できます。ビヘイビアをモジュールに追加するのは簡単で、 `@behaviour` 属性を使います。

新しいビヘイビアを使って、リモートファイルをダウンロードしてローカルに保存するモジュールのタスクを作ってみましょう。

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

複数のファイルを圧縮するワーカーはどうでしょう？これも可能です。

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

これらは動作が異なる一方で、公開APIは同じです。利用するコードは、これらのモジュールをが期待通りに動くことを分かってやりとりできます。これによって、我々は異なるタスクを実行するが同じ公開APIに準拠するワーカーをいくつでも作れます。

もしビヘイビアを追加しながら要求されたすべての関数を実装してない場合、コンパイル時に警告されます。この動作を見るために `Example.Compressor` のコードから `init/1` を削除してみましょう。

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

コンパイルしてみると、次のような警告が表示されます。

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

以上です。これでビヘイビアを作成して共有できるようになりました。
