---
version: 1.0.2
title: Pattern Matching
---

Le Pattern matching est une partie très puissante d'Elixir, il nous permet de tester la correspondance de simples valeurs, de structures de données, et même de fonctions. Dans cette leçon nous allons voir comment on utilise le pattern matching.

{% include toc.html %}

## L'opérateur Match

Êtes-vous prêt pour un peu d'inattendu ? En Elixir, `=` est l'opérateur de correspondance, comparable au signe égal dans l'algèbre. L'utiliser transforme toute l'expression en une équation, et Elixir évalue l'équivalence des éléments à gauche et à droite du signe égal. S'il y a correspondance, il retourne la valeur de l'equation. Sinon il génère une erreur. Regardons ça :

```elixir
iex> x = 1
1
```

Maintenant essayons une correspondance simple:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Essayons avec une collection:

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## L'opérateur Pin

Nous venons de voir que l'opérateur de correspondance gère l'assignement lorsque la partie à gauche inclus une variable. Dans certains cas ce comportement, la re-assignation de variable, n'est pas désirable. Pour ces situations, nous avons l'opérateur pin: `^` (épingle).

Lorsque nous épinglons une variable nous essayons une correspondance avec la valeur existante plutôt que d'en assigner une nouvelle. Regardons comment ca fonctionne:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2 a introduit le support de l'épinglage pour les clés d'une map ainsi que les clauses de fonctions:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Un exemple d'épinglage dans une clause de fonction:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
iex> greeting
"Hello"
```

Notez que dans l'exemple `"Mornin'"` la re-assignation de `greeting` à `"Mornin'"` arrive seulement à l'intérieur de la fonction. En dehors de la fonction `greeting` vaut toujours `"Hello"`.
