%{
  version: "0.9.1",
  title: "Nebenläufigkeit",
  excerpt: """
  Einer der wichtigsten Gründe für den Einsatz von Elixir ist die eingebaute Unterstützung von Nebenläufigkeit.
  Dank der Erlang VM (BEAM) ist Nebenläufigkeit in Elixir einfacher als erwartet.
  Die Nebenläufigkeit basiert auf dem Actor Model, bei dem ein abgeschlossener Prozess mit anderen Prozessen durch message passing kommuniziert.

  In dieser Lektion werden wir uns die Nebenläufigkeitsmodule anschauen, welche mit Elixir geliefert werden.
  Im darauf folgenden Kapitel werden wir OTP behandeln, die diese Module implementieren.
  """
}
---

## Prozesse

Prozesse in der Erlang VM sind leichtgewichtig und laufen verteilt auf allen CPUs. Während sie wie native Threads wirken sind sie simpler und es ist nicht ungewöhnlich mehrere Tausend nebenläufige Prozesse in einer Elixiranwendung zu haben.

Der einfachste Weg einen Prozess zu erzeugen ist durch `spawn`, welche eine anonyme oder benannte Funktion entgegen nimmt. Wenn wir einen neuen Prozess erzeugen gibt uns dieser einen _Process Identifier_, auch PID genannt, zurück, welcher den Prozess in unserer Anwendung eindeutig identifiziert.

Für den Start schreiben wir ein Modul und definieren eine Funktion, die wir gerne laufen lassen würden:

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

Um die Funktion asynchron auszuwerten benutzen wir `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Message Passing

Zur Kommunikation benutzen Prozesse message passing. Zwei Komponenten werden hierfür benötigt: `send/2` und `receive`. Die Funktion `send/2` erlaubt uns Nachrichten an PIDs zu schicken. Auf der anderen Seite nutzen wir `receive` um Nachrichten zu empfangen. Falls keine Übereinstimmung gefunden wird läuft die Ausführung ohne Unterbrechung weiter.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
    end

    listen
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

Bei genauer Betrachtung des Codes fällt auf, dass die `listen/0` Funktion rekursiv ist, was unserem Prozess erlaubt mehrere Nachrichten zu empfangen. Ohne Rekursion würde unser Prozess einfach beendet werden, nachdem die erste Nachricht ausgewertet wurde.

### Kopplung von Prozessen

Ein Problem mit `spawn` ist mitzubekommen, wenn ein Prozess abgestürzt ist. Dafür müssen wir unsere Prozesse mit `spawn_link` verbinden. Zwei auf diese Art verbundene Prozesse bekommen mit, sollte der andere abstürzen:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Manchmal wollen wir nicht, dass ein abgestürzter Prozess den aktuelle Prozess zum abstürzen bringt. Dafür müssen wir die exits abfangen. Beim Abfangen von exits werden sie als Nachrichtentupel empfangen: `{:EXIT, from_pid, reason}`.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### Monitoring von Prozessen

Was wenn wir zwei Prozesse nicht verbinden wollen, aber dennoch informiert werden? Dafür können wir Prozesse mit `spawn_monitor` überwachen. Wenn wir einen Prozess überwachen bekommen wir eine Nachricht falls der Prozess abstürzt, ohne dass unser aktueller Prozess mitabstürzt. Ebensowenig müssen wir dazu exits abfangen.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)

  def run do
    {pid, ref} = spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, ref, :process, from_pid, reason} -> IO.puts("Exit reason: #{reason}")
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Agenten

Agenten sind eine Abstraktion über Hintergrundprozesse welche einen Zustand beibehalten. Wir können sie von anderen Prozessen innerhalb unserer Anwendung und aller Knoten abrufen. Der Zustand unserer Agenten wird auf den Rückgabewert unserer Funktion gesetzt:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Durch Benennung eines Agenten können wir diesen direkt ansprechen, anstatt auf dessen PID zurückgreifen zu müssen:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tasks

Tasks erlauben eine Funktion im Hintergrund auszuführen und deren Rückgabewert später zu erhalten. Sie sind besonders nützlich wenn aufwendige Berechnungen durchgeführt werden, ohne die Ausführung der Anwendung zu blockieren.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# Führe langwierige Berechnung durch

iex> Task.await(task)
4000
```
