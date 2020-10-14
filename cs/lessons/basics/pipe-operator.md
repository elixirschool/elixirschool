---
version: 1.0.1
title: Pipe operátor
---

Pipe operátor `|>` pošle výslednou hodnotu výrazu jako první paramater do dalšího výrazu.

{% include toc.html %}

## Úvod

Programování může být i pěkný bordel.
Ve skutečnosti tak velký bordel, že volání funkcí může být tolikrát vnořené, že je těžké sledovat co se děje.
Podívejte se na následující funkci jako odstrašující případ:

```elixir
foo(bar(baz(new_function(other_function(other_other_function())))))
```

Zde předáváme hodnotu `other_other_function/0` do `other_function/0` do `new_function/1`, a `new_function/1` do `baz/1`, `baz/1` do `bar/1`, a konečně výsledek `bar/1` do `foo/1`.
Elixír má na tohle pragmatický přístup a tenhle syntaktický chaos nahrazuje pipe operátorem.
Pipe operátor, který vypadá takhle `|>` vezme výsledek jednoho výrazu (vlevo) a přesune ho do výrazu vpravo.
Pojďme si refaktorovat úvodní chaotickou funkci s použitím pipe operátoru.

```elixir
other_other_function() |> other_function() |> new_function() |> baz() |> bar() |> foo()

other_other_function()
|> other_function() 
|> new_function() 
|> baz() 
|> bar() 
|> foo()

```

## Příklady

Pro tyhle příklady použijeme String modul.

- Tokenize String (loosely)

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Velká písmena pro všechny tokeny

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Kontrola konce

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Best Practices

Jestli je arita funkce více než 1, v takovém případě použíjte závorky.
KDyž použijeme náš třetí přiklad bez závorek u `String.ends_with?/2`, dostaneme následující varování.

```elixir
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call.
For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
