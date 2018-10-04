---
version: 1.0.0
title: OTP Nebenläufigkeit
---

Wir haben uns die Elixir-Abstraktion für Nebenläufigkeit angesehen, aber manchmal hätten wir gern mehr Kontrolle und dafür sehen wir uns OTP behaviors an, auf denen Elixir gebaut wurde.

In dieser Lektion werden wir uns hauptsächlich mit zwei wichtigen Teilen beschäftigen: GenServers.

{% include toc.html %}

## GenServer

Ein OTP-Server ist ein Modul mit dem GenServer behavior, welches ein Set an Callbacks implementiert. Auf dem untersten Level ist ein GenServer eine Schleife, welche einen Request pro Iteration handhabt, indem sie einen aktualisierten Status herum reicht.

Um die GenServer-API zu demonstrieren, werden wir eine einfache Queue implementieren, die Werte speichert und entgegen nimmt.

Um unseren GenServer anzufangen, müssen wir ihn starten und die Initialisierung regeln. In den meisten Fällen wollen wir Prozesse miteinander verbinden, so dass wir `GenServer.start_link/3` benutzen. Wir übergeben das GenServer-Modul, das wir starten, initiale Argumente und ein Set an GenServer-Optionen. Die Argumente werden an `GenServer.init/1` übergeben, was wiederum den initialen Status durch den Rückgabewert setzt. In unserem Beispiel sind die Argumente der initiale Status:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.  This is a helper function
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}
end
```

### Synchrone Funktionen

Oft ist es notwendig mit unserem GenServer in einer synchronen Art und Weise zu interagieren, etwa eine Funktion aufrufen und auf das Ergebnis warten. Um synchrone Requests zu verwalten müssen wir den `GenServer.handle_call/3`-Callback benutzen, welcher benötigt: Den Request, den PID des Aufrufers und den vorhandenen Status; es wird davon ausgegangen, dass er ein Tupel zurückgibt: `{:reply, response, state}`.

Mit pattern matching können wir Callbacks für viele verschiedene Requests und Stati definieren. Eine komplette Liste akzeptierter Rückgabewerte findet sich in der [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3)-Dokumentation.

Um synchrone Requests zu demonstrieren lass uns die Möglichkeit einbauen, unsere aktuelle Queue anzusehen und einen Wert rauszunehmen:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Lass uns unsere SimpleQueue startet und unsere neue dequeue-Funktionalität testen:

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

### Asynchrone Funktionen

Asynchrone Requests werden durch den `handle_cast/2`-Callback behandelt. Dieser arbeitet ähnlich wie `handle_call/3`, bekommt jedoch keinen Aufrufer übergeben und es wird nicht davon ausgegangen, dass er eine Rückgabe hat.

Wir werden unsere enqueue-Funktionalität asynchron implementieren. Die Queue wird aktualisiert, jedoch blockiert der Aufruf nicht unsere aktuelle Ausführung:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Lass uns unsere neue Funktionalität ausprobieren:

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

Für mehr Informationen sieh in die offizielle  [GenServer](https://hexdocs.pm/elixir/GenServer.html#content)-Dokumentation.
