---
layout: page
title: OTPの並行性
category: advanced
order: 4
lang: jp
---

並行性(コンカレンシー)に関するElixirの抽象化を見てきましたが、さらなる制御が必要になることもあります。そうした時のために、Elixirに組み込まれているOTPの振る舞いに目を向けます。

このレッスンではGenServerとGenEventという2つの重要な要素に焦点を当てます。

{% include toc.html %}

## GenServer

OTPサーバーは一連のコールバックを実装するGenServerの振る舞いをもったモジュールです。最も基本的なレベルでは、GenServerは更新された状態を伝える反復処理のたびにに1つのリクエストを処理するループです。

GenServerのAPIを実演するために、値を格納し読みだす基本的なキューを実装します。

GenServerを始めるには、起動し、初期化処理を行う必要があります。ほとんどの場合、プロセスをリンクしたいので`GenServer.start_link/3`を用います。開始したGenServerモジュールに、初期化用の引数と一連のGenServerオプションを渡します。これらの引数は`GenServer.init/1`に渡され、その戻り値を通して、初期状態が設定されます。私たちの例では、引数が初期状態になります:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  キューを開始し、リンクします。これはヘルパーメソッドです。
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 コールバック
  """
  def init(state), do: {:ok, state}
end
```

### 同期関数

GenServerと同期的な方法、つまり関数を呼びその返答を待つという方法でやりとりをする必要がよくあります。同期リクエストを処理するには、`GenServer.handle_call/3`コールバックを実装する必要があります。これはリクエスト、呼び出し側のPIDと、既存の状態を受け取ります。そして返答は`{:reply, response, state}`のタプルを返すことが期待されます。

パターンマッチングを用いて、多くの異なるリクエストや状態へのコールバックを定義することができます。認められている戻り値の一覧は[`GenServer.handle_call/3`](http://elixir-lang.org/docs/v1.1/elixir/GenServer.html#c:handle_call/3)のドキュメントで見つけることができます。

同期的なリクエストを実演するために、現在のキューを表示できて、値を取り除くことができる能力を付け加えましょう:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 コールバック
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 コールバック
  """
  def handle_call(:dequeue, _from, [value|state]) do
    {:reply, value, state}
  end
  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### クライアント側API / ヘルパーメソッド

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end

```

SimpleQueueを開始し、新しいdequeue(キューから値を取り出す)機能をテストしましょう:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.90.0>}
iex> SimpleQueue.dequeue
1
iex> SimpleQueue.dequeue
2
iex> SimpleQueue.queue
[3]
```

### 非同期関数

非同期リクエストは`handle_cast/2`コールバックを用いて処理されます。これは`handle_cast/3`によく似た働きをしますが、呼び出し側PIDを受け取らず、返答することも期待されていません。

enqueue(キューに値を入れる)機能を非同期、つまりキューを更新するけれども現在実行中の処理を遮らないように実装します:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 コールバック
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 コールバック
  """
  def handle_call(:dequeue, _from, [value|state]) do
    {:reply, value, state}
  end
  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2 コールバック
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### クライアント側API / ヘルパーメソッド

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end
  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

新しい機能を使ってみましょう:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.100.0>}
iex> SimpleQueue.queue
[1, 2, 3]
iex> SimpleQueue.enqueue(20)
:ok
iex> SimpleQueue.queue
[1, 2, 3, 20]
```

より詳しい情報については、公式の[GenServer](http://elixir-lang.org/docs/v1.1/elixir/GenServer.html#content)ドキュメントを調べてみてください。

## GenEvent

私たちは、GenServerが状態を維持し同期/非同期なリクエストを処理することのできるプロセスだと学びました。それではGenEventとは何でしょうか。GenEventは入ってくるイベントを受け取って購読している消費者(イベントを処理するプロセス)に通知を行う、ジェネリック(総称的)なイベントマネージャです。GenEventはイベントの流れに動的にハンドラを追加、削除する仕組みを提供します。

### イベントの処理

GenEventで最も重要なコールバックは、想像がつくように、`handle_event/2`になります。これはイベントとハンドラの現在の状態を受け取って、`{:ok, state}`のタプルを返すことを期待されています。

GenEventの機能を実演するために、2つのハンドラを作ることから始めましょう。1つはメッセージログを預かり、もう片方はそれを(建前としては)永続化するためのものになります:

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts "Logging new message: #{msg}"
    {:ok, [msg|messages]}
  end
end

defmodule PersistenceHandler do
  use GenEvent

  def handle_event({:msg, msg}, state) do
    IO.puts "Persisting log message: #{msg}"

    # メッセージの保存

    {:ok, state}
  end
end
```

### ハンドラの呼び出し

`handle_event/2`に加えて、GenEventは他のコールバックとの間での`handle_call/2`(ハンドラ呼び出し)にも対応しています。`handle_call/2`を用いると、ハンドラで特定の同期メッセージを処理することができます。

`LoggerHandler`を更新して、現在のメッセージログを取り出すメソッドを加えましょう:

```elixir
defmodule LoggerHandler do
  use GenEvent

  def handle_event({:msg, msg}, messages) do
    IO.puts "Logging new message: #{msg}"
    {:ok, [msg|messages]}
  end

  def handle_call(:messages, messages) do
    {:ok, Enum.reverse(messages), messages}
  end
end
```

### GenEventの使用

ハンドラの準備が整ったので、いくつかのGenEventの関数に詳しくなっておく必要があります。最も重要な3つの関数は`:add_handler/3`、`notify/2`、そして`call/4`です。これらの関数によってそれぞれ、ハンドラを追加し、新しいメッセージを配信し、特定のハンドラ関数を呼び出すことができます。

全てを一緒に用いる場合、実際のハンドラは以下のようになります:

```elixir
iex> {:ok, pid} = GenEvent.start_link([])
iex> GenEvent.add_handler(pid, LoggerHandler, [])
iex> GenEvent.add_handler(pid, PersistenceHandler, [])

iex> GenEvent.notify(pid, {:msg, "Hello World"})
Logging new message: Hello World
Persisting log message: Hello World

iex> GenEvent.call(pid, LoggerHandler, :messages)
["Hello World"]
```

コールバックとGenEvent機能の一覧については、公式の[GenEvent](http://elixir-lang.org/docs/v1.1/elixir/GenEvent.html#content)ドキュメントを参照してください。
