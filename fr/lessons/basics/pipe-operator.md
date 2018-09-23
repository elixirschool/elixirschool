---
version: 1.0.1
title: L'opérateur Pipe
---

L'opérateur pipe `|>` passe le résultat d'une expression en tant que premier paramètre à une autre expression.

{% include toc.html %}

## Introduction

Le code peut vite devenir confus. L'appel à une fonction peut être tellement imbriqué que la logique devient difficile à suivre. Prenons cet exemple:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Ici nous passons le résultat de `other_function/0` à `new_function/1`, puis de `new_function/1` à `baz/1`, de `baz/1` à `bar/1` et enfin le résultat de `bar/1` à `foo/1`. Elixir propose une alternative pragmatique à ce chaos syntaxique: l'opérateur pipe. L'opérateur pipe `|>` *prends le résultat d'une expression, et le passe à la suivante*. Regardons maintenant le bout de code au dessus re-écrit avec l'opérateur pipe.

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Le pipe prend le résultat à sa gauche et le passe à sa droite.

## Exemples

Nous allons utiliser le module String d'Elixir pour les exemples suivants.

- Segmentation de String

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Transformation des tokens en majuscules

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Vérification de la fin

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Bonnes pratiques

Si l'arité d'une fonction et supérieure à 1, assurez vous d'utiliser des parenthèses. Ce n'est pas nécessaire pour Elixir mais plus pour les autres développeurs qui pourraient mal interpréter votre code. Si on prends notre 3ème exemple, et enlevons les parenthèses de `String.ends_with?/2`, nous pouvons voir l'avertissement suivant:

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

foo(1) |> bar(2) |> baz(3)

true
```
