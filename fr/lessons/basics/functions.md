---
version: 0.9.1
title: Fonctions
---

En Elixir, comme dans tous les langages fonctionnels, les fonctions sont des citoyens de premier ordre. Nous verrons les différents types de fonctions en
Elixir, ce qui les rend différentes et comment les utiliser.

{% include toc.html %}

## Fonctions anonymes

Tout comme leur nom le sous-entend, les fonctions anonymes n'ont pas de nom. Tel que nous l'avons vu dans la leçon `Enum`, elles sont fréquemment passées à
d'autres fonctions. Pour définir une fonction anonyme en Elixir, nous avons besoin des mot-clés `fn` et `end`, à l'intérieur desquels nous pouvons définir
n'importe quel nombre de paramètres et de corps de fonction, séparés par `->`.
Jetons un coup d'œil à cet exemple :

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

Comme vous avez peut-être déjà deviné, dans la version raccourcie nos paramètres sont disponibles en tant que `&1`, `&2`, `&3`, etc.

## Pattern matching

Le Pattern matching (ou « Filtrage par motif » en Français) en Elixir ne se limite pas juste aux variables. Il peut être appliqué aux signatures de
fonctions, comme nous allons le voir dans cette section :

Elixir utilise le pattern matching pour identifier le groupe de paramètres correspondant, et appelle le corps de fonction correspondant :

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## Fonctions nommées

Nous pouvons définir des fonctions nommées que nous pouvons appeler plus tard. Ces fonctions sont définies avec le mot-clé `def` au sein d'un
module. Nous en apprendrons plus au sujet des Modules dans les prochaines leçons. Pour l'instant, concentrons-nous seulement sur les fonctions nommées.

Les fonctions définies au sein d'un module sont utilisables par les autres modules, et c'est un élément de langage particulièrement utile en Elixir.

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

Armés de notre connaissance du pattern matching, explorons maintenant la récursion en utilisant les fonctions :

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

### Fonctions privées
Lorsque nous ne voulons pas que d'autres modules aient accès à nos fonctions, nous pouvons utiliser des fonctions privées, qui sont seulement disponibles
au sein de leur propre module. Elles sont définies avec le mot-clé `defp` :

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

### Guards

Nous avons brièvement couvert les guards (prosaïquement traduit par « gardes » dans <u>Programmer en Erlang</u>, Pearson, 2010) dans la leçon sur les
[Structures de contrôle](../control-structures).
Nous allons à présent voir comment nous pouvons les appliquer aux fonctions.

L'exemple ci-dessous contient deux fonctions avec la même signature. Nous allons nous servir des guards pour déterminer laquelle des deux utiliser, en
nous basant sur le type des arguments :


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

Si nous voulons donner une valeur par défaut pour un argument, nous utiliserons la syntaxe `arguments \\ valeur` :

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

Quand nous combinons nos exemples de guards avec les arguments par défaut, nous rencontrons un problème. Regardons cela de plus près :

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

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir n'aime pas les arguments par défaut dans les fonctions avec plusieurs matchs, ça peut être déroutant. Pour gérer ceci, nous ajoutons une tête de fonction avec nos
arguments par défaut :

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
