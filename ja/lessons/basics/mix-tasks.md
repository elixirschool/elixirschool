---
version: 0.9.1
title: カスタムMixタスク
---

あなたのElixirプロジェクトのためのカスタムのMixタスクの作成

{% include toc.html %}

## 導入

カスタムのMixタスクを追加してElixirアプリケーションの機能を拡張したいと思うのは珍しいことではありません。私たちのプロジェクト特有のMixタスクを作成する方法を学ぶ前に、既存のタスクを見てみましょう:

```shell
$ mix phoenix.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

上のシェルコマンドから分かる通り、Phoenix Frameworkは新しいプロジェクトを作成するカスタムのMixタスクを持っています。私たちのプロジェクトのために、同様のものを作るにはどうすればいいでしょうか？幸いなことに、カスタムMixタスクの作成が可能であるだけでなく、Elixirはそれをとても簡単にしてくれます。

## セットアップ

基本的なMixアプリケーションをセットアップしましょう。

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

それでは、Mixが生成した **lib/hello.ex** に、"Hello, World!" を出力する簡単な関数を作成しましょう。

```elixir
defmodule Hello do
  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## カスタムMixタスク

カスタムのMixタスクを作成しましょう。新しいディレクトリとファイル、**hello/lib/mix/tasks/hello.ex** を作成してください。このファイルに以下の7行のElixirコードを追加しましょう。

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

defmodule文が`Mix.Tasks`と、そしてコマンドラインから呼び出したい名前から始まっているのに気付いてください。二行目では名前空間に`Mix.Task`ビヘイビアをもたらす`use Mix.Task`を実行しています。それから、今のところ全ての引数を無視するrun関数を宣言します。この関数の中では、`Hello`モジュールの`say`関数を呼び出しています。

## Mixタスクの実行

私たちのMixタスクを確かめてみましょう。アプリケーションのディレクトリにいる限り、これは上手くいきます。コマンドラインから`mix hello`を実行すると以下のようになるはずです:

```shell
$ mix hello
Hello, World!
```

Mixはデフォルトでかなり親切です。誰もが時々スペルミスをするのを知っているので、ファジーマッチングと呼ばれる技術を用いて候補を提案します:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

また、前に新しいモジュール属性である`@shortdoc`を紹介したのに気がついたでしょうか？これは`mix help`コマンドをターミナルで実行したときのように私たちのアプリケーションを使用するときに便利です。

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
