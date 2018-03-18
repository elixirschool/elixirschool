---
version: 1.1.1
title: Kompozícia
---

Zo skúsenosti vieme, že je dosť nepohodlné, mať všetky funkcie v jedinom súbore. V tejto lekcii sa naučíme, ako funkcie zoskupovať a definovať špeciálny typ mapy, zvaný *struct* aby sme mohli usporiadať náš kód efektívne.

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

Je dôležité zapamätať si, že v Elixire existujú vyhradené modulové atribúty. Najbežnejšie tri sú tieto:

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
%Example.User{name: "Sean", roles: [:admin, :owner]}
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

Aj keď sa `require/2` používa zriedkavejšie, je rovnako dôležitou metódou kompozície. Pri jej použití máme istotu, že cieľový modul je skompilovaný a načítaný. To je užitočné najmä v prípade, že potrebujeme prístup k jeho makrám:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Ak by sme sa totiž pokúsili zavolať makro, ktoré ešte nie je načítané, Elixir by vyhodil chybu.

### `use`

Macro use vyvolá špeciálne macro, nazvané `__using__/1`, z špecifikovaného modulu. Tu je príklad:

```elixir
# lib/use_import_require/use_me.ex
defmodule UseImportRequire.UseMe do
  defmacro __using__(_) do
    quote do
      def use_test do
        IO.puts("use_test")
      end
    end
  end
end
```

a pridáme tento riadok do UseImportRequire:

```elixir
use UseImportRequire.UseMe
```

Použitím UseImportRequire.UseMe definuje funkciu `use_test/0` tým že vyvolá macro `__using__/1`.

To je všetko čo use spraví. Ale, je bežné pre macro `__using__` použiť ho na zavolanie alias, require alebo import. To vytvorí v module zadané aliasy alebo importy. Umožní nám modul použiť na definovanie politiky, ako máme odkazovať na funkcie a makrá.

Phoenix framework využíva use a `__using__/1` na odstránenie opakovania sa pri aliasoch a importoch v moduloch definovaných používateľom.

Tu je krátka ukážka z modulu Ecto.Migration:

```elixir
defmacro __using__(_) do
  quote location: :keep do
    import Ecto.Migration
    @disable_ddl_transaction false
    @before_compile Ecto.Migration
  end
end
```

Macro `Ecto.Migration.__using__/1` obsahuje volanie import a keď zavoláme `use Ecto.Migration` tiež zavoláme aj `import Ecto.Migration`. To pripraví aj atribúty modulu, ktorý ovláda správanie Ecta.

Na zopakovanie: použitie macra jednoducho zavolá
`__using__/1` špecifikovaného modulu. Aby sme ale naozaj vedeli čo vykoná musíme si prečítať macro `__using__/1`.

**Poznámka**: `quote`, `alias`, `use` a `require` sú makrá použité keď pracujeme s metaprogramovaním.