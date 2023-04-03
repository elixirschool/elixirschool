%{
  version: "1.0.2",
  title: "IEx Helpers",
  excerpt: """
  """
}
---

## Général

Quand on commence à travailler en Elixir, IEx est notre meilleur ami.
C'est un REPL (read–eval–print loop), qui a beaucoup de fonctionnalités avancées qui peuvent vous rendre la vie plus facile quand vous explorez du code nouveau, ou développez le vôtre.
Il y a un tas de helpers intégrés, que l'on verra dans cette leçon.

### Auto-complétion

En travaillant dans la console, on se retrouve souvent à utiliser un module avec lequel on n'est pas familier.
Pour savoir ce qui nous est disponible, la fonctionnalité d'auto-complétion est très utile.
Il suffit de taper le nom d'un module suivi d'un `.`, puis d'appuyer sur `Tab`:

```elixir
iex> Map. # press Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

On connait maintenant les fonctions et leurs arités!

### .iex.exs

À chaque fois qu'IEx est lancé, il cherche un fichier de configuration `.iex.exs`.
S'il n'y en a pas dans le dossier actuel, celui du dossier home de l'utilisateur (`~/.iex.exs`) sera utilisé à la place.

Les options de configuration et le code défini dans ce fichier seront disponibles quand la console IEx aura démarré.
Par exemple, si on veut que certaines fonctions helper nous soient disponibles dans IEx, on peut ouvrir `.iex.exs` et faire quelques changements.

Commençons par ajouter un module avec quelques fonctions helper :

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Maintenant, quand on lance IEx, le module IExHelpers nous sera disponible dès le départ.
Ouvrons IEx et essayons nos nouveaux helpers :

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Comme on peut le voir, il n'y a pas besoin de faire quoi que ce soit de spécial pour importer nos helpers, IEx s'en occupe pour nous.

### h

`h` est un des outils les plus utiles que la console Elixir nous donne. 
Grâce au fantastique support de la documentation du langage, la documentation de n'importe quel code peut être récupérée en utilisant ce helper.
Voyons le en action :

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration.
For example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable.
The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as a result, infinite streams need to be carefully used with such
functions, as they can potentially run forever.
For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

On peut même le combiner avec l'auto-complétion de notre console.
Imaginons que l'on explore Map pour la première fois :

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===).
Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct.
Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Comme on peut le voir, on est capable de voir quelles fonctions sont disponibles dans ce module, mais aussi d'avoir accès à la documentation des fonctions, dont la plupart incluent des exemples d'usage.

### i

Utilisons nos nouvelles connaissances en nous servant de `h` pour en savoir plus sur le helper `i` :

```elixir
iex> h i

def i(term)

Prints information about the given data type.

iex> i Map
Term
Map
Data type
Atom
Module bytecode
/usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
/private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
[9651177287794427227743899018880159024]
Compile time
no value found
Compile options
[:debug_info]
Description
Use h(Map) to access its documentation.
Call Map.module_info() to access metadata.
Raw representation
:"Elixir.Map"
Reference modules
Module, Atom
```

Nous avons maintenant des informations sur `Map`, dont là ou sa source est stockée, et les modules qu'il référence.
C'est assez utile lorsqu'on explore des types de data inconnus ou custom, et de nouvelles fonctions.

Avec toutes ces rubriques, ça peut paraître dense, mais à haut niveau, on peut y trouver des informations intéressantes :

- Son type de donnée est un atome
- Où se trouve le code source
- Sa version et ses options de compilation
- Une description générale
- Comment y accéder
- Quels autres modules il référence

Cela nous donne beaucoup de matière, et c'est bien mieux que d'y aller à l'aveugle !

### r

Si on veut recompiler un module en particulier, on peut utiliser le helper `r`.
Disons que nous avont changé un bout de code, et que l'on veut utiliser une nouvelle fonction que l'on vient d'ajouter.
Pour cela, il faut sauvegarder nos changements et recompiler avec `r` :

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### t

Le helper `t` nous en dit plus sur les types de données disponibles dans un module :

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

Maintenant, on sait que `Map` définit des types key et value dans son implémentation.
Si on va voir dans la source de `Map` :

```elixir
defmodule Map do
# ...
@type key :: any
@type value :: any
# ...
```

C'est un exemple simple, qui nous indique que les clés et valeurs peuvent être de n'importe quel type, mais cela peut être utile à savoir.

En tirant parti de toutes ces subtilités intégrées, nous pouvons facilement explorer le code et en savoir plus sur son fonctionnement.
IEx est un outil très puissant et robuste, qui donne du pouvoir aux développeurs.
Avec ces outils dans notre poche, explorer et construire sont encore plus simples !