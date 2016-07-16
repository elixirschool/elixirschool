---
layout: page
title: Kompozícia
category: basics
order: 8
lang: sk
---

Zo skúsenosti vieme, že je dosť nepohodlné, mať všetky funkcie v jedinom súbore. V tejto lekcii sa naučíme, ako funkcie zoskupovať do *modulov*, ako moduly komponovať a ako používať špeciálny typ mapy, zvaný *Struct*.

{% include toc.html %}

## Moduly

Moduly umožňujú organizovať funkcie do menných priestorov (*namespaces*). Definujeme v nich pomenované a privátne funkcie, o ktorých sme si povedali v minulej lekcii.

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

V Elixire je možné definovať moduly vnorené v iných moduloch, čo nám dovoľuje jemnejšie rozdeľovať funkcionalitu do menných priestorov:

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

Dôležitá poznámka: v Elixire existujú vyhradené modulové atribúty, ktoré majú špeciálny význam. Najbežnejšie tri sú tieto:

+ `moduledoc` — Slúži na dokumentáciu modulu.
+ `doc` — Dokumentácia funkcie alebo makra.
+ `behaviour` — Indikuje použitie OTP, alebo iného behavaiour (chovania).

## Structs

Struct je špeciálny typ dátovej štruktúry *mapa* s preddefinovanými kľúčami a ich default hodnotami. Struct musí byť definovaný v module - z tohto modulu získa svoj názov. V tomto module sa potom už väčšinou nič iné nedefinuje.

Na definovanie structu používame kľúčové slovo `defstruct` nasledované zoznamom polí a ich default hodnôt:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Teraz si vytvorme niekoľko exemplárov tohto structu:

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

Struct môžeme meniť rovnako, ako mapu:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", password: nil, roles: [:admin, :owner]}
```

Veľmi dôležitou vlastnosťou structov je, že ich môžeme pattern matchovať s mapami:

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## Skladanie modulov

Teraz, keď už dokážeme vytvárať vlastné moduly, je načase naučiť sa, ako v nich používať funkcie definované v iných moduloch. Elixir nám na tento účel poskytuje niekoľko odlišných kompozičných mechanizmov:

### `alias`

Dovoľuje nám dať externému modulu (kratší) alias, cez ktorý potom k nemu budeme pristupovať. V Elixirovom kóde je použitie aliasov veľmi bežné:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

# s použitím aliasu

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# bez použitia aliasu

defmodule Example do
  def greeting(name), do: Saying.Greetings.basic(name)
end
```

V príklade je vidieť, že ak nešpecifikujeme inak, ako alias sa použije posledná časť mena modulu. napríklad z modulu `Sayings.Greetings` sa stane `Greetings`. Ak chceme vytvoriť vlastný alias (napríklad aby sme sa vyhli konfliktu mien), použijeme parameter `as:`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Je možné aliasovať viacero modulov naraz:

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

Ak by sme v uvedenom príklade nepoužili `import`, museli by sme funkciu `last` volať ako `List.last`.

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

Takto zasa naimportujeme z modulu `List` *všetko okrem* funkcie `last/1`:

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

Aj keď sa `require/2` používa zriedkavejšie, je rovnako dôležitou metódou kompozície. Pri jej použití máme istotu, že cieľový modul je skompilovaný a načítaný. To je užtočné najmä v prípade, že potrebujeme prístup k jeho makrám:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Ak by sme sa totiž pokúsili zavolať makro, ktoré ešte nie je načítané, Elixir by vyhodil chybu.

### `use`

Použije modul v aktuálnom kontexte. Hodí sa nám to keď chceme, aby cieľový modul pri importovaní niečo vykonal. Volaním príkazu `use` totiž spustíme funkciu `__using__` daného modulu (ak nejakú má), čo mu poskutuje možnosť ovplyvniť náš modul - napríklad vložiť doňho nejaké importy, aliasy a podobne:

```elixir
defmodule HelloModule do
  defmacro __using__(opts) do
    quote do
      import HelloModule.Foo
      import HelloModule.Bar
      import HelloModule.Baz

      alias HelloModule.Repo
    end
  end
end
```

Ak by sme teda v našom module zavolali `use HelloModule`, HelloModule nám doňho importne svoje podmoduly `Foo`, `Bar` a `Baz`, plus vytvorí alias `Repo`.
