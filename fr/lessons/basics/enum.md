---
version: 1.7.0
title: Enum
---

Un ensemble d'algorithmes pour énumérer sur les collections.

{% include toc.html %}

## Enum

Le module `Enum` inclus plus de 70 fonctions pour travailler sur les énumérables. Toutes les collections que nous avons vues dans la [leçon précédente](../collections/), à l'exception des Tuples, sont énumérables.

Cette leçon ne couvre qu'une partie des fonctions disponibles, cependant nous pouvons les examiner par nous même. Faisons une petite expérience dans IEx.

```elixir
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

En utilisant ceci, il devient clair que nous avons accès à un grand nombre de fonctionnalités, et ceci pour une très bonne raison.
L'énumération est au coeur de la programmation fonctionnelle et en l'utilisant en combinaison avec d'autres avantages d'Elixir, cela peut être une grande source de puissance pour le développeur.

Pour la liste complète des fonctions, consultez la documentation officielle du module [`Enum`](https://hexdocs.pm/elixir/Enum.html); pour l'énumération paresseuse utilisez le module [`Stream`](https://hexdocs.pm/elixir/Stream.html).

### all?

Lorsque nous utilisons `all?/2`, et la plupart de fonctions du module `Enum`, nous fournissons une fonction à appliquer aux éléments de nos collections. Dans le cas de `all?/2`, toute la collection dois être évaluée à `true` sinon `false` sera retourné :

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

Contrairement à ci-dessus, `any?/2` retournera `true` si au moins un élément est évalué à `true` :

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every/2

Si vous devez diviser vos collections en plus petits groupes d'une taille donnée, `chunk_every/2` est la fonction que vous recherchez :

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Il existe quelques options pour `chunk_every/4` que nous ne verrons pas, mais que vous pouvez consulter dans [`la documentation officielle de chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) pour en savoir plus.

### chunk_by

Si on veut grouper nos collections autrement que par taille, on peux utiliser la fonction `chunk_by/2`. Elle prend un énumérable donné et une fonction, et quand le retour de cette fonction change, un nouveau groupe est crée :

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Parfois, diviser une collection en petits groupes n'est pas exactement ce dont on a besoin. Si c'est le cas, `map_every/3` peut être très utile pour agir sur chaque `nième` élément, en commençant toujours par le premier :

```elixir
# Apply function every three items
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

Pour itérer sur une collection sans produire une nouvelle valeur, on utilise `each/2` :

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Note__: La fonction `each/2` retourne l'atome `:ok`.

### map

Pour appliquer une fonction à chaque élément et produire une nouvelle collection, nous avons la fonction `map/2` :

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` trouve la valeur minimale d'une collection :

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` fait la même chose, mais si l'énumérable est vide, on nous permet de spécifier une fonction pour produire la valeur minimum.

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` retourne la valeur maximale d'une collection :

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` est à `max/1` ce que `min/2` est à `min/1` :

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### filter

La fonction `filter/2` nous permet de filtrer une collection en ne retournant que les éléments qui permettent à la fonction fournie de retourner une évaluation `true`.

```elixir
iex> Enum.filter([1, 2, 3, 4], fn(x) -> rem(x, 2) == 0 end)
[2, 4]
```

### reduce

Avec `reduce/3` nous pouvons réduire nos collections à une unique valeur. Pour cela nous passons un accumulateur optionnel (`10` dans cet exemple) à notre fonction; s'il n'y a pas d'accumulateur, la première valeur est utilisée :

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Le tri de collections est facilité avec non pas une, mais deux fonctions de tri.

`sort/1` utilise le [tri de termes](http://erlang.org/doc/reference_manual/expressions.html#term-comparisons) d'Erlang pour déterminer l'ordre :

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

`sort/2` nous permet de fournir notre propre fonction de tri :

```elixir
# avec notre fonction
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# sans notre fonction
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

Pour plus de commodité, `sort/2` nous permet d'utiliser `:asc` ou `:desc` comme la fonction de tri :

```elixir
Enum.sort([2, 3, 1], :desc)
[3, 2, 1]
```

### uniq

Nous pouvons utiliser `uniq/1` pour supprimer les doublons de nos collections.

```elixir
iex> Enum.uniq([1, 2, 3, 2, 1, 1, 1, 1, 1])
[1, 2, 3]
```

### uniq_by

`uniq_by/2` va aussi supprimer les doublons de nos collections, mais nous pouvons fournir une fonction pour faire la comparaison de singularité.

```elixir
iex> Enum.uniq_by([%{x: 1, y: 1}, %{x: 2, y: 1}, %{x: 3, y: 3}], fn coord -> coord.y end)
[%{x: 1, y: 1}, %{x: 3, y: 3}]
```

### L'utilisation d'Enum avec l'opérateur de capture (&)

Plusieurs fonctions du module Enum d'Elixir utilisent des fonctions anonymes comme argument pour travailler sur chaque itérable d'une collection.

Ces fonctions anonymes sont souvent écrits en abrégé à l'aide de l'opérateur de capture (&).

Ci-dessous on trouve quelques exemples d'implémentation de l'opérateur de capture avec le module Enum.
Chaque version est fonctionnellement équivalent.

#### L'utilisation de l'opérateur de capture avec une fonction anonyme

Ci-dessous on a un exemple typique de la syntaxe standard pour passer une fonction anonyme à `Enum.map/2`.

```elixir
iex> Enum.map([1,2,3], fn number -> number + 3 end)
[4, 5, 6]
```

Maintenant avec l'implémentation de l'opérateur de capture (&), qui capture chaque itérable de la liste de nombres ([1,2,3]) et l'attribue à variable &1 lors de l'application de la fonction par la fonction `Enum.map/2`.

```elixir
iex> Enum.map([1,2,3], &(&1 + 3))
[4, 5, 6]
```

Cela peut être encore refactorisé en attribuant la fonction avec l'opérateur de capture à une variable et en l'utilisant dans la fonction `Enum.map/2`.

```elixir
iex> plus_three = &(&1 + 3)
iex> Enum.map([1,2,3], plus_three)
[4, 5, 6]
```

#### L'utilisation de l'opérateur de capture avec une fonction nommée

Nous créons d'abord une fonction nommée et l'utilisons dans `Enum.map/2`.

```elixir
defmodule Adding do
  def plus_three(number), do: number + 3
end

iex>  Enum.map([1,2,3], fn number -> Adding.plus_three(number) end)
[4, 5, 6]
```

Ensuite, nous pouvons refactoriser pour utiliser l'opérateur de capture

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three(&1))
[4, 5, 6]
```

Pour la syntaxe la plus succincte, nous pouvons appeler directement la fonction nommée sans capturer explicitement la variable.

```elixir
iex> Enum.map([1,2,3], &Adding.plus_three/1)
[4, 5, 6]
```
