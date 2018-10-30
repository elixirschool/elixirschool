---
version: 1.1.1
title: Testovanie
---

Testovanie je dôležitou súčasťou vývoja softvéru. V tejto lekcii sa pozrieme na to, ako testovať náš Elixir kód pomocou knižnice ExUnit a na testovacie *best practices*.

{% include toc.html %}

## ExUnit

Elixir má zabudovaný testovací framework ExUnit, ktorý obsahuje všetko, čo potrebujeme na dôkladné otestovanie nášho kódu. Než s ním začneme, je dôležité spomenúť, že ExUnit testy sa implementujú ako Elixir skripty, takže pre súbory s testami musíme použiť príponu `.exs`. Pred spustením testov ešte musíme naštartovať samotný ExUnit s `ExUnit.start()`. Bežne sa to robí v súbore `test/test_helper.exs`.

Keď sme si v minulej lekcii vygenerovali nový projekt, mix nám vygeneroval rovno aj jednoduché základné testy v súbore `test/example_test.exs`.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :world
  end
end
```

Kompletnú sadu testov nášho projektu môžeme spustiť pomocou príkazu `mix test`. Následne by sme mali dostať podobný výstup:

```shell
..

Finished in 0.03 seconds
2 tests, 0 failures
```

Prečo sú vo výstupe dva testy? Pozrime sa na `lib/example.ex`. Mix tam pre nás vytvoril ďalší test, a to doctest.

```elixir
defmodule Example do
  @moduledoc """
  Documentation for Example.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Example.hello
      :world

  """
  def hello do
    :world
  end
end
```

### assert

Každý kto sa už niekedy stretol s automatickými testami softvéru, určite pozná príkaz `assert` (v niektorých testovacích frameworkoch `should`, či `expect`).

Toto makro testuje, či sa daný výraz vyhodnotí ako `true`. Ak nie, vyhodí chybu a test zlyhá. Pozrime sa na príklad takéhoto zlyhania - upravme náš test a spustime ho príkazom `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert Example.hello() == :word
  end
end
```

Teraz by sme mali vidieť celkom iný výstup:

```shell
  1) test greets the world (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code:  assert Example.hello() == :word
     left:  :world
     right: :word
     stacktrace:
       test/example_test.exs:6 (test)

.

Finished in 0.03 seconds
2 tests, 1 failures
```

ExUnit nám povie úplne presne, kde (na ktorom asserte) testy zlyhali, aká bola očakávaná hodnota a aká bola skutočná hodnota.

### refute

Opakom príkazu `assert` je príkaz `refute`. Použijeme ho v prípade, že chceme testovať, či sa daný výraz vyhodnotí ako `false`.

### assert_raise

Niekedy potrebujeme testovať, že kód vyhodí chybu (prípadne konkrétny typ chyby) - na to sa nám hodí príkaz `assert_raise`. Príklad použitia `assert_raise` je v lekcii o knižnici Plug.

### assert_receive

V Elixire, aplikácie pozostávajú z actorov/procesov, ktorí posielajú správy medzi sebou a často chceme otestovať odosielanú správu. Keďže ExUnit beží ako vlastný proces, môže prijímať správy tak ako každý iný proces a môžeme assertnúť pomocou makra `assert_received`:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` nečaká na správy, s `assert_receive` však môžeme špecifikovať kedy čas na prijatie správy vyprší.

### capture_io and capture_log

Zachytávanie výstup aplikácie je možné s pomocou `ExUnit.CaptureIO` bez zmien v pôvodnej aplikácii. Jednoducho vložíme funkciu, ktorá generuje výstup ako argument:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts "Hello World" end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` je ekvivalent použitý, keď chceme zachytávať výstup do `Logger`.

## Test Setup

Niekedy potrebujeme pred samotnými testami vykonať pomocné činnosti. S tým nám pomôžu makrá `setup` a `setup_all`. Blok kódu v makre `setup` sa vykoná pred každým jednotlivým testom, blok v makre `setup_all` sa vykoná len raz - na začiatku pred spustením celej sady testov. Oba bloky by mali vrátiť tuple v tvare `{:ok, stav}`, pričom stav bude dostupný v jednotlivých testoch.

Ako príklad si do nášho súboru s testami doplníme blok `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, recipient: :world}
  end

  test "greets", state do
    assert Example.hello() == state[:recipient]
  end
end
```

## Mockovanie

Jednoduchá odpoveď na mockovanie v Elixire je: nerobte to. Inštinktívne možno siahnete na mocky, ale v komunita Elixiru dôrazne neodporúča z dobrého dôvodu.

Na dlhšiu diskusiu je tu [výborný článok](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/).

Ak vo svojom kóde dodrživate zásady dobrého funkcionálneho návrhu, mockovanie nikdy potrebovať nebudete, pretože svoje moduly a funkcie budete môcť jednoducho testovať na individuálnej úrovni.
