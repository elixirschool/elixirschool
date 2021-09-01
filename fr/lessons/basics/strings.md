---
version: 1.2.0
title: Chaines
---

Chaines, Caractères Listes, Graphemes and Codepoints.

{% include toc.html %}

## Strings 

Avec Elixir, les chaines ne sont rien de plus qu'une séquence d'octets.
Considérons l'exemple suivant : 


```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```
En concaténant la chaine avec l'octet `0`, IEx affiche la chaine comme une séquence binaire car l'ajout de l'octet `0` rend la chaine invalide.
Avec cette astuce, il est possible de voir la chaine exprimée sous forme d'octets.

>NOTE: L'utilisation de << >> indique au compilateur que les éléments à l'intérieur des chevrons sont des octets.

## Charlists

En interne, les chaines Elixir sont des représentées par d es séquences d'octets et non pas un tableau de caractères.
Elixir propose également un type liste de caractères.
Les chaines de caractères Elixir sont encadrées par des guillements ( " - Double quotes en Anglais) tandis que les listes de caractères sont encadrées par des apostrophes ( ' - Single quote en Anglais).

Quelle différence cela fait ? Dans une liste de caractères chaque valeur stockée représente un point de code Unicode. Dans une chaine de type binary, les points de code sont encodés avec UTF-8

Considérons l'exemple suivant :

```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` est le point de code Unicode pour ł . On constate en revanche que la même lettre ł est encodée sur deux octets en UTF-8.

Il est possible d'obtenir le point de code d'un caractère en utilisant `?`

```elixir
iex> ?Z
90
```

Il devient alors possible d'utiliser la notation `?Z`plutôt que 'Z' pour un symbole.

On utilise généralement en Elixir des chaines de caractères plutôt que des listes de caractères, les listes de caractère sont supportées principalement pour les intéractions avec des modules Erlang.

Pour plus d'informations, consulter la documentation officielle [`Getting Started Guide`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## Graphemes et points de code

Les points de code sont de simples caractères Unicode représentés par un ou plusieurs octets selon le codage UTF-8
Les caractères hors table ASCII US seront systèmatiquement encodés avec deux octets ou plus.
Par exemple, les caractères du jeu Latin qui portent un tilde ou un accent (`á, ñ, è`)  sont codés sur deux octets.
Les caractères provenant de langues astiatiques sont parfois codées sur trois ou quatre octets.
Un grapheme est une collection de points de code qui sont affichés comme un seul caractère.

Le module String contient deux functions pour obtenir un grapheme ou un point de code, `graphemes/1` and `codepoints/1`.
Considérons l'exemple suivant : 

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Fonctions de chaines de caractères

Regardons maintenant quelques unes des fonctions les plus utiles et importantes du module String d'Elixir. Nous ne verrons ici qu'une fration des fonctions disponibles.
Pour une liste complète consulter la documentation officielle [`String`](https://hexdocs.pm/elixir/String.html) docs.

### `length/1`

Renvoie le nombre de graphemes dans la chaine.

```elixir
iex> String.length "Hello"
5
```

### `replace/3`

Renvoie une nouvelle chaine où une portion de chaine d'origine est remplacée par une nouvelle chaine.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

Renvoie une nouvelle chaine qui contient la chaine d'origine duppliquée n fois.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

Renvoie une liste de chaines issue de la division en sous-chaines de la chaine d'origine, selon le motif spécifié.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Exercice

Exerçons nous maintenant avec un exercice simple !

### Anagrammes

A et B sont des anagrammes si il est possible de modifier l'ordre des lettres de telle sorte que A et B soient identiques.
Par exemple :

+ A = super
+ B = perus

Si nous modifions l'emplacement des lettres dans la chaine A nous obtenons la chaine B et inversement.

Maintenant, comment pourrions-nous vérifier si deux chaines sont des anagrammes avec Elixir ? La solution la plus simple est de trier chaque chaine par ordre alphabétique puis de vérifier que la chaine A est égale à la chaine B.

Considérons l'exemple suivant :

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Regardons en premier la fonction `anagrams?/2`.
Nous vérifions dans un premier temps que les paramètres que nous recevons sont bien des chaines (Type binary)

Nous appelons ensuite la fonction `sort_string/1` qui trie la chaine par ordre alphabétique :
La chaine est d'abord forcée en minuscule puis passée au travers de la fonction `String.graphemes/1` qui renvoie une liste des graphemes présents dans la chaine.
Finalement, le résultat est passé en premier argument à la fonction `Enum.sort/1` avec l'opérateur pipe (|>)

Plutôt simple non ?

Vérifions le résultat sur iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Nous constatons que le dernier appel à la fonction `anagrams?` provoque une erreur. 
L'erreur nous informe qu'aucune fonction correspondant aux paramètres passés (Deux entiers - Donc deux arguments qui ne sont pas de type binary) n'a pu être trouvée ; C'est parfait, c'est pile le comportement que nous cherchons, pouvoir utiliser la fonction uniquement avec deux chaines.
