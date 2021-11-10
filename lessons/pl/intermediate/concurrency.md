%{
  version: "1.1.1",
  title: "Współbieżność",
  excerpt: """
  Jednym z najbardziej wartościowych elementów Elixira jest obsługa współbieżności.
  Dzięki temu, że działa on na maszynie wirtualnej Erlanga, zadanie to zostało bardzo uproszczone.
  Współbieżność oparta jest o model aktorów, reprezentowanych przez procesy, które komunikują się, wymieniając wiadomości.
  """
}
---

## Procesy

Maszyna wirtualna Erlanga używa procesów lekkich, które mogą działać na wszystkich dostępnych dla niej procesorach.
Choć są one podobne do natywnych, systemowych wątków, to jednak są prostsze i nie jest niczym niezwykłym, gdy w aplikacji napisanej w Elixirze jednocześnie działa kilka tysięcy procesów.

Najprostszą metodą na utworzenie nowego procesu jest wywołanie `spawn`, która jako argument przyjmuje funkcję, nazwaną lub anonimową.
Kiedy utworzy nowy proces zwróci _Identyfikator procesu_, czyli PID, który w sposób unikalny identyfikuje proces w naszej aplikacji.

Zacznijmy od stworzenia nowego modułu i zdefiniowania w nim funkcji, którą będziemy uruchamiać:

```elixir
defmodule Example do
  def add(a, b) do
    IO.puts(a + b)
  end
end

iex> Example.add(2, 3)
5
:ok
```

By wywołać ją asynchronicznie wywołajmy `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Przekazywanie komunikatów

Komunikacja pomiędzy procesami bazuje na wymianie komunikatów.
Istnieją dwa główne elementy tego mechanizmu: `send/2` i `receive`.
Funkcja `send/2` pozwalana na wysłanie komunikatu pod wskazany PID.
Przychodzących komunikatów nasłuchujemy za pomocą `receive` i dopasowujemy je do wzorców.
Jeżeli komunikat nie zostanie dopasowany, to proces zignoruje go i będzie kontynuować działanie, jak gdyby nic się nie stało.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen()
  end
end

iex> pid = spawn(Example, :listen, [])
#PID<0.108.0>

iex> send pid, {:ok, "hello"}
World
{:ok, "hello"}

iex> send pid, :ok
:ok
```

Warto zauważyć, że funkcja `listen/0` jest rekurencyjna.
Dzięki temu może ona obsługiwać kolejno nadchodzące wiadomości.
Bez tego mechanizmu proces zakończyłby działanie po obsłużeniu pierwszej wiadomości.

### Łączenie procesów

Problem z funkcją `spawn` polega na tym, że nie wiemy, kiedy proces ulegnie awarii.
Dlatego też potrzebujemy procesów połączonych, które tworzy się z użyciem `spawn_link`.
Dwa połączone procesy będą nawzajem otrzymywać komunikaty o swoim zakończeniu:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Czasami nie chcemy by awaria jednego procesu spowodowała zamknięcie połączonego z nim innego procesu.
Dlatego też musimy przechwycić informacje o zamknięciu korzystając z `Process.flag/2`.
Wykorzystana zostaje funkcja [process_flag/2](http://erlang.org/doc/man/erlang.html#process_flag-2) dla flagi `trap_exit`.
Podczas przechwytywania wyjść (`trap_exit` jest ustawione na `true`), sygnały wyjścia będą odbierane jako wiadomość w postaci krotki: `{:EXIT, from_pid, reason}`.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### Monitoring

A co, jeżeli nie chcemy łączyć procesów, ale chcemy nadal być informowani o awariach?
Do tego służy mechanizm monitoringu `spawn_monitor`.
Gdy monitorujemy inny proces z naszego procesu, to gdy otrzymamy wiadomość o jego awarii, nasz proces nie ulegnie awarii ani też nie będziemy musieli jawnie obsłużyć sygnału zamknięcia.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, _ref, :process, _from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Agenci

Agenci są pewnego rodzaju abstrakcją nad procesami służącą do zarządzania ich stanem w tle.
Możemy się do nich odwołać z poziomu innego procesu aplikacji albo innego węzła.
Aktualny stan agenta jest równy wartości zwracanej przez naszą funkcję:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Do nazwanych agentów możemy odwołać się przez nazwę zamiast przez PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Zadania

Zadania pozwalają na wywołanie funkcji w tle i otrzymanie wyniku w późniejszym terminie.
Jest to przydatne szczególnie wtedy, gdy funkcja wykonuje jakieś długotrwałe obliczenia albo jest operacją blokującą.
Można wtedy wywołać ją bez blokowania całej aplikacji.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{
  owner: #PID<0.105.0>,
  pid: #PID<0.114.0>,
  ref: #Reference<0.2418076177.4129030147.64217>
}

# Coś się kręci

iex> Task.await(task)
4000
```
