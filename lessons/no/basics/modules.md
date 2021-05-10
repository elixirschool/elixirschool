---
version: 0.9.2
title: Moduler
---

Vi vet fra erfaring at det er besværlig å ha alle våre funksjoner i samme fil og skop. I denne leksjonen skal vi dekke hvordan vi grupperer funksjoner, og definerer en spesialisert form for map kjent som struct for å kunne organiserer koden vår mer effektivt.

{% include toc.html %}

## Moduler

Moduler er den beste måten å organisere funksjoner inn i egne navnområder. I tillegg til å gruppere funksjoner, tillater det oss å definere våre egne navnkalte og private funksjoner som vi gikk igjennom i forrige leksjon.

La oss se på et enkelt eksempel:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

I Elixir så er det mulig å nøste moduler i hverandre:

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Modul Attributer

Modul attributer er som oftest brukt som konstanter i Elixir. La oss se på et enkelt eksempel:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Det er viktig å notere at det er reserverte attributer i Elixir. De tre vanligste er:

+ `moduledoc` — Dokumenterer den nåværende modulen.
+ `doc` — Dokumentasjon for funksjoner og makroer.
+ `behaviour` — Bruk en OTP eller bruker-definert atferd.

## Structs

Structs er en spesielle form for map, de definerer en mengde av nøkler og standard verdier. En struct må være definert i en egen modul, som den også får navnet sitt fra. Det er normalt at en struct er det eneste som er definert i en modul.

For å definere en struct bruker vi `defstruct` sammen med en nøkkelord liste av felt og standard verdier.

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

La oss lage noen structs:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Vi kan oppdatere vår struct akkurat som med en map:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Det viktigste er at du kan matche structs mot maps:


```elixir
iex> %{navn: "Sean"} = sean
%Eksempel.Bruker{navn: "Sean", roller: [:admin, :eier]}
```

## Komposisjon

Nå som vi vet hvordan vi lager moduler og structs, la oss lære oss hvordan vi kan legge til eksisterende funksjonalitet til de via komposisjon. Elixir forsyner oss med mange forskjellige måter å integrere med andre moduler.

### `alias`

Tillater oss å gi alias til modulnavn; noe som er veldig ofte brukt i Elixir.

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Uten alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Hvis det oppstår en konflikt mellom to alias, eller om vi ønsker å bruke et alias til noe annet, så kan vi bruke `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Det er også mulig å bruke et alias på flere moduler i en tilordning:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Hvis vi har lyst til å importere funksjoner og makroer istedenfor å bruke et alias for modulen kan vi bruke `ìmport/`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtrering

Per standard vil alle funksjoner og makroer bli importert, men vi kan filtrere dem ved å bruke `:only` og `:except`.

For å importere spesifikke funksjoner og makroer, må vi bruke navn/aritet paret med `:only` og `:except`. La oss starte med å kun importere `last/1` funksjonen:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Hvis vi importerer alt untatt `last/1` og prøver med den samme funksjonen som tidligere:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

I tillegg til navn/aritet paret så er det to spesielle atomer, `:functions` og `:macros`, som importerer kun de funksjonene eller makroene:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Brukt sjeldnere, men fortsatt viktig er `require/2`. Å kreve en modul forsikrer at den er kompilert og lastet.
Dette er mest brukbart når vi trenger å aksessere en modul sine makroer:

```elixir
defmodule Eksempel do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Hvis vi prøver å kalle en makro som ikke er lastet, så vil Elixir heve en feil.

### `use`

use makroen kaller en spesiell makro, kalt `__using__/1`, i den spesifiserte modulen. Her er et eksempel:

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

og vi legger denne linjen til UseImportRequire:

```elixir
use UseImportRequire.UseMe
```

Å bruke UseImportRequire.UseMe definerer en use_test/0 funksjon gjennom invokasjon av `__using__/1` makroen.

Det er alt det use gjør. Men, det er vanlig at `__using__` makroen kaller på alias, require eller import. Dette vil lage aliaser eller importere det som kreves i using modulen. Dette tillater modulen til å bli brukt til å definere en retningslinje for hvordan deres funksjoner og makroer burde bli referert til. Dette kan være svært fleksibelt i det at `__using__/1` kan sette opp referanser til andre moduler, spesielt submoduler.

Phoenix rammeverket bruker use og `__using__/1` for å kutte ned bruken av repetitive alias og import kall i bruker definerte moduler.

Her er et godt eksempel fra Ecto.Migration modulen:

```elixir
defmacro __using__(_) do
  quote location: :keep do
    import Ecto.Migration
    @disable_ddl_transaction false
    @before_compile Ecto.Migration
  end
end
```

`Ecto.Migration.__using__/1` makroen inkluderer et importkall slik at når du bruker `use Ecto.Migration` så vil den også kalle `import Ecto.Migration`. Den setter også opp modul attributer som vi kan anta kontrollerer Ecto sin atferd.

For å oppsumere: use invokerer `__using__/1` i den spesifiserte modulen. For å virkelig forstå hva den gjør så anbefales det at du leser om `__using__/1` makroen.
