---
version: 1.3.0
title: Modules
---

Nous savons d'expérience qu'il est mauvais d'avoir toutes nos fonctions dans le même fichier et le même scope.  Dans cette leçon nous allons voir comment grouper nos fonctions et définir une map spécifique nommée `struct` dans le but d'organiser notre code plus efficacement.

{% include toc.html %}

## Modules

Les modules nous permettent d'organiser nos fonctions à l'intérieur d'un namespace (aussi appelé "Espace de noms"). En plus de grouper les fonctions, ils nous permettent de définir les fonctions nommées et les fonctions privées définies dans la [leçon sur les fonctions](../functions/).

Regardons cet exemple:

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Il est possible d'imbriquer des modules en Elixir, nous permettant d'espacer encore plus nos noms:

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

Les attributs de module sont la plupart du temps utilisés en tant que constantes en Elixir. Ici un exemple basique:

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Il est important de se rappeler qu'il y a des attributs réservés en Elixir.  Les trois plus fréquents sont:

+ `moduledoc` — Documente le module actuel.
+ `doc` — Documentation pour les fonctions et macros.
+ `behaviour` — Utilise un comportement d'OTP ou défini par l'utilisateur.

## Structs

Les structs sont des maps spéciales avec un ensemble défini de clés et de valeurs par défaut.  Une struct doit être définie à l'intérieur d'un module, dont elle prend le nom.  Il est fréquent qu'une struct soit la seule chose définie à l'intérieur d'un module.

Pour définir une struct nous utilisons `defstruct` ainsi qu'une liste de mot-clés contenant les champs et les valeurs par défaut:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Créons maintenant quelques struct:

```elixir
iex> %Example.User{}
#Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
#Example.User<name: "Steve", roles: [], ...>

iex> #Example.User<name: "Steve", roles: [...], ...>
#Example.User<name: "Steve", roles: [...], ...>
```

Nous pouvons mettre à jour notre struct exactement comme une map:

```elixir
iex> steve = #Example.User<name: "Steve", roles: [...], ...>
#Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
#Example.User<name: "Sean", roles: [...], ...>
```

Plus important encore, on peut pattern matcher struct et map:

```elixir
iex> %{name: "Sean"} = sean
#Example.User<name: "Sean", roles: [...], ...>
```

## Composition

Maintenant que nous savons créer des modules et des structs, apprenons a leur ajouter des fonctionnalités existantes via la composition.  Elixir nous fournit une multitude de moyens d'interagir avec les autres modules.

### `alias`

Nous permet de créer un alias pour des noms de modules; utilisé très fréquemment en Elixir:

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

Si il y à conflit entre deux alias ou que nous voulons juste les nommer différemment, nous pouvons utiliser l'option `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Il est même possible de créer des alias pour de multiples modules en une seule fois:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Si nous voulons importer des fonctions plutot que de créer un alias pour le module, nous pouvons utiliser  `import`:

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

Pour importer des macros et options spécifiques , nous devons fournir les paires nom/arité à `:only` et `:except`.  Commençons par importer seulement la fonction `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Si nous importons tout sauf `last/1` et que nous essayons les mêmes appels de fonction:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

En plus des paires nom/arité, il existe deux atomes spéciaux, `:functions` et `:macros`, qui importent réspectivement uniquement les fonctions et les macros:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Nous pouvons utiliser `require` pour dire a Elixir que nous allons utiliser les macros d'un autre module. La subtile différence avec `import` est qu'il permet d'utiliser les macros, mais pas les fonctions, du module spécifié:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Si nous essayons d'appeler une macro qui n'est pas encore chargée, Elixir nous renverra une erreur.

### `use`

Avec la macro `use` nous pouvons permettre a un autre module de modifier la définition de notre modul actuel.
Quand nous appelons `use` dans notre code, nos appelons en fait le callback `__using__/1` défini par le module fourni.
Le résultat de l'appel de la macro `__using__/1` devient partie intégrante de la définition de notre module.
Pour mieux comprendre ce fonctionnement, regardons cet exemple:

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

Ici nous avons crée un module `Hello` qui définit le callback `__using__/1` à l'intérieur duquel nous définissons une fonction `hello/1`.
Créons maintenant un nouveau module pour pouvoir tester notre code:

```elixir
defmodule Example do
  use Hello
end
```

Si nous essayons notre code dans IEx, nous voyons que `hello/1` est disponible dans le module `Example`:

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

Nous pouvons voir que `use` a appelé le callback`__using__/1` dans `Hello` ce qui a ajouté le code retourné à notre module.
Maintenant que nous avons vu un exemple simple, améliorons notre code pour voir comment`__using__/1` gère les options.
Nous allons le faire en ajoutant une option `greeting`:

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

Mettons à jour notre module `Example` pour inclure l'option `greeting` que nous venons de créer:


```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

Si nous essayons notre code dans IEx, nous devrions voir que le retour d'appel de `hello/1` a changé:

```
iex> Example.hello("Sean")
"Hola, Sean"
```

Nous avons ici de simples exemples dont le but est de démontrer le fonctionnement de `use`, mais c'est un outil extremement puissant dans la boite à outils d'Elixir.
En continuant votre apprentissage, faites attention aux utilisations de `use`, un exemple que vous serez sur de voir est: `use ExUnit.Case, async: true`.

**Note**: `quote`, `alias`, `use`, `require` sont des macros utilisées quan nous travaillons avec la [métaprogrammation](../../advanced/metaprogramming).
