%{
  version: "0.9.2",
  title: "Module",
  excerpt: """
  Wie wir aus Erfahrung wissen ist es unschön alle unsere Funktionen in der gleichen Datei und im gleichen scope zu haben. In dieser Lektion werden wir uns ansehen, wie man Funktionen aufteilt und definieren eine spezielle map, genauer ein struct, um unseren Code effektiver zu strukturieren.
  """
}
---

## Module

Module sind der beste Weg Funktionen in einem namespace zu gruppieren. Zusätzlich zum Gruppieren von Funktionen erlauben sie uns benannte und private Funktionen zu definieren, welche wir im vorherigen Kapitel behandelt haben.
Lass uns ein einfaches Beispiel ansehen:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Es ist möglich Module in Elixir zu verschachteln, was dir erlaubt den namespace weiter zu konkretisieren:

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

### Modulattribute

Modulattribute werden meist als Konstanten in Elixir benutzt. Lass uns den Blick auf ein simples Beispiel werfen:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Es ist wichtig festzuhalten, dass es reservierte Attribute in Elixir gibt. Die drei häufigsten sind:

+ `moduledoc` — Dokumentiert das aktuelle Modul.
+ `doc` — Dokumentation für Funktionen und Makros.
+ `behaviour` — Benutzt OTP oder benutzerdefiniertes Verhalten.

## Structs

Structs sind besondere maps, mit einer Menge keys und Defaultwerten. Ein struct muss innerhalb eines Modules definiert werden, woher es den Namen bezieht. Es ist für ein struct üblich, das einzige Ding in einem Modul zu sein.
Um ein struct zu definieren benutzen wir `defstruct` zusammen mit einer keyword list an Feldern und Defaultwerten:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Lass uns ein paar structs erstellen:

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Wir können ein struct genauso wie eine map aktualisieren:

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Und das Wichtigste: Man kann sie gegen maps matchen:

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

## Komposition

Da wir nun wissen wie man Module und structs erstellt, lass uns lernen wie man existierende Funktionalität hinzufügt mit der Hilfe von Komposition. Elixir erlaubt uns mit einer breiten Anzahl verschiedener Wege mit anderen Modulen zu interagieren.

### `alias`

Erlaubt uns Modulnamen mit einem Alias anzusprechen; wird ziemlich oft in Elixir benutzt:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Ohne Alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Falls es einen Konflikt zwischen zwei Aliasen gibt oder wir einfach nur einen anderen Alias vergeben wollen, können wir die `:as`-Option nutzen:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Es ist sogar möglich mehrere Module auf einmal zu aliasen:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Falls wir Funktionen und Makros statt eines Moduls importieren wollen, können wir `import/` benutzen:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtern

Standardmäßig werden alle Funktionen und Makros importiert, aber wir können diese mit den `:only`- und `:except`-Optionen filtern.

Um bestimmte Funktionen und Makros zu importieren müssen wir `:only` und `:except` die Name/Arity-Paare angeben. Lass uns mit dem Import der `last/1`-Funktion beginnen:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Falls wir alles außer `last/1` importieren und die gleichen Funktionen wie gerade eben aufrufen wollen:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Neben den Name/Arity-Paaren gibt es noch zwei besondere atoms: `:functions` und `:macros`, welche nur Funktionen bzw. Makros importieren:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Obwohl weniger gebräuchlich, ist `require/2` dennoch wichtig. Ein Modul zu benötigen sichert ab, dass es kompiliert und geladen ist. Das ist am nützlichsten, wenn wir auf das Makro eines Moduls zugreifen wollen:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff()
end
```

Falls wir versuchen auf ein Makro zuzugreifen, dass noch nicht geladen ist, wirft Elixir einen Fehler.

### `use`

Das use-Makro ruft ein spezielles Macro auf - `__using__/1` - vom spezifizierten Modul. Hier ist ein Beispiel:

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

und wir fügen diese Zeile UseImportRequire hinzu:

```elixir
use UseImportRequire.UseMe
```

UseImportRequire.UseMe zu benutzen definiert eine `use_test/0`-Funktion durch den Aufruf des `__using__/1`-Makros.

Das ist alles, was use macht. Dennoch ist es wiederum für das `__using__`-Makro üblich alias, require oder import aufzurufen. Das erstellt dann daraus Aliase oder Imports im benutzenden Modul. Das erlaubt dem Modul eine Richtlinie zu definieren, wie seine Funktionen und Makros referenziert werden sollen. Das kann ziemlich flexibel sein, insofern, dass `__using__/1` Referenzen auf andere Module aufsetzt, besonders Untermodule.

Das Phoenix Framework benutzt use und `__using__/1`, um den Gebrauch von sich wiederholenden Aliasen und Import-Aufrufen in benutzerdefinierten Modulen zu reduzieren.

Hier ist ein schönes und kurzes Beispiel aus dem Ecto.Migration-Modul:

```elixir
defmacro __using__(_) do
  quote location: :keep do
    import Ecto.Migration
    @disable_ddl_transaction false
    @before_compile Ecto.Migration
  end
end
```

Das `Ecto.Migration.__using__/1`-Makro inkludiert einen import-Aufruf, so dass wenn du `use Ecto.Migration` aufrufst, auch `import Ecto.Migration` aufrufst.

Nochmal zur Wiederholung: Das use-Makro ruft einfach nur das `__using__/1`-Makro auf dem angegebenen Modul auf. Um wirklich zu verstehen, was es tut, musst du das `__using__/1`-Makro lesen.

**Notiz**: `quote`, `require`, `use` und `alias` sind Makros, die wir bei der [Metaprogrammierung](../../advanced/metaprogramming) brauchen.
