---
version: 1.0.3
title: OTPの並行性
---

並行性(コンカレンシー)に関するElixirの抽象化を見てきましたが、さらなる制御が必要になることもあります。そうした時のために、Elixirに組み込まれているOTPの振る舞いに目を向けます。

このレッスンではGenServerという重要な要素に焦点を当てます。

{% include toc.html %}

## GenServer

OTPサーバーは一連のコールバックを実装するGenServerの振る舞いをもったモジュールです。
最も基本的なレベルでは、GenServerは単一プロセスであり、更新された状態を伝える反復処理のたびにに1つのメッセージを処理するループを実行します。

GenServerのAPIを実演するために、値を格納し読みだす基本的なキューを実装します。

GenServerを始めるには、起動し、初期化処理を行う必要があります。
ほとんどの場合、プロセスをリンクしたいので `GenServer.start_link/3` を用います。
開始したGenServerモジュールに、初期化用の引数と一連のGenServerオプションを渡します。
これらの引数は `GenServer.init/1` に渡され、その戻り値を通して、初期状態が設定されます。
私たちの例では、引数が初期状態になります:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  キューを開始し、リンクします。
  これはヘルパー関数です。
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1コールバック
  """
  def init(state), do: {:ok, state}
end
```

### 同期関数

GenServerと同期的な方法、つまり関数を呼びその返答を待つという方法でやりとりをする必要がよくあります。
同期リクエストを処理するには、 `GenServer.handle_call/3` コールバックを実装する必要があります。これはリクエスト、呼び出し側のPIDと、既存の状態を受け取ります。そして返答は `{:reply, response, state}` のタプルを返すことが期待されます。

パターンマッチングを用いて、多くの異なるリクエストや状態へのコールバックを定義することができます。
認められている戻り値の一覧は [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3) のドキュメントで見つけることができます。

同期的なリクエストを実演するために、現在のキューを表示できて、値を取り除くことができる能力を付け加えましょう:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1コールバック
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3コールバック
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### クライアント側API / ヘルパー関数

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

SimpleQueueを開始し、新しいdequeue (キューから値を取り出す)機能をテストしましょう:

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

非同期リクエストは `handle_cast/2` コールバックを用いて処理されます。
これは `handle_call/3` によく似た働きをしますが、呼び出し側PIDを受け取らず、返答することも期待されていません。

enqueue(キューに値を入れる)機能を非同期、つまりキューを更新するけれども現在実行中の処理を遮らないように実装します:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1コールバック
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3コールバック
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2コールバック
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### クライアント側API / ヘルパー関数

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

より詳しい情報については、公式の [GenServer](https://hexdocs.pm/elixir/GenServer.html#content) ドキュメントを調べてみてください。
