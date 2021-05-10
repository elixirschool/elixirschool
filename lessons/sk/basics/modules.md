---
version: 1.3.1
title: Moduly
---

Zo skúsenosti vieme, že je dosť nepohodlné, mať všetky funkcie v jedinom súbore. V tejto lekcii sa naučíme, ako funkcie zoskupovať a definovať špeciálny typ mapy, zvaný *struct*, aby sme mohli náš kód usporiadať efektívnejšie.

{% include toc.html %}

## Moduly

Moduly nám umožňujú organizovať funkcie do menných priestorov (*namespaces*). Definujeme v nich pomenované a privátne funkcie, o ktorých sme si povedali v [lekcii o funkciách](../functions/).

Pozrime sa na jednoduchý príklad:

``` elixir
defmodule Example do
  def pozdrav(meno) do
    ~s(Ahoj #{meno}.)
  end
end

iex> Example.pozdrav "Jano"
"Ahoj Jano."
```

V Elixire je možné definovať moduly vnorené v iných moduloch, čo nám dovoľuje ďalej rozdeľovať funkcionalitu do menších menných priestorov:

```elixir
defmodule Example.Pozdravy do
  def rano(meno) do
    "Dobré ráno #{meno}."
  end

  def vecer(meno) do
    "Dobrý večer #{meno}."
  end
end

iex> Example.Pozdravy.rano "Jano"
"Dobré ráno Jano."
```

### Atribúty modulov

Atribúty sa v Elixirových moduloch najčastejšie používajú ako konštanty:

```elixir
defmodule Example do
  @pozdrav "Ahoj"

  def pozdrav(meno) do
    ~s(#{@pozdrav} #{meno}.)
  end
end
```

Je dôležité zapamätať si, že v Elixire existujú vyhradené atribúty modulov. Najbežnejšie sú tieto tri:

+ `moduledoc` — Slúži na dokumentáciu modulu.
+ `doc` — Dokumentácia funkcie alebo makra.
+ `behaviour` — Indikuje použitie OTP, alebo iného behaviour (chovania) definovaného užívateľom.

## Structs

Structs sú špeciálny typ *máp* s definovanými kľúčmi a ich východiskovými hodnotami. Struct musí byť definovaný v module, z ktorého získa svoj názov. Je bežné, že struct je jediná vec definovaná v module.

Na definovanie structu používame kľúčové slovo `defstruct` nasledované zoznamom kľúčových slov a ich východiskových hodnôt:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Teraz si vytvorme niekoľko príkladov tohto structu:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Struct môžeme meniť rovnako, ako mapu:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Veľmi dôležitou vlastnosťou structov je, že ich môžeme pattern matchovať s mapami:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## Kompozícia

Teraz, keď už dokážeme vytvárať vlastné moduly a štruktúry, je načase naučiť sa, ako pridať funkcionalitu definovanú v iných moduloch. Elixir nám na tento účel poskytuje niekoľko spôsobov ako interagovať s inými modulmi.

### `alias`

Dovoľuje nám dať externému modulu (kratší) alias, cez ktorý potom k nemu budeme pristupovať. V Elixirovom kóde je použitie aliasov veľmi bežné:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

# S použitím aliasu

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Bez použitia aliasu

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Ak existuje konflikt medzi dvoma aliasmi alebo iba chceme aliasy pomenovať úplne inak, môžeme tak urobiť pomocou `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Je možné aliasovať aj viacero modulov naraz:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Ak chceme z externého modulu len importovať jeho funkcie a makrá do nášho modulu, môžeme použiť príkaz `import`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtrovanie

Normálne sa pri importe do nášho modulu dostanú úplne všetky funkcie a makrá z modulu, ktorý importujeme. Môžeme však použiť filtre `:only` (iba) a `:except` (okrem), ktorými vieme presnejšie špecifikovať, o čo z cieľového modulu máme záujem.

Pri použití filtrov *only* a *except* musíme uviesť názov a aritu (počet argumentov) každej filtrovanej funkcie (alebo makra). Napríklad funkciu `last/1` by sme samostatne importovali takto:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Ak zasa naimportujeme *všetko okrem* funkcie `last/1` a teraz vyskúšame rovnaké funkcie ako predtým dostaneme:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Ďalšími užitočnými filtrami sú `:functions` a `:macros`, ktorými vieme naimportovať z cieľového modulu len funkcie alebo len makrá:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Keď chceme z iného modulu načítať len makrá, ale nie funkcie, použijeme `require`:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Ak sa pokúsime zavolať makro, ktoré nie je načítané, Elixir vyhodí chybu.

### `use`

Makrom `use` umožníme cieľovému modulu modifikovať náš modul.
Keď zavoláme `use` v našom kóde, tak vlastne vyvoláme `__using__/1` callback definovaný v dodanom module.
Výsledok `__using__/1` makra sa stane časťou definície nášho modulu.
Aby sme si ukázali ako funguje pozrime sa na tento jednoduchý príklad:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Tu sme vytvorili modul `Hello`, ktorý definuje `__using__/1` callback vo vnútri ktorého definujeme funkciu `hello/1`.
Poďme vytvoriť nový modul aby sme mohli vyskúšať náš kód:

```elixir
defmodule Example do
  use Hello
end
```

Ak skúsime spustiť v IEx náš kód tak uvidíme, že funkcia `hello/1` je dostupná v module `Example`:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Tu môžeme vidieť, že `use` vyvolalo `__using__/1` callback na module `Hello`, čo pridalo výsledný kód do nášho modulu.
Teraz, keď sme si ukázali jednoduchý príklad upravme náš kód aby sme sa pozreli ako `__using__/1` podporuje doplnkové parametre.
Spravíme to tak, že pridáme `greeting` možnosť:

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

Upravme náš modul `Example` aby mal novo vytvorenú `greeting` možnosť:

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

Keď vyskúšame zavolať našu funkciu v IEx tak by sme mali vidieť, že pozdrav sa zmenil:

```
iex> Example.hello("Sean")
"Hola, Sean"
```

Toto sú jednoduché príklady ako funguje `use`, ale zároveň demonštruje aký silný nástroj to je v Elixire.
Ako sa postupne učíme o Elixire, pozerajme sa po použití `use`. Jeden príklad, ktorý určite uvidíme je `use ExUnit.Case, async: true`.

**Poznámka**: `quote`, `alias`, `use` a `require` sú makrá použité keď pracujeme s metaprogramovaním.
