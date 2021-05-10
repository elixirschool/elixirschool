%{
  version: "1.2.0",
  title: "Fonctions",
  excerpt: """
  En Elixir, comme dans tous les langages fonctionnels, les fonctions sont des citoyens de premier ordre.
  Nous verrons les différents types de fonctions en Elixir, ce qui les rend différentes et comment les utiliser.
  """
}
---

## Fonctions anonymes

Tout comme l'appellation le sous-entend, les fonctions anonymes n'ont pas de nom.
Comme nous l'avons vu dans la leçon `Enum`, elles sont fréquemment passées à d'autres fonctions.
Pour définir une fonction anonyme en Elixir, nous avons besoin des mot-clés `fn` et `end`, à l'intérieur desquels nous pouvons définir n'importe quel nombre de paramètres et de corps de fonction, séparés par `->`.

Jetons un coup d'œil à un exemple basique:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Le raccourci '&'

Utiliser des fonctions anonymes est quelque chose de tellement courant en Elixir qu'il y a un raccourci pour le faire :

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Comme vous l'avez peut-être déjà deviné, dans la version raccourcie nos paramètres sont disponibles en tant que `&1`, `&2`, `&3`, etc.

## Pattern matching

Le _pattern matching_ (ou _Filtrage par motif_ en français) en Elixir ne se limite pas juste aux variables. Il peut être appliqué également aux signatures de
fonctions, comme nous allons le voir dans cette section.

Elixir utilise le _pattern matching_ pour identifier le groupe de paramètres correspondant, et appelle le corps de fonction correspondant :

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## Fonctions nommées

Nous pouvons définir des fonctions nommées afin de  pouvoir les appeler facilement plus tard.
Ces fonctions nommées sont définies avec le mot-clé `def` au sein d'un module.
Nous en apprendrons plus au sujet des Modules dans les prochaines leçons, mais pour l'instant, concentrons-nous seulement sur les fonctions nommées.

Les fonctions définies au sein d'un module sont utilisables par les autres modules.
C'est un élément de langage particulièrement utile en Elixir.

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Si nos corps de fonction ne s'étendent que sur une ligne, nous pouvons les raccourcir encore plus avec le mot-clé `do:` :

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Armés de notre connaissance du _pattern matching_, explorons maintenant la récursion avec les fonctions nommés :

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Nommage de Fonctions et Arité

Nous avons mentionné précédemment que les fonctions sont nommées par la combinaison de leur nom donné et de leur arité (nombre d'arguments).
Ce qui signifie que l'on peut par exemple faire ceci:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

Nous avons listés les noms des fonctions dans l'exemple ci-dessus dans les commentaires.
La première implémentation ne prend pas d'arguments, donc son nom sera `hello/0`; la seconde prend un argument et donc sera nommée `hello/1`, et ainsi de suite. Contrairement à la surcharge de fonctions dans d'autres langages, ces fonctions sont considérées _différentes_ les unes des autres.
(Le _pattern matching_, que l'on vient de décrire, ne s'applique que quand de multiples définitions sont données pour le _même_ nombre d'arguments.)

### Fonctions et Pattern Matching

Dans les coulisses du langage, les fonctions réalisent un _pattern matching_ sur les arguments avec lesquels elles sont appelées.

Imaginons que nous avons besoin d'une fonction qui prend en paramètre un tableau associtif (une _map_) mais nous sommes juste intéressés par une clé spécifique.
Nous sommes capables d'utiliser le _pattern matching_ sur la présence de cette clé de la manière suivante :

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

Maintenant imaginons que nous avons un tableau associatif décrivant une personne nommé Fred :

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

Ci-après nous avons le résultat quand nous appelons  `Greeter1.hello/1` avec le tableau associatif `fred` :

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```

Que se passe-t-il si nous appelons la fonction avec un tableau associatif qui _ne contient pas_ la clé `:name` ?

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

La raison de ce comportement est qu'Elixir réalise le _pattern matching_ des arguments avec lesquelles une fonction est appelée par rapport à l'arité avec laquelle la fonction est définie.

Réfléchissons ce à quoi ressemblent les données quand ils arrivent dans `Greeter1.hello/1` :

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

`Greeter1.hello/1` attend un argument similaire à :

```elixir
%{name: person_name}
```

Dans `Greeter1.hello/1`, le tableau associatif que nous passons (`fred`) est évalué par rapport à notre argument (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Une clé qui correspond à `name` dans le tableau associatif en entrée est trouvée.
Nous avons une correspondance ! Et comme conséquence de cette mise en correspondance, la valeur associée à la clé `:name` dans le tableau à droite (i.e. le tableau associatif `fred`) est _assignée_ à la variable à gauche (`person_name`).

Maintenant, et si nous voulons assigner le nom de Fred à `person_name` mais que nous voulons AUSSI conserver l'entièreté du tableau associatif représentant la personne ? Disons par exemple que nous voulons `IO.inspect(fred)` après l'avoir salué.
A ce stade, parce que nous n'avons effectué du _pattern matching_ uniquement sur la clé `:name` de notre tableau associatif, n'ayant ainsi assigné que la valeur de cette clé à une variable, la fonction n'a pas accès au reste de Fred.

Afin de le conserver, nous avons besoin d'assigner l'entièreté du tableau associatif à sa propre variable pour pouvoir l'utiliser.

Démarrons l'écriture d'une nouvelle fonction:

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Il faut se souvenir qu'Elixir va mettre en correspondance les arguments comme ils viennent.
Par conséquent dans ce cas, chaque côté va être mis en correspondance avec un argument entrant et assigné avec la valeur associée à cette mise en correspondance.
Examinons le côté droit en premier :

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Maintenant, `person` a été évaluée et assignée en totalité au tableau associatif _fred_.
Passons à la mise en correspondance suivante :

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Maintenant, c'est identique à la fonction `Greeter1` originale dans laquelle nous realisions le _pattern matching_ sur le tableau associatif mais ne retenions que le nom de Fred.
Ce que nous obtenons, ce sont deux variables que nous pouvons utiliser à la place d'une seule :

1. `person` se référant à `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name` se référeant à `"Fred"`

Désormais quand nous appellons `Greeter2.hello/1`, nous pouvons utiliser toutes les information de Fred :

```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

Nous venons ainsi de voir qu'Elixir effectue son _pattern matching_ à plusieurs niveaux parce que chaque argument est mis en correspondance avec les données entrantes de manière indépendante, nous laissant avec les variables par lesquelles les appeler dans notre fonction.

Si nous intervertissons l'ordre de `%{name: person_name}` et de `person` dans la liste, nous obtiendrons le même résultat puisque chacun est mis en correspondance avec fred indépendamment.

Nous intervertissons la variable et le tableau associatif :

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Et nous l'appelons avec les mêmes données que celles que nous avons utilisées avec `Greeter2.hello/1` :

```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Il faut bien se rappeler que même si cela donne l'impression que `%{name: person_name} = person` met en correspondance `%{name: person_name}` avec la variable `person`, en fait ils sont chacun mis en correspondance avec l'argument passé en entrée.

**Résumé:** Les fonctions effectuent la mise en correspondance des données qui leur sont passées en entrée sur leurs arguments de manière indépendante.
Nous pouvons le mettre à profit pour assigner les valeurs dans des variables différentes au sein de la fonction.

### Fonctions privées

Lorsque nous ne voulons pas que d'autres modules aient accès à nos fonctions, nous pouvons utiliser des fonctions privées.
Les fonctions privées sont seulement disponibles au sein de leur propre module.
Elles sont définies avec le mot-clé `defp` :

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Guards (Gardes)

Nous avons brièvement couvert les gardes (on reprend ici la traduction en français de _guards_ utilisée dans __Programmer en Erlang__, Pearson, 2010) dans la leçon sur les [Structures de contrôle](../control-structures). Nous allons à présent voir comment nous pouvons les appliquer aux fonctions.
Dès lors qu'Elixir a trouvé une correspondance sur un nom de fonction, toutes les gardes seront testées.

L'exemple ci-dessous contient deux fonctions avec la même signature. Nous allons nous servir des gardes pour déterminer laquelle des deux utiliser, en nous basant sur le type des arguments :

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Arguments par défaut

Si nous voulons donner une valeur par défaut pour un argument, nous utiliserons la syntaxe `argument \\ valeur` :

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Quand nous combinons nos exemples de gardes avec les arguments par défaut, nous rencontrons un problème.
Regardons cela de plus près :

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header.
Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir n'aime pas les arguments par défaut dans les fonctions avec plusieurs matchs, ça peut être déroutant.
Pour gérer ceci, nous ajoutons une tête de fonction avec nos arguments par défaut :

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
