%{
  version: "1.2.0",
  title: "Mnesia",
  excerpt: """
  Mnesiaは、耐久性のあるリアルタイム分散データベース管理システムです。
  """
}
---

## 概要

Mnesiaは、Elixirで自然に使えるErlang Runtime Systemに同梱されているデータベース管理システム（DBMS）です。
Mnesiaの*リレーショナルとオブジェクトのハイブリッドデータモデル*は、どんな規模の分散アプリケーションの開発にも適しているものです。

## 使用するタイミング

特定の技術をいつ使うかは、しばしば迷うところです。
以下の質問のいずれかに「はい」と答えられるなら、ETSやDETSよりもMnesiaを使用する良い指標となります。

  - トランザクションのロールバックは必要か？
  - データの読み書きのための使いやすい構文が必要か？
  - データは1つのノードではなく、複数のノードに分散して保存する必要があるか？
  - 情報を保存する場所を選択する必要があるか（RAMかディスクか）？

## スキーマ

MnesiaはElixirではなくErlangコアの一部なので、コロン構文でアクセスしなければなりません（レッスン: [Erlangとの相互運用](/ja/lessons/intermediate/erlang) を参照してください）。

```elixir

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

このレッスンでは、Mnesia APIを使用する場合、後者のアプローチを取ります。
`Mnesia.create_schema/1` は新しい空のスキーマを初期化し、ノードリストを渡します。
この場合、IExセッションに関連付けられたノードを渡します。

## ノード

IEx経由で `Mnesia.create_schema([node()])` コマンドを実行すると、現在の作業ディレクトリに **Mnesia.nonode@nohost** などというフォルダが表示されるはずです。
この**nonode@nohost**というのは、今まで出てこなかったので、どういう意味かと思われるかもしれません。
それでは見てみましょう。

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

コマンドラインからIExに `--help` オプションを渡すと、可能なすべてのオプションが表示されます。
`name` と `--sname` オプションがあり、ノードに情報を割り当てることができることがわかります。
ノードとは起動しているErlang仮想マシンのことで、それ自身の通信やガベージコレクション、処理のスケジューリング、メモリなどを扱います。
ノードはデフォルトで **nonode@nohost** という名前になっています。

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

これでわかるように、実行中のノードは `: "learner@elixirschool.com"` というアトムであることがわかります。
もう一度 `Mnesia.create_schema([node()])` を実行すると、**Mnesia.learner@elixirschool.com** という別のフォルダが作成されていることがわかります。
この目的はとてもシンプルです。
Erlangのノードは、他のノードに接続し、情報やリソースを共有（配布）するために使われます。
これは同じマシンに限定する必要はなく、LANやインターネットなどを通じて通信できます。

## Mnesiaを開始する

さて、背景の基本が終わり、データベースをセットアップしたら、今度は `Mnesia.start/0` コマンドでMnesia DBMSを起動する段階に入りました。

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

関数 `Mnesia.start/0` は非同期です。
これは既存のテーブルの初期化を開始し、`:ok`アトムを返します。
Mnesiaを起動した直後に既存のテーブルに対して何らかのアクションを実行する必要がある場合、 `Mnesia.wait_for_tables/2` という関数を呼び出す必要があります。
これは、テーブルが初期化されるまで呼び出し元を一時停止します。
[データの初期化とマイグレーション](#data-initialization-and-migration)のセクションの例を参照してください。

2つ以上のノードが参加する分散システムを実行する場合、 `Mnesia.start/1` 関数を参加している全てのノードで実行する必要があることに留意するとよいでしょう。

## テーブルを作成する

データベース内にテーブルを作成するには、関数 `Mnesia.create_table/2` を使用します。
以下では、`Person` という名前のテーブルを作成し、テーブルのスキーマを定義するキーワードリストを渡します。

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

アトムを使用して `:id`、`:name`、`:job` カラムを定義します。
最初のアトム (この場合は `:id`) がプライマリキーとなります。
少なくとも1つの属性が必要です。

`Mnesia.create_table/2` を実行すると、以下のいずれかのレスポンスが返されます。

 - 関数が正常に実行された場合、 `{:atomic, :ok}` を返します。
 - 関数が失敗した場合、`{:aborted, Reason}` を返します。

とくに、テーブルがすでに存在している場合、理由は `{:already_exists, table}` という形式になり、このテーブルを再度作成しようとすると、次のような結果になります。

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## ダーティな方法

最初に、Mnesiaテーブルの読み書きのダーティーなやり方について見ていきます。
これは成功が保証されていないため、一般的には避けるべきですが、Mnesiaを学び、快適に操作できるようになるための助けになるはずです。
それでは、**Person**テーブルにいくつかのエントリーを追加してみましょう。

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...そして、エントリーを取得するために `Mnesia.dirty_read/1` を使用できます。

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

存在しないレコードを取得しようとすると、Mnesiaは空のリストを返します。

## トランザクション

伝統的に、私たちは**トランザクション**を使用して、データベースへの読み書きをカプセル化しています。
トランザクションは、耐障害性の高い分散システムを設計する上で重要な役割を果たします。
Mnesiaのトランザクションは、*一連のデータベース操作を1つの機能ブロックとして実行することができるメカニズム*です。
まず、無名関数、この場合は `data_to_write` を作成し、それを `Mnesia.transaction` に渡します。

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
このトランザクションメッセージに基づけば、`Person`テーブルにデータを書き込んだと安全に判断できます。
念のため、トランザクションを使用してデータベースから読み込んでみましょう。
データベースから読み込むには `Mnesia.read/1` を使用しますが、ここでも無名関数の中から行います。

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

データを更新したい場合は、既存のレコードと同じキーで `Mnesia.write/1` を呼び出すだけです。
したがって、ハンスのレコードを更新するには、次のようにします。

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## インデックスの使用

Mnesiaは非キーカラムのインデックスをサポートしており、これらのインデックスに対してデータをクエリできます。
そこで、`Person`テーブルの `:job` カラムに対してインデックスを追加してみましょう。

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

結果は `Mnesia.create_table/2` が返すものと似ています。

 - 関数が正常に実行された場合は、 `{:atomic, :ok}` が返されます。
 - 関数が失敗した場合、`{:aborted, Reason}` が返されます。

とくに、インデックスがすでに存在している場合、理由は `{:already_exists, table, attribute_index}` という形式になり、このインデックスを再度追加しようとすると、次のような結果になります。

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

インデックスが正常に作成されたら、それに対して読み取りを行い、すべてのプリンシパルのリストを取得できます。

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## マッチとセレクト

Mnesiaはテーブルからデータを取得するための複雑なクエリを、マッチングやアドホックなセレクト関数という形でサポートしています。

`Mnesia.match_object/1` 関数は、与えられたパターンにマッチするすべてのレコードを返します。
テーブルのカラムにインデックスがある場合は、それを利用してクエリをより効率的に行うことができます。
マッチに含まれないカラムを識別するために、特別なアトム `:_` を使用します。

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

`Mnesia.select/2` 関数を使うと、Elixir言語（あるいはErlang）の任意の演算子や関数を使ったカスタムクエリを指定できます。
例として、キーが3より大きいレコードをすべて選択する方法を見てみましょう。

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}])
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

これを紐解いてみましょう。
最初の属性はテーブル `Person` で、2番目の属性は `{match, [guard], [result]}` という形式の3つの値です。

- `match` は `Mnesia.match_object/1` 関数に渡すものと同じです。しかし、`:"$n"` という特別なアトムがあり、クエリの残りの部分で使用される位置パラメータを指定していることに注意してください。
- `guard` リストは適用するガード関数を指定するタプルのリストで、この場合は最初の位置パラメータ `:"$1"` と定数 `3` を属性として標準の関数である `:>`（より大きい）を使用します。
- `result` リストは、クエリによって返されるフィールドのリストです。すべてのフィールドを参照するために、 `:"$$"` という特別なアトムの位置パラメーターで表現されます。最初の2つのフィールドを返すには `[:"$1", :"$2"]` を、すべてのフィールドを返すには `[:"$$"]` を使うことができます。

詳しくは[Erlang Mnesia ドキュメントのselect/2](http://erlang.org/doc/man/mnesia.html#select-2)を参照してください。

## データの初期化とマイグレーション

どのソフトウェアソリューションでも、ソフトウェアのアップグレードやデータベースに保存されているデータのマイグレーションが必要になる時期がやってきます。
たとえば、アプリのv2で `Person` テーブルに `:age` カラムを追加したいとします。
一度作成された `Person` テーブルを作成することはできませんが、変換することは可能です。
そのためには、いつ変換するのかを知っておく必要があります。これは、テーブルを作成する際に行うことができます。
そのためには、 `Mnesia.table_info/2` 関数で現在のテーブルの構造を取得し、 `Mnesia.transform_table/3` 関数で新しい構造へ変換します。

以下のコードでは、次のロジックを実装することでこれを実現しています。

* v2の属性を持つテーブルを作成します。`[:id, :name, :job, :age]` 
* 作成結果を処理します。
    * `{:atomic, :ok}`: `:job` と `:age` にインデックスを作成して、テーブルを初期化します
    * `{:aborted, {:already_exists, Person}}`: 現在のテーブルの属性が何であるかを確認し、それにしたがって動作します。
        * v1リスト (`[:id, :name, :job]`) の場合、すべての人の年齢を21に設定してテーブルを変換し、 `:age` に新しいインデックスを追加します。
        * v2リストであれば、何もしません。問題ありません。
        * 他のものであった場合、終了します。

`Mnesia.start/0` でMnesiaを起動した直後に既存のテーブルに対して何らかのアクションを実行すると、それらのテーブルが初期化されておらず、アクセスできない可能性があります。
その場合、[`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2) 関数を使用する必要があります。
これは、テーブルが初期化されるか、タイムアウトに達するまで、現在のプロセスを一時停止させます。

`Mnesia.transform_table/3` 関数は、テーブルの名前、レコードを古いフォーマットから新しいフォーマットに変換する関数、新しい属性のリストを属性として受け取ります。

```elixir
case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
  {:atomic, :ok} ->
    Mnesia.add_table_index(Person, :job)
    Mnesia.add_table_index(Person, :age)
  {:aborted, {:already_exists, Person}} ->
    case Mnesia.table_info(Person, :attributes) do
      [:id, :name, :job] ->
        Mnesia.wait_for_tables([Person], 5000)
        Mnesia.transform_table(
          Person,
          fn ({Person, id, name, job}) ->
            {Person, id, name, job, 21}
          end,
          [:id, :name, :job, :age]
          )
        Mnesia.add_table_index(Person, :age)
      [:id, :name, :job, :age] ->
        :ok
      other ->
        {:error, other}
    end
end
```
