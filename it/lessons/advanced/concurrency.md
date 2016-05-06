---
layout: page
title: Concorrenza
category: advanced
order: 4
lang: it
---

Uno dei punti di forza di Elixir è il suo supporto alla concorrenza. Grazie alla ErlangVM, scrivere programmi concorrenti in Elixir è più semplice di quanto uno possa aspettarsi. Il modello di concorreza si basa sugli Attori, processi indipendenti che comunicano con altri processi, attraverso il passaggio di messaggi.

In questa lezione daremo un'occhiata ai moduli sulla concorrenza che vengono provveduti con l'installazione di Elixir. Nel prossimo capitolo, ci occupiamo dei _behaviour OTP_ che ci permettono di scrivere programmi concorrenti.

## Tavola dei Contenuti

- [Processi](#processi)
  - [Message Passing](#message-passing)
  - [Process Linking](#process-linking)
  - [Process Monitoring](#process-monitoring)
- [Agenti](#agenti)
- [Task](#task)

## Processi

I processi che vivono nella ErlangVM sono leggeri, e possono tenere occupate tutte le CPU del sistema. Nonostante questi possano sembrare thread nativi, i processi Erlang sono più semplici, e non è raro trovare migliaia di processi concorrenti in un'applicazione Elixir.

Il modo più semplice per lanciare un processo è attraverso il comando `spawn`, che accetta una funzione anonima o pre-definita. Quando creiamo un processo, il suo _Process Identifier_, o PID, ci viene restituito; con esso, possiamo identificare unicamente il processo creato all'interno della nostra applicazione.

Per iniziare, creiamo un modulo e definiamo una funzione che vorremmo lanciare:

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

Per lanciare la stessa funzione in modo asincrono, usiamo `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Message Passing

Per comunicare, i processi usano _message passing_. A riguardo, ritroviamo due componenti principali: `send/2` e `receive/1`. La funzione `send/2` ci permette di mandare message ad altri PID; per ascoltare per messaggi in arrivo, usiamo `receive/1` ed (opzionalmente) eseguiamo un _match_ sui messaggi in arrivo. Se un messaggio non soddisfa nessun _match_, il processo ignora il messaggio e continua ininterrotto.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts "World"
    end
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

### Process Linking

Un problema con `spawn` è sapere quando il processo lanciato muore. Per questo motivo, abbiamo bisogno di collegare i nostri processi, usando `spawn_link`. Due processi collegati riceveranno notifiche d'uscita vicendevolmente.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) :kaboom
```

A volte, non vogliamo che un processo collegato uccida il processo che l'ha creato. Per evitare questo, dobbiamo _intrappolare le uscite_ nel processo genitore. Quando intrappoliamo uscite in un processo, questo riceverà solo messaggi di notifica in questa forma: `{:EXIT, dal_pid, ragione}`.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
  def run do
    Process.flag(:trap_exit, true)
    spawn_link(Example, :explode, [])

    receive do
      {:EXIT, from_pid, reason} -> IO.puts "Exit reason: #{reason}"
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

### Process Monitoring

Cosa facciamo quando non vogliamo che due processi siano collegati, ma rimangano comunque informati sull'altro? In questo caso, possiamo fare _process monitoring_ con `spawn_monitor`. Quando monitoriamo un processo, riceviamo un messaggio quando questo muore, senza preoccuparci di ripercussioni sul processo corrente, e senza dover intrappolare uscite.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
  def run do
    {pid, ref} = spawn_monitor(Example, :explode, [])

    receive do
      {:DOWN, ref, :process, from_pid, reason} -> IO.puts "Exit reason: #{reason}"
    end
  end
end

iex> Example.run
Exit reason: kaboom
:ok
```

## Agenti

Gli Agenti sono astrazioni attorno a dei processi di background, che mantengono uno stato interno. Possiamo accedere ad agenti da altri processi all'interno della nostra applicazione (e nodo). Lo stato di un agente è determinato dal valore di ritorno della funzione che lo inizializza, o aggiorna:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Dando un nome ad un agente, possiamo comunicare con esso senza sapere il suo PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Task

I Task rendono possibile eseguire una funzione in background, della quale possiamo ottenere il valore di ritorno in futuro. I Task possono essere particolarmente utili quando abbiamo a che fare con operazioni costose, e vogliamo evitare di bloccare l'esecuzione della nostra applicazione.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# Fai delle operazioni

iex> Task.await(task)
4000
```
