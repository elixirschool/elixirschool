---
version: 1.3.0
title: Basics
---

Getting started, basic data types, and basic operations.

{% include toc.html %}

## Getting Started

### Installing Elixir

Installation instructions for each OS can be found on elixir-lang.org in the [Installing Elixir](http://elixir-lang.org/install.html) guide.

After Elixir is installed, you can easily find the installed version.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Trying Interactive Mode

Elixir comes with IEx, an interactive shell, which allows us to evaluate Elixir expressions as we go.

To get started, let's run `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Note: On Windows PowerShell, you need to type `iex.bat`.

Let's go ahead and give it a try now by typing in a few simple expressions:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Don't worry if you don't understand every expression yet, but we hope you get the idea.

## Basic Data Types

### Integers

```elixir
iex> 255
255
```

Support for binary, octal, and hexadecimal numbers comes built in:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Floats

In Elixir, floating point numbers require a decimal after at least one digit; they have 64-bit double precision and support `e` for exponent values:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booleans

Elixir supports `true` and `false` as booleans; everything is truthy except for `false` and `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atoms

An atom is a constant whose name is its value.
If you're familiar with Ruby, these are synonymous with Symbols:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

The booleans `true` and `false` are also the atoms `:true` and `:false`, respectively.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Names of modules in Elixir are also atoms. `MyApp.MyModule` is a valid atom, even if no such module has been declared yet.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atoms are also used to reference modules from Erlang libraries, including built in ones.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Strings

Strings in Elixir are UTF-8 encoded and are wrapped in double quotes:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Strings support line breaks and escape sequences:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir also includes more complex data types.
We'll learn more about these when we learn about [collections](../collections/) and [functions](../functions/).

## Basic Operations

### Arithmetic

Elixir supports the basic operators `+`, `-`, `*`, and `/` as you would expect.
It's important to remember that `/` will always return a float:

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

If you need integer division or the division remainder (i.e., modulo), Elixir comes with two helpful functions to achieve this:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean

Elixir provides the `||`, `&&`, and `!` boolean operators.
These support any types:

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

There are three additional operators whose first argument _must_ be a boolean (`true` or `false`):

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

Note: Elixir's `and` and `or` actually map to `andalso` and `orelse` in Erlang.

### Comparison

Elixir comes with all the comparison operators we're used to: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<`, and `>`.

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

For strict comparison of integers and floats, use `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

An important feature of Elixir is that any two types can be compared; this is particularly useful in sorting. We don't need to memorize the sort order, but it is important to be aware of it:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

This can lead to some interesting, yet valid comparisons you may not find in other languages:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### String Interpolation

If you've used Ruby, string interpolation in Elixir will look familiar:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### String Concatenation

String concatenation uses the `<>` operator:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
