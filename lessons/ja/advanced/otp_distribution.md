%{
  version: "1.0.1",
  title: "OTPディストリビューション",
  excerpt: """
  ## ディストリビューションへの入門

Elixirアプリは、単体のホストや複数のホストにまたがって分散された(distributed)一連の異なるノードで実行することができます。
Elixirは、このレッスンで概説するいくつかの異なるメカニズムを通して、それらのノード間で通信をすることが可能です。
  """
}
---

## ノード間通信

ElixirはErlang VMで動作しますが、これはErlangの強力な [分散機能](http://erlang.org/doc/reference_manual/distributed.html) へアクセス可能であることを意味します。

> 分散されたErlangシステムは互いに通信するいくつものErlangランタイムシステムを含んでいます。
> これらのそれぞれのランタイムはノードと呼ばれます。

ノードは名前が与えられた任意のErlangランタイムシステムです。
名前を与えて `iex` セッションを起動することで、ノードを開始できます:

```bash
iex --sname alex@localhost
iex(alex@localhost)>
```

別のターミナルウィンドウで、もう一つのノードを起動してみましょう:

```bash
iex --sname kate@localhost
iex(kate@localhost)>
```

これら2つのノードは `Node.spawn_link/2` を使うことで相手にメッセージを送ることができます。

### `Node.spawn_link/2` による通信

この関数は2つの引数を取ります:

- 接続したいノードの名前
- そのノードで動作しているリモートプロセスによって実行させる関数

これはリモートノードとの間で通信を確立して、ノード上で与えられた関数を実行し、リンクされたプロセスのPIDを返します。

Kateさんを紹介する `Kate` というモジュールを、 `kate` ノードの中に定義しましょう:

```elixir
iex(kate@localhost)> defmodule Kate do
...(kate@localhost)>   def say_name do
...(kate@localhost)>     IO.puts "Hi, my name is Kate"
...(kate@localhost)>   end
...(kate@localhost)> end
```

#### メッセージの送信

これで [`Node.spawn_link/2`](https://hexdocs.pm/elixir/Node.html#spawn_link/2) を使うと、 `alex` ノードは `kate` ノードに対して `say_name/0` 関数を呼ばせることができます:

```elixir
iex(alex@localhost)> Node.spawn_link(:kate@localhost, fn -> Kate.say_name end)
Hi, my name is Kate
#PID<10507.132.0>
```

#### 入出力とノードに関する注意

注意が必要なのは、 `Kate.say_name/0` がリモートノードで実行されたとはいえ、 `IO.puts` の結果を受け取るのはローカル、つまり呼び出し側のノードだという点です。
これは、ローカルノードが **グループリーダー** であるためです。
Erlang VMはプロセスを通してI/Oを管理します。
これによって `IO.puts` のようなI/Oタスクを分散されたノード間で実行することができます。
これらの分散されたプロセスは、I/Oプロセスグループリーダーによって管理されます。
このグループリーダーは常にプロセスを生産するノードとなります。
そのため、 `alex` ノードは `spawn_link/2` から呼び出されているので、そのノードがグループリーダーとなり、 `IO.puts` の出力はそのノードの標準出力ストリームへと向けられます。

#### メッセージへの返信

受信したノードから送信側に対して何らかの _返信_ を返したい場合はどうしましょう？ これは、単に `receive/1` と [`send/3`](https://hexdocs.pm/elixir/Process.html#send/3) を使うことで実現できます。

`alex` ノードに `kate` ノードへのリンクを作らせて、 `kate` ノードに匿名関数を実行させます。
その匿名関数は、メッセージと `alex` ノードのPIDを記述する特定のタプルの受信を待ちます。
`alex` ノードのPIDにメッセージを送り(`send`)返すことで、そのメッセージに応答します。

```elixir
iex(alex@localhost)> pid = Node.spawn_link :kate@localhost, fn ->
...(alex@localhost)>   receive do
...(alex@localhost)>     {:hi, alex_node_pid} -> send alex_node_pid, :sup?
...(alex@localhost)>   end
...(alex@localhost)> end
#PID<10467.112.0>
iex(alex@localhost)> pid
#PID<10467.112.0>
iex(alex@localhost)> send(pid, {:hi, self()})
{:hi, #PID<0.106.0>}
iex(alex@localhost)> flush()
:sup?
:ok
```

#### 異なるネットワークでのノード間通信における注意

異なるネットワークにおけるノード間でメッセージ送信をしたい場合、共通cookieで名前を与えられたノードを起動する必要があります:

```bash
iex --sname alex@localhost --cookie secret_token
```

```bash
iex --sname kate@localhost --cookie secret_token
```

同一の `cookie` で開始されたノード同士のみがお互いに接続することができます。

#### `Node.spawn_link/2` の制限

`Node.spawn_link/2` は、ノード間の関係とメッセージ送信を可能にする方法を示す一方で、実際には分散ノードをまたいで動作するアプリケーションに対しては正しい選択では _ありません_ 。
`Node.spawn_link/2` は単独でプロセスを生成します。
つまり、そのプロセスは監視されていません。
_ノード間で_ 監視された非同期プロセスを生成する方法があれば…

## 分散タスク

[分散タスク](https://hexdocs.pm/elixir/master/Task.html#module-distributed-tasks) によって、監視されたタスクをノードをまたいで生成することができます。
ここでは分散タスクを利用し、分散されたノードをまたいで `iex` セッションを通じたユーザー間のチャットを可能にするシンプルなスーパーバイザアプリケーションを作ります。

### スーパーバイザアプリケーションの定義

次のコマンドでアプリを生成します:

```
mix new chat --sup
```

### スーパービジョンツリーへのタスクスーパーバイザの追加

タスクスーパーバイザはタスクを動的に監視します。
これは子が無い状態で開始され、大抵は自分を監視するスーバーバイザの _下に_ あり、後に任意の数のタスクの監視に使用することができます。

ここでは、タスクスーパーバイザをアプリのスーパービジョンツリーに追加し、 `Chat.TaskSupervisor` と名前をつけます。

```elixir
# lib/chat/application.ex
defmodule Chat.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Chat.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

これでアプリケーションが指定されたどこのノードで開始されても、 `Chat.Supervisor` が開始されてタスクを監視する準備ができたのがわかります。

### 監視されたタスクへのメッセージ送信

[`Task.Supervisor.async/5`](https://hexdocs.pm/elixir/master/Task.Supervisor.html#async/5) 関数で監視されたタスクを開始します。

この関数は4つの引数を受け取らなければいけません:

- タスクを監視するために使用したいスーパーバイザ。
  これはリモートノードでタスクを監視するために `{SupervisorName, remote_node_name}` のタプルで渡すことができます。
- 関数を実行したいモジュールの名前
- 実行したい関数の名前
- 関数に渡たす必要がある引数

シャットダウンオプションに関する5番目の引数を渡すこともできます。
ただし、ここでは特に気にしません。

チャットアプリケーションはとてもシンプルです。
これはリモートノードにメッセージを送り、リモートノードは `IO.puts` でそれらのメッセージをリモートノードの標準出力に出力することで応答します。

はじめに、リモートノードでタスクを実行させたい `Chat.receive_message/1` を定義しましょう。

```elixir
# lib/chat.ex
defmodule Chat do
  def receive_message(message) do
    IO.puts message
  end
end
```

次に、 `Chat` モジュールに監視されたタスクを使ってどのようにリモートノードへとメッセージを送るかを教えましょう。
このプロセスを成立させるメソッド `Chat.send_message/2` を定義します。

```elixir
# lib/chat.ex
defmodule Chat do
  ...

  def send_message(recipient, message) do
    spawn_task(__MODULE__, :receive_message, recipient, [message])
  end

  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  defp remote_supervisor(recipient) do
    {Chat.TaskSupervisor, recipient}
  end
end
```

それでは、実際に見てみましょう。

1つ目のターミナルウィンドウにて、名前をつけた `iex` セッションの中でチャットアプリを起動します。

```bash
iex --sname alex@localhost -S mix
```

もう1つのターミナルウィンドウを開いて、別の名前をつけたノードでアプリを起動します。

```bash
iex --sname kate@localhost -S mix
```

これで、 `alex` ノードから `kate` ノードへメッセージを送ることができます:

```elixir
iex(alex@localhost)> Chat.send_message(:kate@localhost, "hi")
:ok
```

`kate` ウィンドウに切り替えると、次のようなメッセージが見えるはずです:

```elixir
iex(kate@localhost)> hi
```

`kate` ノードは `alex` ノードに返信を返すことができます:

```elixir
iex(kate@localhost)> hi
Chat.send_message(:alex@localhost, "how are you?")
:ok
iex(kate@localhost)>
```

すると `alex` ノードの `iex` セッションでこのメッセージが表示されます:

```elixir
iex(alex@localhost)> how are you?
```

コードに戻って詳しく見てみましょう。

監視されたタスクを実行したいリモートノードの名前と、そのノードに送信したいメッセージを受け取る `Chat.send_message/2` 関数を持っています。

この関数は `spawn_task/4` 関数を呼び出し、指定された名前のリモートノード上で非同期タスクを実行して、 `Chat.TaskSupervisor` によってリモートノードで監視されます。
そのノード _も_ チャットアプリケーションのインスタンスを実行しているので、 `Chat.TaskSupervisor` がチャットアプリのスーパービジョンツリーの一部として開始されているため、 `Chat.TaskSupervisor` という名前でタスクスーパーバイザがそのノードで実行されていることがわかります。

`Chat.TaskSupervisor` には、 `send_message/2` から `spawn_task/4` に渡されるメッセージの引数とともに `Chat.receive_message` 関数を実行するタスクを監視するように指示しています。

そのため、 `Chat.receive_message("hi")` はリモードノードの `kate` で呼び出され、 `"hi"` というメッセージをそのノードの標準出力ストリームへと流します。
この場合、タスクはリモートノード上で監視されているので、そのノードがこのI/Oプロセスのグループマネージャになります。

### リモートノードのメッセージへの返信

チャットアプリをもう少し賢くしてみましょう。
今のところ、任意の数のユーザーが名前のついた `iex` セッションでアプリケーションを実行してチャットを開始できます。
ですが、チャットを離れたくないMoebiという名前の中型の白い犬がいるとしましょう。
Moebiはチャットアプリに参加していたいですが、彼は犬なので悲しいことにどうやってタイプするかわかりません。
なので、私たちは `Chat` モジュールに対し、Moebiに代わる `moebi@localhost` というノードに対して送られたどのようなメッセージに対しても返信するよう教えます。
彼の唯一の望みはチキンを食べることなので、Moebiに対して何を言おうと彼は `"chicken?"` と返答します。

`recipient` 引数をパターンマッチする別のバージョンの `send_message/2` 関数を定義します。
もしrecipientが `:moebi@localhost` であれば

- `Node.self()` を使って現在のノードの名前を取得します
- 現在のノード、つまり
  送信側の名前を、新しい関数 `receive_message_for_moebi/2` に渡して、メッセージをそのノードに送り _返す_ ことができるようにします

```elixir
# lib/chat.ex
...
def send_message(:moebi@localhost, message) do
  spawn_task(__MODULE__, :receive_message_for_moebi, :moebi@localhost, [message, Node.self()])
end
```

次に、 `IO.puts` で `moebi` ノードの標準出力に出力し、 _そして_ メッセージを送信側に送り返す `receive_message_for_moebi/2` 関数を定義します:

```elixir
# lib/chat.ex
...
def receive_message_for_moebi(message, from) do
  IO.puts message
  send_message(from, "chicken?")
end
```

オリジナルのメッセージを送信したノードの名前 ("送信ノード") を指定して `send_message/2` を呼ぶことで、 _リモート_ ノードに対して監視されたタスクを送信ノードに戻すように指示します。

実際に見てみましょう。
3つの異なるターミナルウィンドウで、別々の名前のノードを開始します:

```bash
iex --sname alex@localhost -S mix
```

```bash
iex --sname kate@localhost -S mix
```

```bash
iex --sname moebi@localhost -S mix
```

`alex` に `moebi` へとメッセージを送らせましょう:

```elixir
iex(alex@localhost)> Chat.send_message(:moebi@localhost, "hi")
chicken?
:ok
```

`alex` ノードは `"chicken?"` という返信を受け取ったことがわかります。
`kate` ノードを確認すると、 `alex` も `moebi` も何も送っていないので、メッセージが来ていないことがわかります(ごめんね `kate`)。
`moebi` ノードのターミナルウィンドウを開くと、 `alex` が送ったメッセージが確認できます:

```elixir
iex(moebi@localhost)> hi
```

## 分散コードのテスト

`send_message` 関数の簡単なテストを書いてみましょう。

```elixir
# test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

`mix test` でテストを実行すると、以下のエラーで失敗することがわかります:

```elixir
** (exit) exited in: GenServer.call({Chat.TaskSupervisor, :moebi@localhost}, {:start_task, [#PID<0.158.0>, :monitor, {:sophie@localhost, #PID<0.158.0>}, {Chat, :receive_message_for_moebi, ["hi", :sophie@localhost]}], :temporary, nil}, :infinity)
         ** (EXIT) no connection to moebi@localhost
```

`moebi@localhost` という名前のノードは実行されていないために接続することができないので、このエラーは当然です。

いくつかのステップを実行することで、このテストをパスさせることができます:

- もう1つのターミナルウィンドウを開いて、名前つきノードを開始します: `iex --sname moebi@localhost -S mix`
- 最初のターミナルで名前付きノードを通してテストを実行し、 `iex` セッションの中でmixテストを実行します: `iex --sname sophie@localhost -S mix test`

これは作業が多く、自動化されたテストプロセスとはとても考えられません。

ここでは2つの異なるアプローチを取ることができます:

1.
必要なノードが実行されていない場合、分散ノードを必要とするテストを条件分岐で除外する。

2.
テスト環境ではリモートノード上でのタスク生成をしないようにアプリケーションを構成する。

1つ目のアプローチについて見てみましょう。

### タグによるテストの条件付き除外

このテストに `ExUnit` タグを追加します:

```elixir
#test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  @tag :distributed
  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

そして、テストが名前付きノードで実行 _されていない_ 場合にそのタグを持つテストを除外するため、条件分岐ロジックをテストヘルパーに追加します。

```elixir
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
```

ここではノードが生きているかどうか、つまり、
[`Node.alive?`](https://hexdocs.pm/elixir/Node.html#alive?/0) でノードが分散システムの一部であるかどうかをチェックします。
もし生きていなければ、 `ExUnit` に `distributed: true` タグを持つ全てのテストをスキップするよう伝えます。
そうではない場合、どのテストも除外しないように指示します。

さて、以前の `mix test` を実行すると、次のようになります:

```bash
mix test
Excluding tags: [distributed: true]

Finished in 0.02 seconds
1 test, 0 failures, 1 excluded
```

そして、分散テストを実行したい場合には、単に前のセクションで述べたステップを実行する必要があります: `moebi@localhost` ノードを開始し、 _さらに_ `iex` を通して名前付きノードでテストを実行します。

他のテストアプローチ、つまり異なる環境では異なる振る舞いとなるアプリケーションの設定について見てみましょう。

### 環境固有のアプリケーション構成

`Task.Supervisor` にリモートノードで監視されたタスクの開始を指示するコードの一部は次の通りです:

```elixir
# app/chat.ex
def spawn_task(module, fun, recipient, args) do
  recipient
  |> remote_supervisor()
  |> Task.Supervisor.async(module, fun, args)
  |> Task.await()
end

defp remote_supervisor(recipient) do
  {Chat.TaskSupervisor, recipient}
end
```

`Task.Supervisor.async/5` は1つ目の引数に使用したいスーパーバイザを取ります。
`{SupervisorName, location}` というタプルを渡すと、指定されたノードで指定されたスーパーバイザを開始します。
しかし、 `Task.Supervisor` の1つ目の引数にスーパーバイザの名前だけを渡すと、ローカルでタスクを監視するためにスーパーバイザを使用します。

`remote_supervisor/1` 関数を環境に応じて設定可能となるようにしましょう。
開発環境では、これは `{Chat.TaskSupervisor, recipient}` を返し、テスト環境では `Chat.TaskSupervisor` を返します。

アプリケーション変数を通してこれを行います。

`config/dev.exs` ファイルを作成し、以下を追加します:

```elixir
# config/dev.exs
use Mix.Config
config :chat, remote_supervisor: fn(recipient) -> {Chat.TaskSupervisor, recipient} end
```

`config/test.exs` を作成し、以下を追加します:

```elixir
# config/test.exs
use Mix.Config
config :chat, remote_supervisor: fn(_recipient) -> Chat.TaskSupervisor end
```

`config/config.exs` で、この行のコメントを外すことを忘れないでください:

```elixir
import_config "#{Mix.env()}.exs"
```

最後に、 `Chat.remote_supervisor/1` 関数を更新して、新しいアプリケーション変数に格納された値を見るようにします:

```elixir
# lib/chat.ex
defp remote_supervisor(recipient) do
  Application.get_env(:chat, :remote_supervisor).(recipient)
end
```

## 最後に

Erlang VMの力で持っているElixirのネイティブの分散機能は、それを強力なツールにする機能の1つです。
Elixirが持つ分散コンピューティングの処理能力を利用して、並行なバックグラウンドジョブの実行や、高性能アプリケーションのサポートなどを想像することができます。

このレッスンでは、Elixirの分散の概念についての基本的な紹介と、分散アプリケーションの構築を始めるために必要なツールを紹介しました。
監視付きタスクを使用することで、分散アプリケーションのさまざまなノードにメッセージを送信できます。
