%{
  version: "1.4.0",
  title: "Bases",
  excerpt: """
  Installation, types de base et opérations.
  """
}
---

## Installation

### Installer Elixir

Les instructions d'installation pour chaque système d'exploitation se trouvent sur *elixir-lang.org* dans le [guide d'installation.](http://elixir-lang.org/install.html).

Une fois qu'Elixir est installé, nous pouvons facilement trouver la version installée.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Essayer le Mode Interactif

Elixir vient avec `iex`, un shell interactif qui nous permet d'évaluer des expressions Elixir au fur et à mesure.

Pour commencer, lançons `iex` :

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Note : Sous Windows PowerShell, il faut taper `iex.bat`.

Maintenant, essayons `iex` en tapant quelques expressions simples :

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

### Entiers (*Integers*)

```elixir
iex> 255
255
```

En plus de la base décimale, les entiers peuvent être notés en base binaire, octale et hexadécimale :

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Nombres à virgule flottante (*Floats*)

En Elixir, les nombres à virgule flottante requièrent une décimale après au moins un chiffre ; elles ont une précision de l'ordre d'un `double` de 64 bits et offrent le support de la notation `e` pour les exponentielles.

```elixir
iex> 3.14
 3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booléens (*Booleans*)

Les valeurs booléennes sont dénotées `true` et `false`. Tout est considéré comme vrai, excepté `false` et `nil`.

```elixir
iex> true
true
iex> false
false
```

### Atomes (*Atoms*)

Un atome est une constante qui a pour valeur son nom. Ils sont équivalent au type `Symbol` en Ruby.

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Note : les booléens `true` et `false` sont aussi respectivement les atomes `:true` et `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Les noms de modules en Elixir sont aussi des atomes. `MyApp.MyModule` est un atome valide, même si aucun module de ce nom n'a été déclaré.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Les atomes sont aussi utilisés pour référencer les modules de bibliothèques Erlang, y compris celles inclues de base.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Chaînes de caractères (*Strings*)

Les chaînes de caractères en Elixir sont encodées en *UTF-8* et entourées de guillemets droits doubles :

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Les chaînes de caractères peuvent contenir des retours à la ligne et des séquences d'échappement :

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir comprend aussi des types plus complexes. Nous approfondirons ce sujet dans les leçons dédiées aux [collections](/fr/lessons/basics/collections) et aux [fonctions](/fr/lessons/basics/functions).

## Opérations de base

### Opérations arithmétiques

Elixir supporte les opérateurs `+`, `-`, `*` et `/`. `/` produit toujours un nombre à virgule flottante :

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

De plus, Elixir comprend deux fonctions pour calculer le quotient (ou modulo) et le reste (en anglais : *remainder*) d'une division :

```elixir
iex> div(10, 3)
3
iex> rem(10, 3)
1
```

### Opérations booléennes

Elixir fournit les opérateurs booléens `||`, `&&` et `!`. Ils supportent n'importe quel type :

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

Il y a trois opérateurs additionnels, dont le premier argument _doit_ être un booléen (`true` ou `false`) :

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (BadBooleanError) expected a boolean on left-side of "and", got: 42
iex> not 42
** (ArgumentError) argument error
```

Note : Les opérateurs `and` et `or` d'Elixir correspondent respectivement à `andalso` et `orelse` en Erlang.

### Comparaisons

Elixir a tous les opérateurs de comparaison habituels : `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` et `>`.

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

Pour une comparaison stricte d'entiers et de nombres à virgule flottante, utilisez `===` :

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Des valeurs de types différents peuvent être comparés, c'est utile pour effectuer un tri. L'ordre est le suivant :

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Cela permet de réaliser des comparaisons intéressantes, que vous ne trouveriez pas dans d'autres langages :

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolation des chaînes de caractères

Si vous avez déjà utilisé Ruby, l'interpolation en Elixir vous semblera familière :

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Concaténation de chaînes de caractères

L'opérateur de concaténation de chaînes de caractères est `<>` :

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
