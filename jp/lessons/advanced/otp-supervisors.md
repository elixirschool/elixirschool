---
version: 0.9.1
title: OTPスーパーバイザ
---

Supervisor(スーパーバイザ)は、他のプロセスを監視するという、1つの目的に特化したプロセスです。子プロセスが失敗した際に自動的に再起動させることによって、耐障害性の高い(フォールトトレラントな)アプリケーションを作ることを可能にします。

{% include toc.html %}

## 設定

Supervisorの魔術は`Supervisor.start_link`関数の中にあります。スーパーバイザプロセスと子プロセスを開始するのに加えて、子を管理するためにスーパーバイザが使用する戦略を定義することができます。

子プロセスはリストと、`Supervisor.Spec`から取り込まれた`worker/3`関数を使って定義されます。`worker/3`関数はモジュール、引数、そして一連のオプションを受け取ります。内部では、`worker/3`は初期化時に、与えられた引数を用いて`start_link/3`を呼び出します。

[OTPの並行性](../../advanced/otp-concurrency)レッスンで実装したSimpleQueueを用いて、始めていきましょう:

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

プロセスが停止したり終了させられたりすれば、スーパーバイザは何事もなかったかのように自動的にプロセスを再起動するでしょう。

### 戦略

今のところ、スーパーバイザが利用可能な4つの異なる再起動の戦略があります:

+ `:one_for_one` - 失敗した子プロセスのみを再起動します。

+ `:one_for_all` - 失敗したイベントの中にある全ての子プロセスを再起動します。

+ `:rest_for_one` - 失敗したプロセスと、そのプロセスより後に開始された全てのプロセスを再起動します。

+ `:simple_one_for_one` - 動的にアタッチされた子プロセスに最適です。スーパーバイザは1つだけ子プロセスを含む必要があります。

### 入れ子

ワーカープロセスに加えて、スーパーバイザーにスーパーバイザーの木構造を生成するように監督することもできます。異なるのは`worker/3`を`supervisor/3`に替えることだけです:

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Taskスーパーバイザ

Taskはそれ専用のスーパーバイザ、`Task.Supervisor`を持っています。動的にタスクを生成するために設計されており、スーパーバイザは内部では`:simple_one_for_one`を用います。

### セットアップ

`Task.Supervisor`の取り込みは、他のスーパーバイザと違いはありません:

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

### 監督されたTask

スーパーバイザが開始された状態で、`start_child/2`関数を用いて監督されたタスクを作ることができます:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

タスクが途中で停止する場合、再起動が行われます。これは次々と入ってくる接続や、バックグラウンド作業の処理を扱う場合には特に役に立つでしょう。
