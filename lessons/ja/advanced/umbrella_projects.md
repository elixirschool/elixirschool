%{
  version: "1.0.1",
  title: "アンブレラプロジェクト",
  excerpt: """
  プロジェクトが大きく、本当に大きくなることが時々あります。Mixビルドツールはプロジェクトの成長に合わせて、コードを複数のアプリケーションに分割してElixirプロジェクトをより管理しやすくする方法を提供します。
  """
}
---

## 導入

アンブレラプロジェクト(umbrella project)を作るには普通のMixプロジェクトを始めるように、しかし `--umbrella` フラグを渡してプロジェクトを作成します。ここでは例として機械学習ツールキットの _シェル_ を作ります。なぜ機械学習ツールキットなのでしょうか？機械学習ツールキットは様々な異なる学習アルゴリズムやユーティリティ関数から成るからです。

```shell
$ mix new machine_learning_toolkit --umbrella

* creating .gitignore
* creating README.md
* creating mix.exs
* creating apps
* creating config
* creating config/config.exs

Your umbrella project was created successfully.
Inside your project, you will find an apps/ directory
where you can create and host many apps:

    cd machine_learning_toolkit
    cd apps
    mix new my_app

Commands like "mix compile" and "mix test" when executed
in the umbrella project root will automatically run
for each application in the apps/ directory.
```

シェルコマンドから分かる通り、Mixは2つのディレクトリのみで構成される小さい骨組みだけのプロジェクトを作ります:

- `apps/` - サブプロジェクト(子プロジェクト)を配置する場所
- `config/` - アンブレラプロジェクトの設定を配置する場所

## 子プロジェクト

プロジェクトの `machine_learning_toolkit/apps` ディレクトリに移動し、Mixでこのように通常のプロジェクトを3つ作ります:

```shell
$ mix new utilities

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/utilities.ex
* creating test
* creating test/test_helper.exs
* creating test/utilities_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd utilities
    mix test

Run "mix help" for more commands.


$ mix new datasets

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/datasets.ex
* creating test
* creating test/test_helper.exs
* creating test/datasets_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd datasets
    mix test

Run "mix help" for more commands.

$ mix new svm

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/svm.ex
* creating test
* creating test/test_helper.exs
* creating test/svm_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd svm
    mix test

Run "mix help" for more commands.
```

プロジェクトのディレクトリ構造はこのようになっているはずです:

```shell
$ tree
.
├──README.md
├──apps
│   ├──datasets
│   │   ├──README.md
│   │   ├──config
│   │   │   └──config.exs
│   │   ├──lib
│   │   │   └──datasets.ex
│   │   ├──mix.exs
│   │   └──test
│   │       ├──datasets_test.exs
│   │       └──test_helper.exs
│   ├──svm
│   │   ├──README.md
│   │   ├──config
│   │   │   └──config.exs
│   │   ├──lib
│   │   │   └──svm.ex
│   │   ├──mix.exs
│   │   └──test
│   │       ├──svm_test.exs
│   │       └──test_helper.exs
│   └──utilities
│       ├──README.md
│       ├──config
│       │   └──config.exs
│       ├──lib
│       │   └──utilities.ex
│       ├──mix.exs
│       └──test
│           ├──test_helper.exs
│           └──utilities_test.exs
├──config
│   └──config.exs
└──mix.exs
```

アンブレラプロジェクトのルートディレクトリに戻ると、コンパイルのような代表的なコマンドが全て使えることが分かります。サブプロジェクトは通常のプロジェクトなので、サブプロジェクトのディレクトリに移動すれば通常通りMixが許す限り全てのことが可能です。

```bash
$ mix compile

==> svm
Compiled lib/svm.ex
Generated svm app

==> datasets
Compiled lib/datasets.ex
Generated datasets app

==> utilities
Compiled lib/utilities.ex
Generated utilities app

Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
```

## IEx

もしかしたら、アプリケーションとやりとりする方法がアンブレラプロジェクトでは少し異なるのではないか、と思っているかもしれません。信じるにしろ信じないにしろ、それは間違いです！トップレベルディレクトリに移動し、 `iex -S mix` でIExを起動すると通常通りプロジェクト全てとやりとりできます。簡単な例として `apps/datasets/lib/datasets.ex` の内容を変更してみましょう。

```elixir
defmodule Datasets do
  def hello do
    IO.puts("Hello, I'm the datasets")
  end
end
```

```shell
$ iex -S mix
Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

==> datasets
Compiled lib/datasets.ex
Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)

iex> Datasets.hello
:world
```
