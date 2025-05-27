%{
  version: "1.2.0",
  title: "Chaines",
  excerpt: """
  Chaines, Listes de caractères, Graphemes et Points de code.
  """
}
---

## Chaines

En Elixir, les chaînes ne sont rien de plus qu'une suite d'octets.
Voyons un exemple :

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

En concaténant la chaîne avec l'octet `0`, IEx affiche la chaîne en tant que liste binaire, car elle n'est plus une chaîne valide.
Cette astuce nous permet de voir de quels octets est composée n'importe quelle chaîne.

>NOTE: En utilisant la syntaxe << >>, on indique au compilateur que les éléments entre ces symboles sont des octets.

## Charlists / Listes de caractères

En interne, les chaînes Elixir ne sont pas représentées sous forme de tableau de caractères, mais plutôt sous forme d'une suite d'octets.
Elixir a aussi un type char list (liste de caractères).
Les chaînes Elixir sont entre guillemets ("double quotes" en anglais) alors que les listes de caractères sont entre apostrophes ('simple quotes' en anglais).

Quelles sont les différences ? Chaque valeur d'une liste de caractère est le point de code Unicode d'un caractère, alors que dans une chaîne binaire, les points de codes sont encodés en UTF-8.
Voyons un exemple :

```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` est le point de code Unicode pour ł, mais il est encodé en UTF-8 par les deux octets `197` et `130`.

On peut savoir le point de code d'un caractères en utilisant `?`

```elixir
iex> ?Z
90
```

Cela nous permet d'utiliser la notation `?Z` plutôt que 'Z' pour un symbole.

Quand on programme en Elixir, on utilise généralement les chaînes plutôt que les listes de caractères. 
Si le support de ces listes de caractères est inclus, c'est principalement car il est requis par certains modules Erlang.

Pour plus d'informations, vous pouvez voir la documentation officielle. [`Getting Started Guide`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html)

## Les Graphèmes et Points de code

Les points de codes (Codepoints en anglais) sont de simples caractères Unicode, représentés par un ou plusieurs octets, selon l'encodage UTF-8.
Les caractères hors de la table ASCII US seront toujours encodés en plusieurs octets.
Par exemple, les caractères des langues latines avec tildes ou accents (`á, ñ, è`) sont généralement encodés en deux octets.
Les caractères des langues asiatiques sont souvent encodés en trois ou quatre octets.
Un graphème est en ensemble de points de code, représentés par un seul caractère.

Le module String nous met à disposition deux fonctions pour obtenir graphèmes et points de code, `graphemes/1` et `codepoints/1`.
Voyons un exemple : 

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Les fonctions du module String

Passons en revue quelques-unes des fonctions les plus importantes et utiles du module String.
Cette leçon ne couvrira que certaines des fonctions qui existent.
Pour voir la liste complète des fonctions, visitez la documentation officielle [`String`](https://hexdocs.pm/elixir/String.html).

### length/1

Retourne le nombre de graphèmes dans la chaîne.


```elixir
iex> String.length "Hello"
5
```

### replace/3

Retourne une nouvelle chaîne, ou une portion de la chaîne initiale est remplacée par une autre chaîne.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### duplicate/2

Retourne une nouvelle chaîne, répétée n fois.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### split/2

Retourne une liste de chaînes, séparées par un motif.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Exercice

Voyons maintenant un exercice simple, pour démontrer que nous sommes prêts à travailler avec les chaînes!

### Anagrammes 

A et B sont des anagrammes s'il est possible des réarranger les lettres de telle sorte que A et B soient identiques. 
Par exemple :

+ A = super
+ B = perus

Si on réarrange les caractères de la chaîne A, on peut obtenir la chaîne B, et vice-versa.

Comment peut-on vérifier que deux chaînes sont des anagrammes en Elixir? La solution la plus simple est de ranger les graphèmes de chaque chaîne dans l'ordre alphabétique, puis de vérifier si ces deux listes sont identiques.
Essayons cela :

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

Regardons d'abord `anagrams?/2`.
On vérifie que les paramètres que l'on reçoit sont des binaires ou non.
C'est comme ça qu'on peut vérifier qu'un paramètre est une chaîne en Elixir.

Après ça, on appelle une fonction qui trie les chaînes de façon alphabétique.
Elle convertit les chaînes en minuscules, puis utilise `String.graphemes/1` pour obtenir une liste des graphèmes dans cette chaîne.
Enfin, le résultat est passé en premier argument à la fonction `Enum.sort/1` grâce à l'opérateur pipe (|>)
Plutôt simple, n'est ce pas ?

Vérifions le résultat sur iex :

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

Comme on peut le voir, le dernier appel à `anagrams?` a causé une FunctionClauseError.
Cette erreur nous indique qu'il n'y a pas de fonction qui correspond aux paramètres passés, c'est-à-dire deux paramètres non-binaires. C'est exactement le comportement que l'on veut, pouvoir appeler cette fonction seulement avec deux chaînes.
