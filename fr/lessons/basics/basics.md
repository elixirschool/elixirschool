---
version: 0.9.0
title: Bases
---

Installation, types de base et opérations.

{% include toc.html %}

## Installation

### Installer Elixir

Les instructions d'installation pour chaque système d'exploitation peuvent être trouvées sur [elixir-lang.org](http://elixir-lang.org/install.html). 

### Mode Interactif

Elixir viens avec `iex`, un shell interactif qui nous permet d'évaluer des expressions Elixir au fur et à mesure.

Pour commencer, lançons `iex`:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## Types de base

### Entiers

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

### Nombres à virgule

En Elixir, les nombres à virgules requièrent une décimale après au moins chaque chiffre; elles ont une précision de l'ordre d'un `double` de 64 bits et offrent 
le support de la notation `e` pour les exponentielles.


```elixir
iex> 3.14 
 3.14
iex> .14 
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Booléens

Elixir supporte `true` et `false` comme valeures booléennes; tout est vrai à part `false` et `nil` :

```elixir
iex> true
true
iex> false
false
```

### Atomes

Un atome est une constante dont le nom est la valeur. Si vous êtes familiers avec Ruby, ils sont synonymes du type `Symbol`

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

NOTE : Booléens `true` et `false` sont aussi respectivement les atomes `:true` et `:false`.

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### Chaînes de caractères

Les chaînes de caractères (`Strings`) d'Elixir sont encodées en UTF-8 et entourées de guillemets droits doubles :

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

## Opérations de base

### Arithmétique

Elixir supporte les opérateurs `+`, `-`, `*` et `/` comme vous pourriez vous y attendre. Il est important de faire remarquer néanmoins que `/` retournera toujours
un nombre à virgule :

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

Si vous avez besoin du reste d'une division ou d'une division entière, Elixir comprend deux fonctions bien utiles pour y parvenir : 

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Booléens

Elixir fournis les opérateurs booléens `||`, `&&` et `!`. Ils supportent n'importe quel types :

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

Il y a trois opérateurs additionnels dont le premier argument _doit_ être un booléen (`true` ou `false`) : 

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

### Comparaison

Elixir arrive avec tous les opérateurs de comparaison dont nous avons l'habitude : `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` et `>`.

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

Pour une comparaison stricte d'entiers et de nombres à virgule, utilisez `===` :

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Une fonctionnalité importante d'Elixir est que deux types peuvent être comparés, ce qui est particulièrement utile quand on effectue un tri.
Nous n'avons pas besoin de mémoriser l'ordre de tri mais il est important d'en être conscient : 

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Cela peut ainsi mener à d'intéressantes comparaisons que vous ne trouveriez pas dans d'autres langages :

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
