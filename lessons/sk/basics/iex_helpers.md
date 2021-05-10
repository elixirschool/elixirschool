%{
  version: "1.0.1",
  title: "Pomocné funkcie IEx",
  excerpt: """
  
  """
}
---

## Prehľad

Pri práci v Elixire, IEx je náš najlepší kamarát.
Je to Read–eval–print loop, ale má mnoho pokročilých funkcií, ktoré nám môžu uľahčiť život, keď skúmame nový kód alebo počas vývoja projektu.
Existuje niekoľko zabudovaných pomocníkov, o ktorých si povieme v tejto lekcii.

### Autocomplete

Keď pracujeme v príkazovom riadku, môžeme často naraziť na nový modul o ktorom nič nevieme.
Ak chceme vedieť čo máme k dispozícii, funkcionalita automatického doplňovania je úžasná.
Jednoducho napíšeme meno modulu nasledované `.` a potom stlačíme `Tab`:

```elixir
iex> Map. # press Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

A teraz vieme aké funkcie máme k dispozícii!

### `.iex.exs`

Zakaždým keď sa spustí IEx, bude hľadať konfiguračný súbor `.iex.exs`. Ak nie je v aktuálnom adresári, tak sa ako záloha použije z užívateľovho home adresára `~/.iex.exs`.

Možnosti konfigurácie a kód definovaný v tomto súbore bude dostupný hneď, keď sa spustí IEx. Napríklad, ak chceme pomocné funkcie dostupné v IEx, tak môžeme otvoriť `.iex.exs` a spraviť zopár zmien.

Začneme pridaním modulu, ktorý má zopár pomocných funkcií:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Teraz, keď spustíme IEx, bude modul IExHelpers dostupný od spustenia.
Spustime IEx a poďme vyskúšať naše nové pomocné funkcie:

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Ako môžeme vidieť nepotrebujeme použiť require alebo import aby sme mali prístup k našim pomocným funkciám, IEx to spraví za nás.

### `h`

`h` je jeden z najužitočnejších nástrojov Elixir shellu.
Vďaka perfektnej podpore dokumentácie, ju môžeme pri akomkoľvek kóde zobraziť pomocou tejto pomocnej funkcie.

Ukážme si ako funguje:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

A teraz to môžeme dokonca kombinovať s automatickým doplnením nášho shellu.
Predstavme si, že chceme preskúmať modul Map prvý krát:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Ako môžeme vidieť, nielen, že sme schopní nájisť aké funkcie má modul k dispozícii, ale máme prístup aj k dokumentácii jednotlivých funkcií, kde mnohé obsahujú aj príklad použitia.

### `i`

Teraz zúžitkujeme naše novo získané znalosti o pomocnej funkcii `h` tým, že ju použijeme aby sme sa naučili viac o pomocnej funkcii `i`:

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Teraz máme nejaké informácie o module `Map` ako napríklad, kde nájdeme súbor so zdrojovým kódom a na ktoré moduly odkazuje. To je veľmi užitočné najmä, keď preskúmavame cudzie dátové typy a nové funkcie.

Individuálne položky sú na prvý pohľad stručné, ale po prejdení môžeme získať užitočné informácie:

- Je dátový typ atóm
- Kde sa nachádza zdrojový kód
- Verziu a možnosti kompilácie
- Základný popis
- Ako k nemu môžeme pristupovať
- Na ktoré moduly odkazuje

To nám dáva informácie o tom ako s modulom pracovať a je určite lepšie ako to skúšať naslepo.

### `r`

Ak chceme prekompilovať určitý modul môžeme tak urobiť pomocnou funkciou `r`. Povedzme, že sme zmenili časť kódu a chceme spustiť novú funkciu, ktorú sme pridali. Aby sme to spravili, potrebujeme uložiť naše zmeny a prekompilovať pomocou `r`:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

Pomocná funkcia `t` nám povie aké typy sú dostupne v danom module:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

A teraz vieme, že modul `Map` definuje typy kľúča a hodnoty v jeho implementácii.
Ak sa pozrieme na zdrojový kód modulu `Map`:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Toto je jednoduchý príklad, v ktorom sa uvádza, že kľúče a hodnoty podľa implementácie môžu byť akéhokoľvek typu, ale je to užitočné vedieť.

Použitím týchto zabudovaných funkcií môžeme jednoducho preskúmať akýkoľvek kód a dozvedieť sa ako funguje. IEx je veľmi výkonný a robustný nástroj, ktorý ocení každý vývojár.
