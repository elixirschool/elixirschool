---
layout: page
title: Współbieżność z OTP
category: advanced
order: 5
lang: pl
---

Poznaliśmy już abstrakcję do obsługi współbieżności, jaką oferuje Elixir. Czasami potrzebujemy większej kontroli nad
tym, co się dzieje. Dlatego też Elixir ma obsługę zachowań OTP.  

W tej lekcji skupimy się na dwóch elementach: GenServers i GenEvents.

{% include toc.html %}

## GenServer

Serwer OTP zawiera moduł zachowań GenServer, który implementuje zestaw wywołań zwrotnych (ang. callback). W dużym 
uproszczeniu GenServer to pętla, w której każda iteracja odpowiada obsłudze jednego żądania, które aktualizuje stan 
aplikacji.  

By pokazać jak działa GenServer, zaimplementujemy prostą kolejkę.

By uruchomić GenServer, musimy go wystartować oraz obsłużyć procedurę inicjacji. W większości przypadków chcemy 
obsłużyć łączenie procesów, dlatego użyjemy `GenServer.start_link/3`. Przekażemy do modułu GenServer argumenty 
startowe i niewielki zestaw opcji. Argumenty zostaną przekazane do funkcji `GenServer.init/1`, która na ich podstawie
 utworzy początkowy stan aplikacji. W naszym przykładzie argumenty i stan początkowy będą takie same:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.  This is a helper method
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

### Funkcje synchroniczne

Czasami zadania zlecane GenServer muszą być wykonywane w sposób synchroniczny, czyli wywołujemy funkcję i czekamy na 
rezultat. By sprostać temu wyzwaniu, musimy zaimplementować funkcję zwrotną `GenServer.handle_call/3`, która jako 
parametry przyjmuje: 

 * żądanie
 * PID procesu wywołującego
 * stan
 
W odpowiedzi musi zwrócić krotkę w postaci: `{:reply, odpowiedź, stan}`.

Wykorzystując dopasowania wzorców, możemy zdefiniować wiele wywołań zwrotnych, w zależności od żądania i stanu. Pełna
dokumentacja zawierająca listę parametrów i zwracanych wartości znajduje się w dokumentacji [`GenServer.handle_call/3`]
(http://elixir-lang.org/docs/v1.1/elixir/GenServer.html#c:handle_call/3).

By zademonstrować wywołanie synchroniczne, dodajmy do naszej kolejki, możliwość wyświetlenia zawartości i usunięcia 
jednej z wartości:

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
  def handle_call(:dequeue, _from, [value|state]) do
    {:reply, value, state}
  end
  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper methods

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end

```

Wystartujmy naszą aplikację `SimpleQueue` i przetestujmy nowe funkcjonalności:

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

### Funkcje asynchroniczne

Wywołania asynchroniczne są obsługiwane przez `handle_cast/2`.  Działają podobnie jak `handle_call/3`, a jedynymi 
różnicami są brak PID wywołującego oraz to, że nie oczekujemy wartości zwracanej.

Zaimplementujmy dodawanie elementów do kolejki jako asynchroniczne. Dzięki temu, dodając element nie będziemy blokować
 działania programu:

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
  def handle_call(:dequeue, _from, [value|state]) do
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

  ### Client API / Helper methods

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end
  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Spróbujmy użyć naszej nowej funkcjonalności:

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

Więcej informacji znajdziesz w oficjalnej dokumentacji [GenServer](http://elixir-lang.org/docs/v1.1/elixir/GenServer.html#content).

## GenEvent

Wiemy już jak z pomocą GenServer obsługiwać żądania synchroniczne i asynchroniczne. Czym jest GenEvent? GenEvent to 
generyczny manager zdarzeń, który po otrzymaniu informacji powiadamia zainteresowanych konsumentów. Posiada mechanizm
 do dynamicznego dodawania i usuwania obsługi konkretnych zdarzeń.  

### Obsługa zdarzeń

Najważniejszą funkcją zwrotną z jaką pracujemy w GenEvents, jest `handle_event/2`. Przyjmuje ona jako parametry 
zdarzenie i aktualny stan, a zwraca krotkę: `{:ok, stan}`.

By zademonstrować działanie, uruchomimy GenEvent z dwoma modułami obsługi zdarzeń. Pierwszy zapisze je do dziennika, a
 drugi utrwali je (czysto teoretycznie):

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

    # Save message

    {:ok, state}
  end
end
```

### Wywoływanie zdarzeń

Poza  `handle_event/2` GenEvents posiada też między innymi `handle_call/2`. Za pomocą `handle_call/2`
 możemy obsługiwać konkretne, synchroniczne wiadomości.

Zaktualizujmy  `LoggerHandler` dodając metodę do pobierania bieżącej wiadomości z logu:

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

### Użycie GenEvent

Mając nasze funkcje do obsługi zdarzeń, możemy przejść do innych istotnych funkcji GenEvent. Trzy najważniejsze z nich 
to: `add_handler/3`, `notify/2` i `call/4`. Pozwalają one odpowiednio na dodawanie nowych funkcji obsługi zdarzeń, 
rozgłaszanie wiadomości i wywoływanie konkretnych funkcji obsługi.

Zbierzmy wszytko razem i zobaczmy jak w praktyce to działa:

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

W oficjalnej dokumentacji [GenEvent](http://elixir-lang.org/docs/v1.1/elixir/GenEvent.html#content) znajduje się 
pełna lista funkcji zwrotnych, których możemy użyć.
