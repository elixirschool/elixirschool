---
version: 1.0.2
title: Sigils
---

Utilisation et création de _sigils_.

{% include toc.html %}

## Vue d'ensemble des sigils

Elixir fournit une syntaxe alternative pour représenter et travailler avec des valeurs littérales.
Un _sigil_ (la traduction française serait _sceau_ mais nous garderons _sigil_ dans la suite) commence avec un tilde `~` suivi par un caractère.
Elixir fournit de base un certain nombre de _sigils_, et il est aussi possible d'en créer soi-même quand il est nécessaire d'étendre le langage.

La liste des _sigils_ disponibles inclut :

  - `~C` génère une liste de caractères **sans** échappement ni interpolation
  - `~c` génère une liste de caractères **avec** échappement et interpolation
  - `~R` génère une expression régulière **sans** échappement ni interpolation
  - `~r` génère une expression régulière **avec** échappement et interpolation
  - `~S` génère une chaîne de caractères **sans** échappement ni interpolation
  - `~s` génère une chaîne de caractères **avec** échappement et interpolation
  - `~W` génère une liste de mots **sans** échappement ni interpolation
  - `~w` génère une liste de mots **avec** échappement et interpolation
  - `~N` génère une _struct_ `NaiveDateTime`
  - `~U` génère une _struct_ `DateTime` (depuis Elixir 1.9.0)

La liste des délimiteurs inclut :

  - `<...>` Une paire de chevrons
  - `{...}` Une paire d'accolades
  - `[...]` Une paire de crochets
  - `(...)` Une paire de parenthèses
  - `|...|` Une paire de barres verticales
  - `/.../` Une paire de barres obliques
  - `"..."` Une paire de guillemets doubles
  - `'...'` Une paire de guillemets simples

### Listes de caractères

Les _sigils_ `~c` et `~C` génèrent des listes de caractères.
Par exemple :

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

On peut voir que le `~c` en minuscule interpole le calcul, au contraire du `~C` majuscule.
Nous verrons que ce comportement majuscule / minuscule est commun pour tous les _sigils_ pré-définis.

### Expressions régulières

Les _sigils_ `~r` et `~R` sont utilisés pour représenter des Expressions Régulières.
Nous les créons soit à la volée, soit pour une utilisation avec les fonctions du module `Regex`.
Par exemple :

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Nous pouvons constaterdans le premier test d'égalité, que `Elixir` n'a pas de correspondance avec l'expression régulière.
C'est parce que le mot est capitalisé.
Parce qu'Elixir supporte les Expressions Régulières Compatibles de Perl (ou **PCRE** - "**P**erl **C**ompatible **R**egular **E**xpressions" en anglais), nous pouvons ajouter `i` à la fin de l'expression régulière de notre _sigil_ pour désactiver la sensibilité à la casse:

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

De plus, Elixir fournit l'API [Regex](https://hexdocs.pm/elixir/Regex.html) construite sur la bibliothèque d'expressions régulières d'Erlang.
Utilisons `Regex.split/2` avec un _sigil regex_ :

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Comme nous pouvons le voir, la chaîne de caractères `"100_000_000"` est séparé à chaque _blanc souligné_ (_underscore_ en anglais), grâce au _sigil_ `~r/_/`.
La fonction `Regex.split` retourne une liste.

### Chaînes de caractères

Les _sigils_ `~s` et `~S` sont utilisés pour générer des chaînes de caractères.
Par exemple :

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Mais quelle est la différence ? La différence est similaire à celle du _sigil_ de liste de caractères que nous avons déjà vu.
La réponse est l'interpolation et l'utilisation des séquences échappées.
Si nous prenons un autre exemple :

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Listes de mots

Le _sigil_ de liste de mots peut quelquefois être fort pratique.
Il peut et sauver du temps et des frappes au clavier, et sans doute réduire la complexité du code.
Prenez l'exemple suivant:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Nous pouvons voir que ce qui est tapé entre les délimiteurs est séparé par des espaces et mis dans une liste.
Pourtant, il n'y a pas de différence entre ces deux exemples.
Encore une fois, la différence vient de l'interpolation et de l'échappement des séquences.
Prenez l'exemple suivant :

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

Un [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) peut être utile pour créer rapidement une _struct_ représentant un `DateTime` **sans** fuseau horaire.

La plupart du temps, nous devrions éviter de créer une _struct_ `NaiveDateTime` directement.
C'est cependant utile pour le _pattern matching_.
Par exemple :

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

### DateTime

Un [DateTime](https://hexdocs.pm/elixir/DateTime.html) peut être utile pour créer rapidement une _struct_ pour représenter une `DateTime` **avec** un fuseau horaire _UTC_ (Coordinated Universal Time). Puisque c'est dans un fuseau horaire UTC et que votre chaîne de caractères pourrait représenter un autre fuseau, un troisième élément représentant le décalage en seconde est retourné.

Par exemple :

```elixir
iex> DateTime.from_iso8601("2015-01-23 23:50:07Z") == {:ok, ~U[2015-01-23 23:50:07Z], 0}
iex> DateTime.from_iso8601("2015-01-23 23:50:07-0600") == {:ok, ~U[2015-01-24 05:50:07Z], -21600}
```

## Création de sigils

Un des objectifs d'Elixir est d'être un langage de programmation extensible.
C'est donc sans surprise qu'il est possible de créer facilement nos propres _sigils_.
Dans cet exemple, nous créerons un _sigil_ pour passer une chaîne de caractères en majuscules.
Comme il existe déjà une fonction pour cela dans la bibliothèque standard d'Elixir (`String.upcase/1`), nous allons créer notre _sigil_ autour de cette fonction :

```elixir

iex> defmodule MySigils do
...>   def sigil_p(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~p/elixir school/
ELIXIR SCHOOL
```

Tout d'abord, nous définissons premièrement un module appelé `MySigils`, et dans celui-ci nous avons créé une fonction nommée `sigil_p`
Comme il n'y a jusque-là pas de sigil `~p` parmi ceux existants, nous allons le créer.
Le `_p` indique que nous souhaitons utiliser `p` comme le caractère après le tilde.
La définition de la fonction doit prendre deux arguments, une donnée d'entrée et une liste de caractères pour les options passées (telle que le `i` utilisé avec les expressions régulières).
