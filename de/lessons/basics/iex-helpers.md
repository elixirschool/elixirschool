---
version: 1.0.1
title: IEx Hilfsfunktionen
---

{% include toc.html %}

## Überblick

Wenn du anfängst in Elixir zu programmieren, wird IEx schnell dein bester Freund werden.
IEx ist ein REPL und hat viele fortgeschrittene Features, die dir das Leben leichter machen können wenn du neuen Code erkundest oder eigene Projekte entwickelst.
Es gibt eine Menge integrierter Hilfsfunktionen, die wir uns in dieser Lektion anschauen werden.

### Autocomplete

Beim der Arbeit in der Shell wirst du oft ein Modul verwenden wollen mit dem du noch nicht vertraut bist.
Um einen schnellen Überblick über die dir zur Verfügung stehenden Funktionen zu erhalten, ist die Autocomplete-Funktionalität wunderbar geeignet.

Tippe in IEx einfach den Modulnamen gefolgt von `.` und drücke dann `Tab`:

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

Jetzt kennen wir die enthaltenen Funktionen und ihre Arity!

### `.iex.exs`

Immer wenn IEx startet, wird es nach einer `.iex.exs` Konfigurationsdatei suchen. Falls diese im aktuellen Verzeichnis nicht vorhanden ist, wird eine entsprechende Datei im Homeverzeichnis des Nutzers (`~/.iex.exs`) als Fallback genutzt.

Konfigurationsoptionen und Code in dieser Datei werden uns zur Verfügung stehen sobald IEx startet. Wenn wir z.B. eine selbstdefinierte Hilfsfunktion in IEx nutzen wollen, können wir `.iex.exs` öffnen und dort Änderungen machen.

Beginnen wir mit dem Hinzufügen eines Moduls mit einigen Hilfsfunktionen:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Wenn wir jetzt IEx starten, wird uns das Modul `IExHelpers` von Anfang an zur Verfügung stehen. Öffne IEx und probiere unsere neuen Hilfsfunktionen aus:

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

Wie wir sehen können, müssen wir nichts besonderes tun um unsere neuen Funktionen zu importieren - IEx kümmert sich für uns darum.

### `h`

`h` ist eines der nützlichsten Werkzeuge in IEx.
Dank der First-Class Unterstützung von Dokumentation in Elixir, kann die Dokumentation jeglichen Programmcodes mit dieser Hilfsfunktion eingesehen werden.
Dies in Aktion zu sehen ist einfach:

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

Dies können wir auch mit der Autocomplete-Funktionalität in IEx verbinden.
Stelle dir vor, wir würden `Map` zum ersten Mal erkunden:

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

Wie du siehst, waren wir nicht nur dazu in der Lage, herauzufinden welche Funktionen Teil des Moduls sind, sondern wir konnten auch direkt auf die Dokumentation für einzelne dieser Funktionen zugreifen - oft sogar mit Anwendungsbeispielen.

### `i`

Lass uns einen Teil unseres neuen Wissens nutzen indem wir `h` verwenden, um mehr über die `i`-Hilfsfunktion zu erfahren (und diese danach selbst zu benutzen):

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

Jetzt haben wir eine Menge Informationen über `Map`, darunter auch wo der Quellcode gespeichert ist und welche Module `Map` referenziert. Das ist sehr nützlich wenn wir benutzerdefinierte, unbekannte Datentypen oder neue Funktionen erkunden.

Die einzelnen Übershriften im Output von `i` können sehr informationsdicht sein, aber im Überblick erhalten wir einige relevante Informationen:

- Der Datentyp ist `Atom`
- Wo der Quellcode gespeichert ist
- Eine Versionsnummer und Compileroptionen
- Eine allgemeine Beschreibung
- Wie man darauf zugreift
- Welche anderen Module `Map` referenziert

Das gibt uns eine Menge womit wir arbeiten können.

### `r`

Falls wir ein bestimmtes Modul neu kompilieren möchten, können wir `r` nutzen.
Nehmen wir an, wir haben einen Teil unseres Programmcodes verändert und wollen eine neu hinzugefügte Funktion ausführen.
Um das zu erreichen, müssen wir die geänderte Datei speichern und in IEx mit `r` das betroffene Modul neu kompilieren:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

Die `t` Hilfsfunktion gibt Auskunft über die in einem Modul verfügbaren Typen:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

Nun wissen wir, dass `Map` in seiner Implementation die Typen `key` und `value` definiert.
Wir schauen uns den Quellcode von `Map` an:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Dies ist ein einfaches Beispiel - wir erfahren, dass `key` und `value` beliebige Typen haben können. Dennoch ist es gut, dies zu wissen.

Indem wir all diese eingebauten Nettigkeiten verwenden, können wir Elixir-Code mit Leichtigkeit erforschen und mehr darüber erfahren wie er funktioniert.

IEx ist ein mächtiges und robustes Werkzeug, welches Entwickler*innen viele Möglichkeiten gibt.
Mit diesen Werkzeugen in unserer Werkzeugkiste, macht das Entwickeln sogar noch mehr Spaß als vorher!
