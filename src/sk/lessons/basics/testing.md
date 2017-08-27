---
version: 0.9.1
title: Testovanie
---

Testovanie je dôležitou súčasťou vývoja softvéru. V tejto lekcii sa pozrieme na to, ako testovať náš elixirový kód pomocou knižnice ExUnit a na testovacie *best practices*.

{% include toc.html %}

## ExUnit

Elixir má zabudovaný testovací framework ExUnit, ktorý obsahuje všetko, čo potrebujeme na dôkladné otestovanie nášho kódu. Než s ním začneme, je dôležité spomenúť, že ExUnit testy sa implementujú ako elixirové skripty, takže pre súbory s testami musíme použiť príponu `.exs`. Pred spustením testov ešte musíme naštartovať samotný ExUnit. Bežne sa to robí v súbore `test/test_helper.exs`.

Keď sme si v minulej lekcii vygenerovali nový projekt, mix nám vygeneroval rovno aj jednoduché základné testy v súbore `test/example_test.exs`.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Kompletnú sadu testov nášho projektu môžeme spustiť príkazom `mix test`. Keď to urobíme v našom vygenerovanom projekte, mali by sme dostať niečo takéto:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Každý kto sa už niekedy stretol s automatickými testami softvéru, určite pozná príkaz `assert` (v niektorých testovacích frameworkoch `should`, či `expect`). Toto makro testuje, či sa daný výraz vyhodnotí ako `true`. Ak nie, vyhodí chybu a test zlyhá. Pozrime sa na príklad takéhoto zlyhania - upravme náš test a spustime ho príkazom `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "pravda" do
    assert 1 + 1 == 3
  end
end
```

Tentoraz by sme mali vidieť celkom odlišný výstup:

```shell
  1) test pravda (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnit nám povie úplne presne, kde (na ktorom asserte) testy zlyhali, aká bola očakávaná hodnota a aká bola skutočná hodnota.

### refute

Opakom príkazu `assert` je príkaz `refute`. Použijeme ho v prípade, že chceme testovať, či sa daný výraz vyhodnotí ako `false`.

### assert_raise

Niekedy potrebujeme testovať, že kód vyhodí chybu (prípadne konkrétny typ chyby) - na to sa nám hodí príkaz `assert_raise`. Príklad použitia je v lekcii o knižnici Plug.

## Setup

Niekedy potrebujeme pred samotnými testami vykonať nejaké pomocné činnosti. S tým nám pomôžu makrá `setup` a `setup_all`. Blok kódu v makre `setup` sa vykoná pred každým jednotlivým testom, blok v makre `setup_all` sa vykoná len raz - na začiatku pred spustením prvého testu. Oba bloky by mali vrátiť tuple v tvare `{:ok, stav}`, pričom `stav` bude dostupný v jednotlivých testoch.

Ako príklad si do nášho súboru s testami doplníme blok `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "pravda", state do
    assert 1 + 1 == state[:number]
  end
end
```

## Mockovanie

Niektoré testovacie frameworky využívajú techniku mockovania, čiže podsúvania atráp rôznych objektov a funkcií testovanému kódu. Elixir sa však tomuto vyhýba a vývojárov od nej odradzuje. Ak vo svojom kóde dodrživate zásady dobrého funkcionálneho návrhu, mockovanie nikdy potrebovať nebudete, pretože svoje moduly a funkcie budete môcť jednoducho testovať na individuálnej úrovni.

Odolajte pokušeniu.
