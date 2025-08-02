%{
  version: "1.0.4",
  title: "Współbieżność z OTP",
  excerpt: """
  Poznaliśmy już abstrakcję do obsługi współbieżności, jaką oferuje Elixir, ale czasami potrzebujemy większej kontroli nad tym, co się dzieje, dlatego też możemy chcieć użyć zachowań OTP, na których zbudowany jest Elixir.
  
  W tej lekcji skupimy się na istotniejszym elemencie: GenServer
  """
}
---

## GenServer

Serwer OTP zawiera moduł zachowań GenServer, który implementuje zestaw wywołań zwrotnych (ang. _callback_).
W dużym uproszczeniu GenServer to pętla, w której każda iteracja odpowiada obsłudze jednego żądania, które aktualizuje stan aplikacji.

Zademonstrujemy działanie API GenServer, implementując prostą kolejkę.

By uruchomić GenServer, musimy go wystartować oraz obsłużyć procedurę inicjacji.
W większości przypadków chcemy obsłużyć łączenie procesów, dlatego używamy `GenServer.start_link/3`.
Przekazujemy do modułu GenServer argumenty startowe i zestaw opcji.
Argumenty zostaną przekazane do funkcji `GenServer.init/1`, która na ich podstawie utworzy stan początkowy poprzez zwracaną przez nią wartość.
W naszym przykładzie argumenty i stan początkowy będą takie same:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Uruchom naszą kolejkę i połącz jej proces.
  Jest to funkcja pomocnicza.
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

Często zadania zlecane GenServerom muszą być wykonywane w sposób synchroniczny — po wywołaniu funkcji czekamy na rezultat.
By obsłużyć synchroniczne żądania, musimy zaimplementować funkcję zwrotną `GenServer.handle_call/3`, która jako parametry przyjmuje: żądanie, PID procesu wywołującego, stan; oczekiwana odpowiedź to z kolei krotka w postaci: `{:reply, odpowiedź, stan}`.

Wykorzystując dopasowania wzorców, możemy zdefiniować wiele różnych wywołań zwrotnych, w zależności od żądania i stanu.
Pełna dokumentacja zawierająca listę parametrów i zwracanych wartości znajduje się w dokumentacji [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3).

By zademonstrować wywołanie synchroniczne, dodajmy do naszej kolejki możliwość wyświetlenia zawartości i usunięcia jednej z wartości:

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

Wystartujmy naszą aplikację `SimpleQueue` i przetestujmy jej nowe funkcje:

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

Wywołania asynchroniczne są obsługiwane przez `handle_cast/2`.
Działają podobnie jak `handle_call/3`, a jedynymi różnicami są brak PID wywołującego oraz to, że nie oczekujemy żadnej odpowiedzi.

Zaimplementujemy dodawanie elementów do kolejki jako funckję asynchroniczną, dzięki czemu dodając element nie będziemy blokować działania programu:

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

Spróbujmy użyć naszej nowej funkcji:

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

Więcej informacji znajdziesz w oficjalnej dokumentacji [GenServer](https://hexdocs.pm/elixir/GenServer.html#content).
