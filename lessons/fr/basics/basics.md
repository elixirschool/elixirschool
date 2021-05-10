%{
  version: "1.3.0",
  title: "Bases",
  excerpt: """
  Installation, types de base et opérations.
  """
}
---

## Installation

### Installer Elixir

Les instructions d'installation pour chaque système d'exploitation se trouvent sur elixir-lang.org dans le [guide d'installation.](http://elixir-lang.org/install.html).

Une fois qu'Elixir est installé, nous pouvons facilement trouver la version installée.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Essayer le Mode Interactif

Elixir vient avec `iex`, un shell interactif qui nous permet d'évaluer des expressions Elixir au fur et à mesure.

Pour commencer, lançons `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Note: Sous Windows PowerShell, il faut taper `iex.bat`.

Maintenant, essayons `iex` en tapant quelques expressions simples:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Ce n'est pas grave si vous ne comprenez pas chaque expression maintenant, autant que vous comprenez le principe.

## Types de base

### Entiers (Integers)

```elixir
iex> 255
255
```

Il y a également le support des notations binaires, octales et hexadécimales :

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Nombres à virgule flottante (Floats)

En Elixir, les nombres à virgule flottantes requièrent une décimale après au moins une chiffre; elles ont une précision de l'ordre d'un `double` de 64 bits et offrent le support de la notation `e` pour les exponentielles.

```elixir
iex> 3.14
 3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booléens (Booleans)

Elixir supporte `true` et `false` comme valeurs booléennes; tout est considéré comme vrai (truthy) à part `false` et `nil` :

```elixir
iex> true
true
iex> false
false
```

### Atomes (Atoms)

Un atome est une constante qui a pour valeur son nom. Si vous êtes familiers avec Ruby, ils sont synonymes du type `Symbol`

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

NOTE : Les booléens `true` et `false` sont aussi respectivement les atomes `:true` et `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Les noms de modules en Elixir sont aussi des atomes. `MyApp.MyModule` est un atome valide, même si aucun module de ce nom n'a pas encore été déclaré.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Les atomes sont aussi utilisés pour référencer les modules de bibliothèques Erlang, y compris celles inclues de base.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Chaînes de caractères (Strings)

Les chaînes de caractères en Elixir sont encodées en UTF-8 et entourées de guillemets droits doubles :

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Les chaînes de caractères supportent les retours à la ligne et les séquences d'échappement :

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir comprend aussi des types plus complexes. Nous verrons plus à ce sujet en parlant des [collections](../collections/) et des [fonctions](../functions/).

## Opérations de base

### Arithmétique

Elixir supporte les opérateurs `+`, `-`, `*` et `/` comme prévu. Il est important de se souvenir que `/` retournera toujours un nombre à virgule flottante :

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

Si vous avez besoin du reste d'une division ou d'une division entière (le modulo), Elixir comprend deux fonctions bien utiles pour les obtenir :

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Booléens

Elixir fournit les opérateurs booléens `||`, `&&` et `!`. Ils supportent n'importe quel type:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

Il y a trois opérateurs additionnels, dont le premier argument _doit_ être un booléen (`true` ou `false`) :

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

Note: Les opérateurs `and` et `or` d'Elixir mappent en fait à `andalso` et `orelse` en Erlang.

### Comparaison

Elixir a tous les opérateurs de comparaison habituels: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` et `>`.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

Pour une comparaison stricte d'entiers et de nombres à virgule flottante, utilisez `===` :

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Une fonctionnalité importante d'Elixir est que deux types différents peuvent être comparés, ce qui est particulièrement utile quand on effectue un tri. Nous n'avons pas besoin de mémoriser l'ordre de tri mais il est important d'en être conscient :

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Cela permet de réaliser des comparaisons intéressantes, que vous ne trouveriez pas dans d'autres langages :

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolation des chaînes de caractères

Si vous avez déjà utilisé Ruby, l'interpolation en Elixir vous semblera familière :

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Concaténation de chaînes de caractères

La concaténation de chaînes utilise l'opérateur `<>` :

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
