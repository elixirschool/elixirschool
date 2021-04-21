---
version: 0.9.0
title: Enums
---

Ein Satz Algorithmen, um über collections zu gehen.

{% include toc.html %}

## Enum

Das `Enum`-Modul besitzt über hundert Funktionen, um mit collections zu arbeiten, die wir im letzten Kapitel kennen gelernt haben.

Diese Lektion wird nur einen kleinen Teil der verfügbaren Funktionen behandeln, wir können sie jedoch alle genauer anschauen. Lass uns ein kleines Experiment in IEx machen.

```elixir
iex
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

Hieran sieht man, dass wir viel Funktionalität haben und das aus gutem Grund. Enumeration ist die Basis funktionaler Programmierung und ein unglaublich nützliches Ding.
Durch Ausnutzen davon, zusammen mit anderen Vorteilen Elixirs, wie die Dokumentation als `Bürger erster Klasse` behandelt wird, kann es auch den Entwickler enorm unterstützen.

Um eine komplette Liste der Funktionen zu sehen besuche die offizielle [`Enum`](https://hexdocs.pm/elixir/Enum.html)-Dokumentation; für lazy enumeration nimm das [`Stream`](https://hexdocs.pm/elixir/Stream.html)-Modul.

### all?

Beim Benutzen von `all?`, ähnlich wie oft in `Enum`, liefern wir den Items unserer collection eine Funktion, die auf jedes einzelne Elemente angewandt wird. Im Fall von `all?` muss die gesamte collection `true` sein, ansonsten wird als Rückgabewert `false` zurück gegeben:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Anders wie oben gibt `any?` `true` zurück, falls mindestens ein Element der collection `true` ist:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every/2

Falls du deine collection in kleinere Gruppen teilen möchtest ist `chunk_every/2` vermutlich die Funktion, nach der du suchst:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```


`chunk_every/2` hat einige Optionen, aber diese werden wir nicht besprechen. Falls du mehr darüber erfahren möchtest, sieh dir [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) in der offiziellen Dokumentation an, um mehr darüber zu erfahren.

### chunk_by

Falls unsere collection aufgrund eines anderen Merkmals als Größe geteilt werden soll, kannst du die Methode `chunk_by/2` benutzen. Sie nimmt ein vorhandenes enumerable und eine Funktion und falls der Rückgabewert dieser Funktion sich ändert wird eine neue Gruppe erzeugt:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### each

Es kann vonnöten sein über die collection zu iterieren ohne einen Wert zu erzeugen. Für diesen Fall gibt es `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Hinweis__: Die Methode `each` gibt das Atom `:ok` zurück.

### map

Um unsere Funktion auf jedes Item der collection anzuwenden und eine neue collection zu erzeugen gibt es die `map`-Funktion:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Finde den `min`-Wert in unserer collection:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Finde den `max`-Wert in unserer collection:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

Mit `reduce` können wir unsere collection auf einen einzelnen Wert destillieren. Um dies zu tun müssen wir einen optionalen Akkumulator angeben (`10` in diesem Beispiel), der der Funktion übergeben wird; falls kein Akkumulator übergeben wird, so wird der erste Wert genommen:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Unsere collection zu sortieren geht nicht nur mit einer, nein, sogar zwei `sort`-Funktionen. Die erste Option benutzt Elixirs Termsortierung, um die sortierte Reihenfolge zu bestimmen:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Die andere Option erlaubt uns selbst eine Sortierfunktion anzugeben:

```elixir
# mit unserer Funktion
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# ohne
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

Wir können `uniq` dazu benutzen Duplikate aus unserer collection zu entfernen:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
