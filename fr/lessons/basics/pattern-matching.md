---
layout: page
title: Pattern Matching
category: basics
order: 4
lang: fr
---

Le Pattern matching est une partie très puissante d'Elixir, il nous permet de tester la correspondance de simples valeurs, de structures de données, et même de fonctions. Dans cette leçon nous allons voir comment on utilise le pattern matching.

## Table des matières

- [L'opérateur Match](#match-operator)
- [L'opérateur Pin](#pin-operator)

## <a name="match-operator"></a>L'opérateur Match

En Elixir, `=` est l'opérateur de correspondance. Via l'opérateur de correspondance, nous pouvons assigner et faire correspondre des valeurs. Regardons ça:

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
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1|tail] = list
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

## <a name="pin-operator"></a>L'opérateur Pin

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
```
