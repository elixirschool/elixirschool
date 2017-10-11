---
version: 0.9.0
title: Enum
---

Un ensemble d'algorithmes pour énumérer sur les collections.

{% include toc.html %}

## Enum

Le module `Enum` inclus plus de 100 fonctions pour travailler sur les collections que nous avons vues dans la leçon précédente.

Cette leçon ne couvre qu'une partie des fonctions disponibles, pour la liste complète des fonctions voir la documentation officielle du module [`Enum`](https://hexdocs.pm/elixir/Enum.html); pour l'énumération paresseuse utilisez le module [`Stream`](https://hexdocs.pm/elixir/Stream.html).


### all?

Lorsque nous utilisons `all?`, et la plupart de fonctions du module `Enum`, nous fournissons une fonction à appliquer aux éléments de nos collections. Dans le cas de `all?`, toute la collection dois être évaluée à `true` sinon `false` sera retourné:

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Contrairement à ci-dessus, `any?` retournera `true` si au moins un élément est évalué à `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every/2

Si vous devez diviser vos collections en plus petits groupes d'une taille donnée, `chunk_every/2` est la fonction que vous recherchez:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Il existe quelques options pour `chunk_every/2` que vous pouvez consulter dans la documentation officielle de [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) de la fonction.

### chunk_by

Si on veut grouper nos collections autrement que par taille, on peux utiliser la fonction `chunk_by`:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
```

### each

Pour itérer sur une collection sans produire une nouvelle valeur, on utilise `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Note__: La fonction `each` retourne l'atom `:ok`.

### map

Pour appliquer une fonction à chaque élément et produire une nouvelle collection, nous avons la fonction `map`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

Trouve la valeur `min` d'une collection:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

### max

Retourne la valeur `max` d'une collection:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

### reduce

Avec `reduce` nous pouvons réduire nos collections à une valeur. Pour cela nous passons un accumulateur optionnel (`10` dans cet exemple) à notre fonction; s'il n'y a pas d'accumulateur, la première valeur est utilisée:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Le tri de collections est facilité avec deux fonctions `sort`. La première option utilise le tri de termes d'Elixir pour déterminer l'ordre:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

La seconde option nous permet de fournir une fonction de tri:

```elixir
# with our function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# without
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq

`uniq` va supprimer les doublons de nos collections:

```elixir
iex> Enum.uniq([1, 2, 2, 3, 3, 3, 4, 4, 4, 4])
[1, 2, 3, 4]
```
