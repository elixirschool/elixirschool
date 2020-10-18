---
version: 1.1.0
title: Erlang Term Storage (ETS)
---

Erlang Term Storage、略してETSは、OTP内部に組み込まれている強力なストレージエンジンで、Elixirから利用することができます。このレッスンではETSを呼び出す方法と、アプリケーションで使用する方法を見ていきます。

{% include toc.html %}

## 概要

ETSは堅牢なインメモリストアで、ElixirやErlangのオブジェクトを保管するためのものです。ETSはとても大きなデータを格納し、定数時間でのデータアクセスを提供します。

ETSのテーブルは個々のプロセスによって生成、所有されています。テーブルを所有しているプロセスが死ぬと、テーブルは破壊されます。初期状態では、ETSはノードにつき1400テーブルに制限されています。

## テーブルの作成

テーブルは `new/2` で作成します。この関数はテーブル名と、一連のオプションを受け取り、以降の操作で用いることのできるテーブルのIDを返します。

例としてユーザをニックネームで管理し、検索するテーブルを作ります:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

GenServerと同じように、IDの代わりに名前でETSテーブルにアクセスする方法があります。 `:named_table` をオプションに含めることで、名前を用いて直接テーブルにアクセスできます:

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### テーブルの型

ETSで利用できるテーブルの型は4つあります:

- `set` - デフォルトのテーブル型です。キー毎に1つの値を持ち、キーは一意です。
- `ordered_set` - `set` に似ていますがErlang/Elixirの条件で順序付けされます。重要なので注記しておくと、キーの比較は `ordered_set` の内部では他と異なります。等値であるとみなされるキーは個別にマッチしません。1と1.0は同じキーであるとみなされます。
- `bag` - キー毎に複数のオブジェクトを持てるが、1つのオブジェクトにつき1つのインスタンスのみです。
- `duplicate_bag` - キー毎に複数のオブジェクトが持て、重複が許されます。

### アクセス制御

ETSでのアクセス制御はモジュール内部のアクセス制御と似ています:

- `public` - 全てのプロセスで読み/書きが可能です。
- `protected` - 全てのプロセスで読み込みが可能です。所有プロセスによってのみ書き込みができます。これがデフォルトです。
- `private` - 読み/書きは所有プロセスに限定されます。

## レースコンディション

一つ以上のプロセスがテーブルに書き込みができると、レースコンディションが発生する可能性があります。具体的には `:public` でアクセスできる場合や所有プロセスに対してメッセージを送ったりすることで起こり得ます。たとえば、二つのプロセスが同時にカウンターの値である `0` を読み、増加させて `1` を書き込んだとしましょう。結果として、一度の増加分しか反映されないです。

カウンターに関しては[:ets.update_counter/3](http://erlang.org/doc/man/ets.html#update_counter-3)がアトミックな変更-読み込みを提供してくれます。それ以外の場合、" `:results` というキーに対応する値にこの値を足せ"みたいなカスタムのアトミックオペレーションを所有プロセスから実行する必要があるかもしれません。

## データの挿入

ETSはスキーマを持ちません。唯一の制限は、データは最初の項がキーであるタプルとして格納されなくてはいけないというものです。新しいデータを追加するには `insert/2` を用います:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

`insert/2` を `set` や `ordered_set` に用いると、既存のデータは置換されます。これを避けるため、キーが存在している場合に `false` を返してくれる `insert_new/2` があります:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## データの検索

ETSは格納したデータを検索するために便利で柔軟な方法をいくつか提供しています。データの検索をキーや異なった形式のパターンマッチングで行う方法について見ていきます。

最も効率が良く、理想的な検索方法はキーによる探索です。便利ではあるものの、マッチングはテーブルを反復するので、特に巨大なデータセットに対しては慎重に用いるべきです。

### キー探索

キーが与えられる場合は、 `lookup/2` を用いて全レコードを検索することができます:

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### 単純なマッチ

ETSはErlangで作られているため、マッチ変数が _少しだけ_ ダサく見えることを警告しておきます。

マッチ内で変数を指定するには、 `:"$1"` 、 `:"$2"` 、 `:"$3"` などのアトムを用います。変数の数字は結果の位置を示していて、マッチの位置ではありません。興味のない値については、 `:_` 変数を用います。

値もマッチングで用いることはできますが、変数だけが結果として返ってきます。値と変数を一緒に使ってみて、どうなるかを見てみましょう:

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

変数が結果リストの順番にどう影響するか、他の例を見てみましょう:

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

リストではなく、元のオブジェクトが欲しい場合はどうするのが良いでしょう。 `match_object/2` を用いることができます。これは変数に関わらず、オブジェクト全体を返します:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### 発展的な探索

単純なマッチのケースを学びましたが、何かもっとSQLクエリのようなものがあると良いでしょうか。ありがたいことに、もっとしっかりとした構文が利用できます。データを `select/2` で探索するには、3つの引数を持つタプルのリストを作る必要があります。これらのタプルはパターン、0以上のガード節、そして戻り値のフォーマットを表します。

マッチ変数と2つの新しい変数、 `:"$$"` と `:"$_"` は戻り値を作るのに用いることが出来ます。この新しい変数は戻り値のフォーマット用のショートカットで、 `:"$$"` は結果をリストで、 `:$_` は元のデータオブジェクトで取得します。

先ほどの `match/2` の例を、 `select/2` に置き換えましょう:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"spork", 30, ["ruby", "elixir"]}]
```

`select/2` はレコードのどれをどう扱うかについて先ほどよりはまともな管理を可能にしますが、構文は極めて不親切ですし、後々もっとひどくなるはずです。これを制御するため、ETSモジュールは `fun2ms/1` を備えています。これは関数をマッチスペック(match_spec)に置き換えるものです。 `fun2ms/1` を使うとより親しみやすい関数の構文を用いてクエリを作成することができます。

`fun2ms/1` と `select/2` を用いて、2言語以上を知っている全てのユーザ名を探してみましょう:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

マッチスペックについてもっと学びたいですか？Erlangの公式ドキュメントから[match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html)を確認してください。

## データの削除

### レコードの除去

レコードの除去は `insert/2` や `lookup/2` と同じように直接的です。 `delete/2` でテーブルとキーを指定するだけです。この関数は指定されたキーと値の両方を削除します:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### テーブルの除去

ETSテーブルは親が消滅するまではガベージコレクトされません。所有プロセスを殺すことなく、テーブル全体を削除する必要がある場合もあります。そうした時のために、 `delete/1` を用いることができます:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## ETSの使用例

ここまで学んだことをうまく活かして、高コストな処理用の単純なキャッシュを作ってみましょう。モジュールと関数、引数、オプションを受け取る `get/4` 関数を実装します。オプションについては今のところ `:ttl` だけを気にするようにしておきます。

この例では、ETSテーブルはスーパーバイザといった他のプロセスの一部として作られます:

```elixir
defmodule SimpleCache do
  @moduledoc """
  高コストな関数呼び出し用の、単純なETSベースのキャッシュ
  """

  @doc """
  キャッシュされた値を検索するか、与えられた関数をキャッシュして
  結果を返します。
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  キャッシュされた結果を探索し、期限切れかどうかを確認します
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  結果の期限時刻を現在のシステム時刻と比較します。
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  関数を追加し、期限を計算し、結果をキャッシュします。
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

キャッシュをデモするため、システム時刻と10秒のTTL(生存時間)を返す関数を使用します。以下の例のように、値が破棄されるまではキャッシュされた結果が帰ります:

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

10秒後に再度試行すれば、新しい結果を得るはずです:

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

ここまで見たように、スケール可能で高速なキャッシュを外部の依存なしに実装することが可能です。これはETSの多くの用途のほんの一部分に過ぎません。

## ディスクを用いたETS

ETSはインメモリのデータストレージ用だとわかりましたが、ディスクを用いるストレージが必要な場合はどうでしょうか。こうした用途にはディスクベースのストレージ、DETSがあります。ETSとDETSのAPIはテーブルの作成を除いて互換性があります。DETSは `open_file/2` を使用し、 `:named_table` オプションは必要ありません:

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

`iex` を終了したらローカルディレクトリを見てください。 `disk_storage` というファイルが新しく存在するはずです:

```shell
$ ls | grep -c disk_storage
1
```

最後に注記しておきますが、DETSはETSと異なり `orderd_set` には対応していません。 `set` 、 `bag` 、そして `duplicate_bag` にのみ対応しています。
