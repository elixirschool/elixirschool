---
version: 1.0.1
title: Sigils
---

Utilisation et création de sigils.

{% include toc.html %}

## <a name="vue-d-ensemble-des-sigils"></a>Vue d'ensemble des sigils

Elixir fournit une syntaxe alternative pour représenter et travailler avec des valeurs littérales. Un sigil commence avec un tilde `~` suivi par un caractère. Elixir fournit de base un certain nombre de sigils, et il est aussi possible d'en créer soi-même quand il est nécessaire d'étendre le langage.

La liste des sigils disponibles inclut:

  - `~C` Génère une liste de caractères **sans** échappement ni interpolation
  - `~c` Génère une liste de caractères **avec** échappement et interpolation
  - `~R` Génère une expression régulière **sans** échappement ni interpolation
  - `~r` Génère une expression régulière **avec** échappement et interpolation
  - `~S` Génère une chaîne de caractères **sans** échappement ni interpolation
  - `~s` Génère une chaîne de caractères **avec** échappement et interpolation
  - `~W` Génère une liste de mots **sans** échappement ni interpolation
  - `~w` Génère une liste de mots **avec** échappement et interpolation
  - `~N` Génère une struct `NaiveDateTime`

La liste des délimiteurs inclut:

  - `<...>` Une paire de chevrons
  - `{...}` Une paire d'accolades
  - `[...]` Une paire de crochets
  - `(...)` Une paire de parenthèses
  - `|...|` Une paire de barres verticales
  - `/.../` Une paire de barres obliques
  - `"..."` Une paire de guillemets doubles
  - `'...'` Une paire de guillemets simples

### Listes de caractères

Les sigils `~c` and `~C` génèrent des listes de caractères. Par exemple:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

On peut voir que le `~c` en minuscule interpole le calcul, au contraire du `~C` majuscule. Nous verrons que ce comportement majuscule / minuscule est commun pour tous les sigils pré-définis.

### Expressions régulières

Les sigils `~r` et `~R` sont utilisés pour représenter des Expressions Régulières. On les crée soit à la volée, soit pour une utilisation avec les fonctions du module `Regex`. Par exemple:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

On peut voir dans le premier test d'égalité, que `Elixir` n'a pas de correspondance avec l'expression régulière. C'est parce que le mot est capitalisé. Mais comme Elixir utilise les Expressions Régulières Compatibles de Perl (ou PCRE - "Perl Compatible Regular Expressions" en anglais), on peut ajouter `i` à la fin de l'expression régulière de notre sigil pour désactiver la sensibilité à la casse:

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

De plus, Elixir fournit l'API [Regex](https://hexdocs.pm/elixir/Regex.html) construite sur la bibliothèque d'expressions régulières d'Erlang. Implémentons `Regex.split/2` en utilisant un sigil regex:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Comme on peut voir, la chaîne de caractères `"100_000_000"` est séparé à chaque tiret bas, grâce au sigil `~r/_/`. La fonction `Regex.split` retourne une liste.

### Chaînes de caractères

Les sigils `~s` et `~S` sont utilisés pour générer des chaînes de caractères. Par exemple:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

Mais quelle est la différence ? La différence est similaire à celle du sigil de liste de caractères que nous avons déjà vue. La réponse est l'interpolation et l'utilisation des séquences échappées. Si on prend un autre exemple:

```elixir
iex> ~s/bienvenue à elixir #{String.downcase "school"}/
"bienvenue à elixir school"

iex> ~S/bienvenue à elixir #{String.downcase "school"}/
"bienvenue à elixir \#{String.downcase \"school\"}"
```

### Listes de mots

Le sigil de liste de mots peut parfois être très pratique. Il peut sauver du temps et des frappes au clavier, et sans doute réduire la complexité du code. Prenez l'exemple suivant:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

On peut voir que ce qui est tapé entre les délimiteurs est séparé par des espaces et mis dans une liste. Pourtant, il n'y a pas de différence entre ces deux exemples. Encore une fois, la différence vient de l'interpolation et de l'échappement des séquences. Prenez l'exemple suivant:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

Un [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) peut être utile pour créer rapidement une struct représentant un `DateTime` **sans** timezone.

La plupart du temps, nous devrions éviter de créer une struct `NaiveDateTime` directement. C'est cependant utile pour le pattern matching. Par exemple:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

## Création de sigils

Un des objectifs d'Elixir est d'être un langage de programmation extensible. C'est donc sans surprise qu'il est possible de créer facilement nos propres sigils. Dans cet exemple, nous créerons un sigil pour passer une chaîne de caractères en majuscules. Comme il existe déjà une fonction pour cela dans la bibliothèque standard d'Elixir (`String.upcase/1`), nous allons créer notre sigil autour de cette fonction:

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

Comme il n'y a jusque là pas de sigil `~u` parmi ceux existants, nous allons le créer. On définit premièrement un module appelé `MySigils`, et dans celui-ci nous avons créé la fonction nommée `sigil_u`. Le `_u` indique que nous souhaitons utiliser `u` comme le caractère après le tilde. La définition de la fonction doit prendre deux arguments, une donnée d'entrée et une liste de caractères pour les options passées (telle que le `i` utilisé avec les expressions régulières).
