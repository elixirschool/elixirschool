%{
  version: "1.1.1",
  title: "OTPスーパバイザ",
  excerpt: """
  スーパバイザは、他のプロセスを監視するという一つの目的に特化したプロセスです。
子プロセスが失敗した際に自動的に再起動させることによって、耐障害性の高いアプリケーションを作ることを可能にします。
  """
}
---

## 設定

スーパバイザの魔術は `Supervisor.start_link/2` 関数の中にあります。
スーパーバイザプロセスと子プロセスを開始するのに加えて、子を管理するためにスーパーバイザが使用する戦略を定義することができます。

[OTPの並行性](../../advanced/otp-concurrency)レッスンで実装したSimpleQueueを用いて、始めていきましょう。

新しいプロジェクトを `mix new simple_queue --sup` を使って作成することで、スーパバイザツリーも一緒に作成することができます。
`SimpleQueue` モジュール用のコードは `lib/simple_queue.ex` へ、スーパバイザを起動するコードは `lib/simple_queue/application.ex` に記述することになります。

スーパバイザの子プロセスはリストで定義します。それは以下のように単純にモジュール名のリストにするか…

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      SimpleQueue
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

あるいは子プロセスの起動時に初期値を渡すべくタプルのリストにするか、のどちらかが使えます。

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleQueue, [1, 2, 3]}
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

`iex -S mix` で実行すると `SimpleQueue` が自動的に実行されるのがわかります。

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

もし `SimpleQueue` プロセスが異常終了や通常終了すれば、スーパバイザは何事もなかったかのように自動的にプロセスを再起動するでしょう。

### 戦略

今のところ、スーパバイザが利用可能な3つの異なる再起動の戦略があります:

- `:one_for_one` - 失敗した子プロセスのみを再起動します。

- `:one_for_all` - 失敗したイベントの中にある全ての子プロセスを再起動します。

- `:rest_for_one` - 失敗したプロセスと、そのプロセスより後に開始された全てのプロセスを再起動します。

## 子プロセスの定義

起動されたスーパバイザは、子プロセスをどのように起動/停止/再起動させるのかを知ってなくてはなりません。
各々の子モジュールにはこれらの振る舞いを定義する `child_spec/1` 関数が必要です。
`use GenServer` や `use Supervisor` や `use Agent` のマクロを使う場合は、この定義が自動的に行われます。例えば `SimpleQueue` は `use Genserver` してるので、モジュールの記述を変更する必要はありません。自分で定義する必要がある場合は `child_spec/1` 関数が以下のようにキーのマップを返すようにします。

```elixir
def child_spec(opts) do
  %{
    id: SimpleQueue,
    start: {__MODULE__, :start_link, [opts]},
    shutdown: 5_000,
    restart: :permanent,
    type: :worker
  }
end
```

- `id` - 必須キーです。
  スーパバイザが子プロセスを指定するのに使います。

- `start` - 必須キーです。
  スーパバイザがプロセスを起動するときのモジュール/関数/引数を指定します。

- `shutdown` - オプションキーです。
  子プロセスの終了に関する振る舞いを定義します。
  以下の種類があります：

  - `:brutal_kill` - 子プロセスは直ちに停止させられます。

  - 任意の正整数 - 子プロセスが停止されるまでの時間をミリ秒で表します。
    もしプロセスが `:worker` 型の場合は5000がデフォルト値です。

  - `:infinity` - スーパバイザは子プロセスの停止を無期限に延長します。
    これはプロセスが `:supervisor` 型の場合のデフォルトです。
    プロセスが `:worker` 型の場合には使わないことを推奨します。

- `restart` - オプションキーです。
  子プロセスの終了に対して以下の方法を定義できます：

  - `:permanent` - 子プロセスは常に再起動されます。
    すべてのプロセスのデフォルトです。

  - `:temporary` - 子プロセスは決して再起動されません。

  - `:transient` - 子プロセスが異常な終了をした場合にのみ再起動されます。

- `type` - オプションキーです。
  プロセスは `:worker` か `:supervisor` のどちらかの型になります。
  デフォルトは `:worker` です。

## 動的スーパバイザ

アプリケーションが開始されたときに、通常スーパバイザは子プロセスのリストと共に起動します。
しかしながら、アプリケーションの開始時には監視すべき子プロセスが決まっていない場合もあります。例えば、webサイトに接続にくるユーザ処理のプロセスを起動するようなアプリケーションなどでありえます。
このような状況に対しては、子プロセスを要求に応じて開始できるようなスーパバイザが欲しくなるでしょう。
動的スーパバイザはこのような状況で利用できます。

子プロセスを定義しないので、スーパバイザの定義はランタイムオプションのみです。
動的スーパバイザは監視の戦略として `:one_for_one` のみが使えます。

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```

そして、スーパバイザと子プロセスの定義を引数として `start_child/2` を用いることで動的にSimpleQueueを起動します。ただ `SimplefQueue` は `use GenServer` を使っているので、すでに子プロセスは定義済みです。

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Taskスーパバイザ

Taskはそれ専用のスーパバイザ `Task.Supervisor` を持っています。
動的にタスクを生成するように設計されており、Taskスーパバイザは暗黙的に `DynamicSupervisor` を用いています。

### セットアップ

`Task.Supervisor` の使い方は他のスーパバイザと同様です：

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

`Supervisor` との `Task.Supervisor` の最も大きな違いは再起動の戦略のデフォルトが `:temporary` である、すなわちタスクは再起動されない設定になっているということです。

### Taskの監視

スーパバイザが開始された状態において `start_child/2` 関数によりスーパバイザに監視されるタスクを作ることができます：

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

タスクが途中で異常終了する場合、再起動が行われます。
これは次々と入ってくる接続やバックグラウンドで行う処理には特に役に立つでしょう。
