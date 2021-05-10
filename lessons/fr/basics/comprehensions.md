---
version: 1.1.0
title: Compréhensions
---

Les compréhensions de liste sont un _sucre syntaxique_ pour parcourir des énumérables en Elixir.
Dans cette leçon, nous verrons comment nous pouvons utiliser les compréhensions pour itérations et générations.

{% include toc.html %}

## Bases

Les compréhensions peuvent souvent être utilisées pour produire des déclarations plus concises pour les itérations sur des `Enum` et des `Stream`.
Commençons par regarder une compréhension simple que nous allons ensuite expliquer pas à pas :

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

La première chose que nous remarquons est l'utilisation de `for` et d'un générateur.
Qu'est-ce qu'un générateur ?
Les générateurs sont les expressions comme `x <- [1, 2, 3, 4]` que l'on trouve dans les compréhensions de liste.
Ils sont responsables de produire la prochaine valeur.

Heureusement pour nous, les compréhensions ne sont pas limitées aux listes ; en fait, elles fonctionnent avec n'importe quel énumérable :

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Comme beaucoup d'autres choses en Elixir, les générateurs reposent sur la correspondance de motif (_pattern matching_) pour comparer leur ensemble d'entrée à la variable du côté gauche.
Si une correspondance n'est pas trouvée, la valeur est ignorée :

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Il est possible d'utiliser de multiples générateurs, de manière similaire à des boucles imbriquées :

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

Afin de mieux illustrer l'exécution de la boucle qui a concrètement lieu, utilisons `IO.puts` pour afficher les deux valeurs générées :

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

Les compréhensions des listes sont un _sucre syntaxique_ et ne devraient ainsi être utilisées que quand c'est approprié.

## Filtres

Vous pouvez considérer les filtres comme des sortes de clauses de garde pour les compréhensions.
Quand une valeur filtrée retourne `false` ou `nil` elle est exclue de la liste finale.
Itérons sur un intervalle et soucions-nous uniquement des nombres pairs.
Nous utiliserons la fonction `is_even/1` du module `Integer` pour vérifier si la valeur est pair ou non.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Comme pour les générateurs, nous pouvons utiliser plusieurs filtres.
Elargissons notre intervalle et filtrons ensuite uniquement sur les valeurs qui sont à la fois pairs et multiples de 3.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Utilisation de `:into`

Comment faire si nous souhaitons produire autre chose qu'une liste ?
Avec l'option `:into` nous pouvons faire exactement çà !
Comme règle de base, `:into` accepte n'importe quelle structure qui implémente le protocole `Collectable`.

En utilisant `:into`, créons un tableau associatif à partir d'une liste de mots-clés :

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Comme les données de type `Binary` sont également des `Collectable`, nous pouvons nous servir d'une compréhension de liste et de `:into` pour créer des chaînes de caractères de type `String` :

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

Et voilà !
Les compréhensions de liste sont une manière simple et consise d'itérer sur une collection.
