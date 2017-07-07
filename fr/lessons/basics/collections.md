---
version: 0.9.0
title: Collections
---

Les Listes, Tuples, Keywords, Maps et les combinateurs fonctionnels.

{% include toc.html %}

## Listes

Les listes sont de simples collections de valeurs, elles peuvent inclure différents types. Les listes peuvent aussi inclure plusieurs fois la même valeur.

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implémente les listes sous forme de liste chainée. Par conséquent, calculer la taille d'une liste est une opération `O(n)`. Pour cette raison, il est généralement plus rapide d'ajouter un élément en début de liste plutôt qu'à la fin:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### Concaténation de listes

La concaténation de listes s'effectue grace à l'opérateur `++/2`:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Soustraction de listes

Le support de la soustraction se fait via l'opérateur `--/2`. On peux soustraire une valeur inexistante sans problème:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### Head / Tail

Il est commun d'utiliser head et tail lorsque nous utilisons des listes. Head (la tête) est le premier élément de la liste et tail (la queue) les éléments restants. Elixir nous fournis deux fonctions, `hd` et `tl`:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

En plus des fonctions ci-dessus, vous pouvez utiliser un pipe `|` pour déstructurer une liste. Nous verrons cet idiome dans les leçons suivantes:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuples

Les tuples sont similaires aux listes mais sont stockés de manière adjacente en mémoire. On peux calculer leur taille plus rapidement mais cela rends leur modification plus couteuse, le nouveau tuple devant être copié entièrement en mémoire. Les tuples sont définis avec des accolades :

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Les tuples sont souvent utilisés comme un méchanisme pour retourner des informations additionnelles d'une fonction. Leur utilité deviendra plus apparente lorsque nous verrons le pattern matching :

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Les listes de Keywords

Les listes de Keywords et les maps sont les collections associatives d'Elixir. En Elixir, une liste de Keywords est un type de liste spécial contenant uniquement des tuples dont le premier élément est un atom (Keyword). Elles sont aussi performantes que les listes classiques :

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

Les trois caractéristiques des listes de Keywords :

+ Les clés sont des atoms.
+ Les clés sont ordonnées.
+ Les clés peuvent ne pas être uniques.

Pour ces raisons, les listes de Keywords sont la structure de données habituelle pour passer des options aux fonctions.

## Maps

En Elixir les Maps sont la structure privilégiée pour les données de type clé-valeur. Contrairement aux listes à keywords, elles permettent d'avoir des clés de n'importe quel type et ne sont pas ordonnées. On définis une map avec la syntaxe `%{}` :

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Depuis Elixir 1.2, les variables sont autorisées comme clés d'une Map :

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Si nous ajoutons un doublon à une Map, il remplace la valeur précédente :

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Il existe une syntaxe spéciale pour les Maps ne contenant que des clés de type atom :

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```
