%{
  version: "0.9.1",
  title: "Concorrenza",
  excerpt: """
  Uno dei punti di forza di Elixir è il suo supporto alla concorrenza. Grazie alla Erlang VM (BEAM), scrivere programmi concorrenti in Elixir è più semplice di quanto ci si possa aspettare. Il modello di concorrenza si basa sugli Attori, ovvero dei processi concorrenti che mantengono uno stato interno e comunicano con altri attori/processi attraverso lo scambio di messaggi.

In questa lezione daremo un'occhiata ai moduli relativi ai processi concorrenti che vengono forniti dall'installazione di Elixir. Nel prossimo capitolo, ci occuperemo dei behaviour OTP che li implementano.
  """
}
---

## Processi

I processi che vivono nella Erlang VM sono leggeri, e possono tenere occupate tutte le CPU del sistema. Nonostante questi possano sembrare thread nativi, i processi Erlang sono più semplici, e non è raro trovare migliaia di processi concorrenti in un'applicazione Elixir.

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

I processi utilizzano lo scambio di messaggi come metodo di comunicazione, facendo uso di due componenti principali: `send/2` e `receive/1`.  La funzione `send/2` ci permette di mandare messaggi ad altri PID, mentre `receive/1` ci consente di ascoltare quelli in arrivo effettuando un confronto (_match_) opzionale per determinare se il messaggio va considerato o ignorato.

```elixir
defmodule Example do
  def listen do
    receive do
      {:ok, "hello"} -> IO.puts("World")
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

Il componente `spawn` ha un problema: non ci informa quando un processo termina inaspettatamente. Per ovviare a questo inconveniente, possiamo utilizzare la funzione `spawn_link`: in questo modo i due processi collegati riceveranno i rispettivi messaggi di uscita.

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) evaluator process exited with reason: :kaboom
```

Talvolta non vogliamo che un processo "collegato" termini il processo che l'ha creato. Per evitare questa situazione, dobbiamo controllare i messaggi di uscita nel processo padre. Quando controlliamo i messaggi di uscita, questi verranno ricevuti nella seguente forma: `{:EXIT, dal_pid, ragione}`.

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

### Process Monitoring

Cosa possiamo fare quando non vogliamo che due processi siano collegati, ma allo stesso tempo desideriamo venire informati di possibili terminazioni inaspettate? In questo caso, `spawn_monitor` viene in nostro aiuto, permettendoci di monitorare i processi. Quando monitoriamo un processo, veniamo informati da un messaggio quando questo termina, senza preoccuparci di ripercussioni sul processo corrente, e senza dover controllare esplicitamente i messaggi di uscita nei singoli processi.

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

## Agenti

Gli Agenti sono un'astrazione che permette di accedere e manipolare in maniera agevole delle informazioni riguardanti lo stato di una parte di applicazione. Possiamo accedere ad agenti da altri processi all'interno della nostra applicazione (e nodo). Lo stato di un agente è determinato dal valore di ritorno della funzione che lo inizializza o lo aggiorna:

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

I Task rendono possibile eseguire una funzione in background, dalla quale possiamo ottenere il valore di ritorno in un momento successivo. I Task possono essere particolarmente utili quando abbiamo a che fare con operazioni particolarmente onerose in termini di tempo di esecuzione (per esempio una richiesta HTTP), e vogliamo evitare di bloccare l'esecuzione della nostra applicazione.

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
