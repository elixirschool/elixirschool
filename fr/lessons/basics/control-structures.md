---
version: 0.9.0
title: Structures de Contrôle
---

Dans cette leçon nous allons voir les structures de contrôle à notre disposition dans Elixir.

{% include toc.html %}

## `if` et `unless`

Il y a des chances que vous ayez déjà rencontré `if/2`, si vous avez utilisé Ruby `unless/2` vous est familier. En Elixir ils fonctionnent de la même façon mais sont définis comme des macros, pas des constructions du language. Vous trouverez leur implementation dans le [module Kernel](https://hexdocs.pm/elixir/Kernel.html).

A noter en Elixir, les seules valeurs équivalentes à `false` sont `nil` et le booléen `false`.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

`unless/2` s'utilise come `if/2` mis à part qu'il fonctionne sur la négation:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

S'il est nécessaire de tester plusieurs motifs nous pouvons utiliser `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

La variable `_` est une inclusion importante dans les déclarations `case`. Sans celle-ci, l'impossibilité de trouver une correspondance générera une erreur:

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Considérez `_` comme le `else` qui correspondra à "tout les autres valeurs".
Comme `case` se base sur le pattern matching, les mêmes règles et restrictions s'appliquent. Si vous voulez tester une valeur par rapport à une variable existante, vous devez utiliser l'opérateur pin `^`:

```elixir
iex> pie = 3.14 
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Un autre caractéristique sympa de `case` est son support des guard clauses:

_Cet exemple est tiré du guide officiel Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

La documentation pour [les expressions permises dans les guard clauses](http://elixir-lang.org/getting-started/case-cond-and-if.html#expressions-in-guard-clauses).


## `cond`

Lorsque nous avons besoin de faire correspondre des conditions et non des valeurs, nous pouvons utiliser `cond`; un peu comme `else if` ou `elsif` dans d'autres langages:

_Cet exemple est tiré du guide officiel Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

Comme `case`, `cond` générera une erreur s'il n'y a pas de correspondance. Pour palier à ca, on peux définir une condition `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```
