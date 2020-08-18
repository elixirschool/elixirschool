---
version: 1.4.1
title: Modules
---

Nous savons d'expérience qu'il est mauvais d'avoir toutes nos fonctions dans le même fichier et avec la même portée. Dans cette leçon, nous allons voir comment grouper nos fonctions et définir un tableau associatif spécialisé nommé `struct` dans le but d'organiser notre code plus efficacement.

{% include toc.html %}

## Modules

Les modules nous permettent d'organiser nos fonctions à l'intérieur d'un _namespace_ (aussi appelé _espace de noms_ en français). En plus de grouper les fonctions, ils nous permettent de définir des fonctions nommées et des fonctions privées définies dans la [leçon sur les fonctions](../functions/).

Regardons cet exemple :

```elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Il est possible d'imbriquer des modules en Elixir, vous permettant de catégoriser plus finement vos fonctionnalités dans des espaces de noms :

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### Attributs de Module

Les attributs de module sont la plupart du temps utilisés en tant que constantes en Elixir. Ici un exemple basique :

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Il est important de se rappeler qu'il y a des attributs réservés en Elixir. Les trois plus fréquents sont :

- `moduledoc` — Documente le module actuel.
- `doc` — Documentation pour les fonctions et macros.
- `behaviour` — Utilise un comportement d'OTP ou défini par l'utilisateur.

## Structs

Les _structs_ sont des tableaux associatifs spéciaux avec un ensemble défini de clés et de valeurs par défaut.  
Une _struct_ doit être définie à l'intérieur d'un module, dont elle prend le nom.  
Il est fréquent qu'une _struct_ soit la seule chose définie à l'intérieur d'un module.

Pour définir une _struct_ nous utilisons `defstruct` suivi d'une liste de mot-clés spécifiant les champs et les valeurs par défaut associées :

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Créons maintenant quelques _structs_ :

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

Nous pouvons mettre à jour notre _struct_ exactement comme un tableau associatif :

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

Plus important encore, on peut mettre en correspondance une _struct_ et un tableau associatif :

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

A partir d'Elixir 1.8, les _structs_ incluent une introspection personnalisée.
Pour comprendre ce que cela signifie et comment nous allons l'utiliser, inspectons notre variable `sean` utilisée dans le _pattern matching_ précédent :

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

Tous nos champs sont présents ce qui est bien pour cet exemple mais comment gérerions-nous un champ protégé que nous ne voudrions pas inclure ?
La nouvelle fonctionnalité `@derive` nous permet d'accomplir précisément cela !
Mettons à jour notre exemple de sorte que `roles` ne soit désormais plus inclus dans notre affichage en sortie :

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

_Note_: nous aurions également pu utiliser `@derive {Inspect, except: [:roles]}`, les deux écritures sont équivalentes.

Avec notre module mis à jour en place, regardons ce que cela donne dans `iex` :

```elixir
iex> sean = %Example.User{name: "Sean"}
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

Le champ `roles` est exclus de l'affichage en sortie !

## Composition

Maintenant que nous savons créer des modules et des _structs_, apprenons à leur ajouter des fonctionnalités existantes via la composition.
Elixir nous fournit une multitude de moyens d'interagir avec les autres modules.

### `alias`

Nous permet de créer un alias pour des noms de modules; c'est utilisé plutôt fréquemment en Elixir :

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Sans alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Si il y a conflit entre deux alias ou que nous voulons juste les nommer différemment, nous pouvons utiliser l'option `:as` :

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Il est même possible de créer des alias pour de multiples modules en une seule fois :

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Si nous voulons importer des fonctions plutôt que de créer un alias pour le module, nous pouvons utiliser `import` :

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Filtrage

Par défaut toutes les fonctions et macros sont importées, mais nous pouvons les filtrer en utilisant les options `:only` et `:except`.

Pour importer des macros et options spécifiques, nous devons fournir les paires nom/arité à `:only` et `:except`.
Commençons par importer seulement la fonction `last/1` :

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Si nous importons tout sauf `last/1` et que nous essayons les mêmes appels de fonction que dans l'exemple précédent :

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

En plus des paires nom/arité, il existe deux atomes spéciaux, `:functions` et `:macros`, qui importent respectivement uniquement les fonctions et les macros :

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Nous pouvons utiliser `require` pour dire à Elixir que nous allons utiliser les macros d'un autre module. La subtile différence avec `import` est qu'il permet d'utiliser les macros, mais pas les fonctions, du module spécifié :

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Si nous essayons d'appeler une macro qui n'est pas encore chargée, Elixir nous renverra une erreur.

### `use`

Avec la macro `use` nous pouvons permettre à un autre module de modifier la définition de notre module actuel.
Quand nous appelons `use` dans notre code, nous appelons en fait le callback `__using__/1` défini par le module fourni.
Le résultat de l'appel de la macro `__using__/1` devient partie intégrante de la définition de notre module.
Pour mieux comprendre ce fonctionnement, regardons cet exemple :

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Ici nous avons créé un module `Hello` qui définit le callback `__using__/1` à l'intérieur duquel nous définissons une fonction `hello/1`.
Créons maintenant un nouveau module pour pouvoir tester notre code :

```elixir
defmodule Example do
  use Hello
end
```

Si nous essayons notre code dans IEx, nous voyons que `hello/1` est disponible dans le module `Example` :

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Nous pouvons voir que `use` a appelé le callback`__using__/1` dans `Hello` ce qui a ajouté le code retourné à notre module.
Maintenant que nous avons vu un exemple simple, améliorons notre code pour voir comment `__using__/1` gère les options.
Nous allons le faire en ajoutant une option `greeting` :

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

Mettons à jour notre module `Example` pour inclure l'option `greeting` que nous venons de créer :

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

Si nous essayons notre code dans IEx, nous devrions voir que le retour d'appel de `hello/1` a changé :

```elixir
iex> Example.hello("Sean")
"Hola, Sean"
```

Ce sont ici des exemples simples dont le but est de démontrer le fonctionnement de `use`, mais c'est un outil extrêmement puissant dans la boite à outils d'Elixir.
En continuant votre apprentissage, faites attention aux utilisations de `use`, un exemple que vous serez sur de voir est: `use ExUnit.Case, async: true`.

**Note** : `quote`, `alias`, `use`, `require` sont des macros utilisées quand nous travaillons avec la [métaprogrammation](../../advanced/metaprogramming).
