%{
  version: "2.0.1",
  title: "Distillery (基本)",
  excerpt: """
  DistilleryはElixirのみで作られたリリースマネージャーです。これによってほとんど、あるいは全く設定をすることなく、どこにでもデプロイ可能なリリースを作成することができます。
  """
}
---

## リリースとは?

リリースとはコンパイルされたErlang/Elixirのコード (例えば [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) や [bytecode](https://en.wikipedia.org/wiki/Bytecode)) を含むパッケージです。また、アプリケーションの起動に必要なスクリプトも提供します。

> 1つ以上のアプリケーションを作ったら、それらのアプリケーションとErlang/OTPのサブセットを持つ完全なシステムを作るといいでしょう。これをリリースと言います。 - [Erlang documentation](http://erlang.org/doc/design_principles/release_structure.html)

> リリースは簡単なデプロイを可能にします: これは自己完結していて、リリースの起動に必要な全てのものを含みます。それらはリモートコンソールを開くために提供されているシェルスクリプトを通して簡単に管理可能であり、リリースの起動/停止/再起動、バックグラウンドでの起動、リモートコマンドの送信などを行うことができます。それに加え、それらはアーティファクトをアーカイブすることが可能であり、これは古いリリースを何時でもターボール(tarball)から復元可能であることを意味します (基盤となるOS、またはシステムライブラリとの間に非互換性が無い限り)。リリースの使用はアップグレードとダウングレードの実行の要件でもあり、Erlang VMにおけるもっとも強力な機能の1つです。 - [Distillery Documentation](https://hexdocs.pm/distillery/introduction/understanding_releases.html)

リリースは次のものを含んでいます:
* /binフォルダ
  * アプリケーション全体の起動の開始地点となるスクリプトを含みます。
* /libフォルダ
  * 依存とともにコンパイルされたアプリケーションのバイトコードを含みます。
* /releasesフォルダ
  * リリースのメタデータ、そしてフックやカスタムコマンドを含みます。
* /erts-VERSIONフォルダ
  * マシンにErlangやElixirをインストールすることなくアプリケーションを実行するためのErlangランタイムを含みます。


### 始めてみよう/インストール

Distilleryをプロジェクトに追加するために、 `mix.exs` ファイルに依存として追加します。 *注意* - Umbrellaアプリで作業している場合は、プロジェクトルートのmix.exsを変更してください。

```
defp deps do
  [{:distillery, "~> 2.0"}]
end
```

そしてターミナルで次のコマンドを実行してください:

```
mix deps.get
```

```
mix compile
```


### リリースの作成

ターミナルで次のコードを実行してください

```
mix release.init
```

このコマンドはいくつかの設定ファイルを含む `rel` ディレクトリを生成します。

リリースを生成するために `mix release` をターミナルで実行してください。

リリースが作られるとターミナルで次のような指示が見えるはずです。

```
==> Assembling release..
==> Building release book_app:0.1.0 using environment dev
==> You have set dev_mode to true, skipping archival phase
Release successfully built!
To start the release you have built, you can use one of the following tasks:

    # start a shell, like 'iex -S mix'
    > _build/dev/rel/book_app/bin/book_app console

    # start in the foreground, like 'mix run --no-halt'
    > _build/dev/rel/book_app/bin/book_app foreground

    # start in the background, must be stopped with the 'stop' command
    > _build/dev/rel/book_app/bin/book_app start

If you started a release elsewhere, and wish to connect to it:

    # connects a local shell to the running node
    > _build/dev/rel/book_app/bin/book_app remote_console

    # connects directly to the running node's console
    > _build/dev/rel/book_app/bin/book_app attach

For a complete listing of commands and their use:

    > _build/dev/rel/book_app/bin/book_app help
```

アプリケーションを実行するためには `_build/dev/rel/MYAPP/bin/MYAPP foreground` をターミナルで入力してください。
MYAPPはあなたのプロジェクト名です。これでアプリケーションのリリースビルドを実行できます！


## PhoenixとDistilleryの併用

DistilleryをPhoenixとともに使うためには、事前に必要な追加のステップがいくつかあります。

まず、 `config/prod.exs` ファイルを編集する必要があります。

次の行を:

```
config :book_app, BookAppWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
```
以下のように変更してください:

```
config :book_app, BookApp.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:book_app, :vsn)
```

ここでは、いくつかの変更を加えました:
- `server` - アプリケーション開始時にCowboyアプリケーションhttpエンドポイントを起動します
- `root` - 静的ファイルが提供されるアプリケーションのルートをセットアップします
- `version` - アプリケーションのバージョンがホットアップグレードされたときにアプリケーションキャッシュを破棄します
- `port` - ENV変数によって設定されるポートを変更すると、アプリケーションの起動時にポート番号を渡すことができます。アプリを起動すると、`PORT=4001 _build/prod/rel/book_app/bin/book_app foreground` と起動してポートを指定することができます。

上記のコマンドを実行すると、データベースが無いために接続ができず、アプリケーションがクラッシュすることに気が付いたかもしれません。これはEctoの `mix` コマンドを実行することで修正できます。ターミナルに次のように入力してください:

```
MIX_ENV=prod mix ecto.create
```

このコマンドはデータベースを作成します。アプリケーションの再起動を試すと起動が成功するはずです。しかし、データベースに対してマイグレーションが実行されていないことに気がつくでしょう。通常開発時には `mix.ecto migrate` を実行し、手動でこれらのマイグレーションを実行しますが、リリースではマイグレーションを自身が実行できるように設定しておく必要があります。


## プロダクションでマイグレーションを実行する

Distilleryはリリースのライフサイクルの色んなポイントでコードを実行する機能を提供しています。これらのポイントは [ブートフック](https://hexdocs.pm/distillery/1.5.2/boot-hooks.html) として知られています。Distilleryによって提供されるフックは次のものがあります

* pre_start
* post_start
* pre/post_configure
* pre/post_stop
* pre/post_upgrade


私たちの目的に従い、プロダクションでアプリのマイグレーションを実行するために `post_start` フックを使います。まずは `migrate` というリリースタスクを作りましょう。リリースタスクはターミナルから実行可能なモジュール関数であり、アプリケーションの内部動作から分離されたコードを含んでいます。これはアプリケーション本体が実行する必要の無いタスクなどで便利です。

```
defmodule BookAppWeb.ReleaseTasks do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:book_app)

    path = Application.app_dir(:book_app, "priv/repo/migrations")

    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)
  end
end
```

*注意* これらのマイグレーションを実行する前にアプリケーションが全て正しく起動していることを確認するのがグッドプラクティスです。 [Ecto.Migrator](https://hexdocs.pm/ecto/2.2.8/Ecto.Migrator.html) を使うことで接続されたデータベースのマイグレーションを実行することができます。

次に、新たなファイル - `rel/hooks/post_start/migrate.sh` を作り、次のコードを追加します:


```
echo "Running migrations"

bin/book_app rpc "Elixir.BookApp.ReleaseTasks.migrate"

```

このコードを正しく実行するために、リモートプロシージャコールサービスの利用を可能にするErlangの `rpc` モジュールを使います。基本的に、これによりリモートノードで関数を実行して結果を得ることができます。プロダクションで実行する時、多くの場合アプリケーションは複数の異なるノードで実行されています。

最後に、 `rel/config.exs` ファイルの中にprod設定のフックを追加します。

以下を

```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
end
```

次のように置き換えましょう

```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
  set post_start_hooks: "rel/hooks/post_start"
end
```

*注意* - このフックはアプリケーションのプロダクションリリースにのみ存在します。デフォルトのデブロップメントリリースで使用しても実行されません。

## カスタムコマンド

リリースで作業している時、リリースがデプロイされたマシンの中に `mix` がインストールされていないために `mix` コマンドにアクセスできないかもしれません。私たちはカスタムコマンドを作ることでこの問題を解決することができます。

> カスタムコマンドはブートスクリプトのエクステンションであり、foregroundやremote_consoleと同じように使われます。言い換えると、それらはブートスクリプトの一部のように見ることができます。これらはフックのようにブートスクリプトのヘルパー関数と環境へアクセスすることができます - [Distillery Docs](https://hexdocs.pm/distillery/1.5.2/custom-commands.html)

コマンドは、どちらもメソッド関数であるという点でリリースタスクと似ていますが、リリーススクリプトによって実行されるのではなく、ターミナルを介して実行されるという点で異なります。

これでマイグレーションを実行可能になったので、コマンドの実行を通してシードデータの挿入も可能にすると良いでしょう。まず、リリースタスクに新しい関数を追加します。 `BookAppWeb.ReleaseTasks` に次のコードを追加してください:

```
def seed do
  seed_path = Application.app_dir(:book_app_web, "priv/repo/seeds.exs")
  Code.eval_file(seed_path)
end
```

次に、新しいファイル `rel/commands/seed.sh` を作り、次のコードを追加してください:

```
#!/bin/sh

release_ctl eval "BookAppWeb.ReleaseTasks.seed/0"
```


*注意* - `release_ctl()` はDistilleryが提供するシェルスクリプトであり、ローカルやクリーンなノードでコマンドの実行を可能にします。実行中のノードにこれを実行する必要がある場合、 `release_remote_ctl()` を実行することができます。

シェルスクリプトの詳細については、Distilleryの [ここ](https://hexdocs.pm/distillery/extensibility/shell_scripts.html) を見てください。

最後に、 `rel/config.exs` ファイルの中に、次のコードを追加します
```
release :book_app do
  ...
  set commands: [
    seed: "rel/commands/seed.sh"
  ]
end

```

`MIX_ENV=prod mix release` を実行してリリースを作り直すことを忘れないでください。これが終わると、`PORT=4001 _build/prod/rel/book_app/bin/book_app seed` がターミナルで実行できるようになります。
