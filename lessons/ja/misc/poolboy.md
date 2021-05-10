%{
  version: "1.2.0",
  title: "Poolboy",
  excerpt: """
  もしあなたのプログラムを実行しているprocess数が生成できる最大限まで使っていない場合、簡単にシステムリソースを使い果たすことになります。 [Poolboy](https://github.com/devinus/poolboy) はErlangで広く利用されている軽量で汎用的なpoolingライブラリです。
  """
}
---

## なぜPoolboyを使うか

次のような例を考えてみましょう。あなたはユーザーのプロフィールをデータベースに保存するタスクを作成しました。もしあなたがそれぞれの登録毎にプロセスを作成したとすると、データベースへのコネクションは無限に作られることになるでしょう。そしてある時点で、コネクション数がデータベースサーバーの容量を超えることがあります。最終的には、そのアプリケーションはタイムアウトなど様々な例外を返すようになります。

この解決策はユーザー登録毎にプロセスを作成する代わりに一連のワーカー(プロセス)を使ってコネクション数に制限をつくることです。そうすると、簡単にシステムリソース不足を回避できます。

そこでPoolboyを利用します。Poolboyは `Supervisor` によって管理しているワーカーのプールを簡単に設定できます。Poolboyはさまざまなライブラリで利用されています。例えば、 `postgrex` のコネクションプール_( EctoでPostgreSQLを使うために活用されている)_や `redis_poolex` _(Redisのコネクションプール)_などの様々なよく利用されるライブラリがPoolboyを使っています。

## インストール

mixを使えばインストールは簡単です。Poolboyの依存関係を `mix.exs` に記述するだけです。

まずは簡単なアプリケーションを作ってみましょう。

```shell
$ mix new poolboy_app --sup
```

`mix.exs` にPoolboyの依存関係を追加しましょう。

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

そして、Poolboyを含めた依存関係を持ってきましょう。

```shell
$ mix deps.get
```

## 設定可能なオプション

Poolboyを使い始める前に、もう少し多様な設定オプションを知っておく必要があります。

- `:name` - プールの名前。スコープは `:local` 、 `:global` もしくは `:via` が使えます。
- `:worker_module` - ワーカーを表現するモジュール。
- `:size` - プールの最大サイズ。
- `:max_overflow` - プールが空の時に作る一時的なワーカーの最大数(オプショナル)。
- `:strategy` - `:lifo` もしくは `:fifo` が使えます。これはプールに戻されるワーカーが列の最初に戻されるか、最後に戻されるかを決めます。デフォルトは `lifo` です(オプショナル)。

## Poolboyを設定する

この例題では数の平方根を計算するリクエストを処理する責任をもつワーカーのプールを作ります。Poolboyに集中するために例題を簡単なものにします。

Poolboyの設定オプションを定義し、Poolboyワーカープールをアプイケーションの子ワーカーとして追加しましょう。 `lib/poolboy_app/application.ex` を修正します。

```elixir
defmodule PoolboyApp.Application do
  @moduledoc false

  use Application

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: PoolboyApp.Worker,
      size: 5,
      max_overflow: 2
    ]
  end

  def start(_type, _args) do
    children = [
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    opts = [strategy: :one_for_one, name: PoolboyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

最初に定義しないといけないのはプールに関する設定です。プールに `:worker` という名をつけ、 `:scope` を `:local` に指定しました。そして `:worker_module` として `PoolboyApp.Worker` モジュールを使うようにします。プールの `:size` には `5` を設定し、総5つのワーカーを使うようにします。加えて全てのワーカーが負荷下にある場合、 `2` つのワーカーを追加で生成するように `:max_overflow` オプションを使います。_(`overflow` で作られたワーカーは作業が終われたなくなります)_

次に、プールに存在するワーカーがアプリケーションが実行される時に起動するように `:poolboy.child_spec/2` 関数を子のリストに追加します。これは二つの引数を取ります。一つはプールの名前で、もう一つはプールの設定です。

## ワーカー生成

ワーカーモジュールは平方根を計算し、1秒間眠た後、ワーカーのpidを出力する簡単な `GenServer` です。 `lib/poolboy_app/worker.ex` を作りましょう。

```elixir
defmodule PoolboyApp.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:square_root, x}, _from, state) do
    IO.puts("process #{inspect(self())} calculating square root of #{x}")
    Process.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## Poolboyを使う

`PoolboyApp.Worker` を作ったので、Poolboyをテストできます。Poolboyを利用して平行プロセスを生成する簡単なモジュールを作りましょう。 `:poolboy.transaction/3` はワーカープールに対するインタフェースとして使用可能な関数です。 `lib/poolboy_app/test.ex` を作ります。

```elixir
defmodule PoolboyApp.Test do
  @timeout 60000

  def start do
    1..20
    |> Enum.map(fn i -> async_call_square_root(i) end)
    |> Enum.each(fn task -> await_and_inspect(task) end)
  end

  defp async_call_square_root(i) do
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid -> GenServer.call(pid, {:square_root, i}) end,
        @timeout
      )
    end)
  end

  defp await_and_inspect(task), do: task |> Task.await(@timeout) |> IO.inspect()
end
```

テスト関数を実行して結果を見ましょう。

```shell
$ iex -S mix
```

```elixir
iex> PoolboyApp.Test.start()
process #PID<0.182.0> calculating square root of 7
process #PID<0.181.0> calculating square root of 6
process #PID<0.157.0> calculating square root of 2
process #PID<0.155.0> calculating square root of 4
process #PID<0.154.0> calculating square root of 5
process #PID<0.158.0> calculating square root of 1
process #PID<0.156.0> calculating square root of 3
...
```

もしプールに利用可能なワーカーがないとPoolboyはデフォルトのタイムアウト期間(5秒)の後、タイムアウトして新しいリクエストを受け付けません。ここではどうやってデフォルトのタイムアウト設定を書き換えられるのかを説明するためにデフォルトのタイムアウトを1分まで増加させています。このアプリケーションの場合、 `@timeout` を1000以下に設定してエラーを観測できます。

多数のプロセスを生成しようとしても_(上記の例題では全体で20個)_ `:poolboy.transaction` 関数は設定に従い、生成するプロセスの最大数を5つに制限します(臨時のワーカーを2つ追加される場合もある)。全てのリクエストは毎回新しいプロセスを生成するのではなくワーカーのプールを利用して処理されます。
