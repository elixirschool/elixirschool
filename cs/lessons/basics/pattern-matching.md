---
version: 1.0.2
title: Pattern Matching | Shoda vzorů

---

Pattern matching je velmi silná část Elixíru. Dovoluje nám shodu jednoduchých hondot, datových struktur, a dokonce i funkcí.
V téhle lekci uvidíme jak je pattern matching používán.

{% include toc.html %}

## Match Operator | Operátor shody

Jste připravení na kouzlo? V Elixiru je `=` operátor ve skutečnosti operátor shody, naprosto shodně jak byste jej užili v matematice... ano přesně tak. Jeho napsání změní celý výraz na rovnici a Elixír porovná shodu hodnoty na levé straně s hodnotou na pravé straně. Jestli jsou hodnoty shodné, vráti hodnotu rovnice. V opačném případě vyhodí error. Pojďme se podívat:

```elixir
iex> x = 1
1
```

Teď zkusme jednoduchou shodu:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Teď to zkusme s nějakou kolekcí co již známe:

```elixir
# Lists
iex> list = [1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2 | _] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Pin operátor

Operátor shody vykonává přiřazení když levá strana shody obsahuje proměnnou.
V některých případech je znovu přiřazení nové hodnoty nežádoucí.
Na tyhle situace máme pin operátor: `^`.

Když "připneme" proměnnou na existující hodnotu, porovnáme shodu s již existující hodnotou, nevytvoříme hodnotou novou.
Pojďme se podívat jak to funguje:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Od verze Elixíru 1.2, podporuje pin operátor i funkce a mapy:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Příklad použití pin operátoru ve funkci:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   ("Hello", name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.(^greeting, "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
iex> greeting
"Hello"
```

