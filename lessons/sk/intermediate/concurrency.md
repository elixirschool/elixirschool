%{
  version: "1.0.1",
  title: "Konkurentnosť",
  excerpt: """
  Jednou z výhod Elixiru je jeho podpora konkurentnosti. Vďaka Erlang VM (BEAM), konkurentnosť v Elixire je jednodušia než by človek čakal. Model konkurentnosti sa spolieha na Actorov, ktorí predstavujú uzavretý proces, ktorý komunikuje s ostatnými procesmi pomocou odosielania správ.

V tejto lekcii sa pozrieme na konkurentné moduly, ktoré sú dodávané spolu s Elixirom. V nasledujúcej kapitole pokryjeme správania OTP, ktoré ich implementujú.
  """
}
---

## Procesy

Procesy v Erlang VM sú ľahké a dokážu používať všetky CPU. Môže sa zdať, že sa podobajú na natívne vlákna, ale sú jednoduchšie a nie je nevídané mať tisíce konkurentných procesov v Elixir aplikácii.

Najjednoduchší spôsob ako vytvoriť nový proces je použiť funkciu `spawn`, ktorá potrebuje anonymnú alebo pomenovanú funkciu. Keď vytvoríme nový proces, vráti nám _Process Identifier_ alebo PID, ktorý jednoznačne identifikuje proces našej aplikácie.

Na začiatok vytvoríme modul a definujeme funkciu, ktorú chceme spustiť:

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

Keď chceme vyhodnotiť funkciu asynchrónne, použijeme `spawn/3`:

```elixir
iex> spawn(Example, :add, [2, 3])
5
#PID<0.80.0>
```

### Posielanie správ

Procesy sa spoliehajú na posielanie správ, ktoré im umožňuje medzi sebou komunikovať. To má dva komponenty: `send/2` a `receive`. Funkcia `send/2` nám dovoľuje poslať správy daným PID. Na prijatie správy použijeme `receive`, ktorý matchne správy. Ak sa nenájde žiadna vyhovujúca správa vykonávanie pokračuje bez prerušenia.

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

Možno si všimnete, že funkcia `listen/0` je rekurzívna, čo umožňuje našim procesom spracovávať viacero správ. Bez rekurzie by náš proces zanikol po prvej správe.

### Prepojenie Procesov

Jedným problémom so `spawn` je, že nevieme kedy proces spadol. Na to musíme naše procesy prepojiť pomocou `spawn_link`. Dva prepojené procesy dostanú jeden od druhého správu o tom že proces zanikol:

```elixir
defmodule Example do
  def explode, do: exit(:kaboom)
end

iex> spawn(Example, :explode, [])
#PID<0.66.0>

iex> spawn_link(Example, :explode, [])
** (EXIT from #PID<0.57.0>) :kaboom
```

Niekedy ale nechceme aby naše prepojené procesy zhodili náš aktuálny proces. Na to potrebujeme zachytiť zaniknutie procesu. Keď dostaneme správu o zaniknutí procesu, bude v tvare tuple: `{:EXIT, from_pid, reason}`.

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

### Monitorovanie Procesov

Čo ak nechceme prepojiť dva procesy, ale chceme o nich mať informácie? Na to môžeme použiť monitorovanie procesov s funkciou `spawn_monitor`. Keď monitorujeme proces dostaneme správu ak proces spadne bez toho aby spadol náš aktuálny proces alebo ak potrebujeme explicitne zachytiť zaniknutie procesu.

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

Agenti sú abstrakcia procesov na pozadí, ktoré si uchovávajú stav. Môžeme k nim pristupovať z iných procesov v našej aplikácii a node. Stav nášho Agenta je nastavený návratovou hodnotou našej funkcie:

```elixir
iex> {:ok, agent} = Agent.start_link(fn -> [1, 2, 3] end)
{:ok, #PID<0.65.0>}

iex> Agent.update(agent, fn (state) -> state ++ [4, 5] end)
:ok

iex> Agent.get(agent, &(&1))
[1, 2, 3, 4, 5]
```

Keď pomenujeme Agenta, môžeme menom na neho odkazovať namiesto PID:

```elixir
iex> Agent.start_link(fn -> [1, 2, 3] end, name: Numbers)
{:ok, #PID<0.74.0>}

iex> Agent.get(Numbers, &(&1))
[1, 2, 3]
```

## Tasky

Tasky poskytujú spôsob ako vykonať funkciu na pozadí a získať jej návratovú hodnotu neskôr. Môžu byť veľmi užitočné najmä vtedy, keď vykonávame výpočtovo náročné operácie, pretože neblokujú vykonávanie samotnej aplikácie.

```elixir
defmodule Example do
  def double(x) do
    :timer.sleep(2000)
    x * 2
  end
end

iex> task = Task.async(Example, :double, [2000])
%Task{pid: #PID<0.111.0>, ref: #Reference<0.0.8.200>}

# Do some work

iex> Task.await(task)
4000
```
