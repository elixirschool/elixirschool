---
version: 0.9.0
title: Mønstersammenligning
---

Mønstersammenligning (pattern matching) er en viktig del av Elixir, og lar oss matche enkle verdier, datastrukturer og funksjoner. Vi skal nå se nærmere på hva mønstersammenligning innebærer.

{% include toc.html %}

## Sammenligningsoperatoren (Match Operator)

Operatoren `=` er i Elixirs tilfelle en sammenligningsoperator, og vi bruker den til å tildele og matche verdier. La oss se på noen eksempler:

```elixir
#tildeling
iex> x = 1
1
```

La oss prøve med en enkel sammenligning:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

La oss nå prøve med noen av kolleksjonene vi allerede er kjente med:

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Festeoperatoren (Pin Operator)

Hva vi nettopp lærte, er at sammenligningsoperatoren tildeler når venstre siden av en sammenligning er en variabel. I noen tilfeller er dette uønsket, og vi kan da benytte oss av festeoperatoren: `^`.
Når vi fester en variabel sammenligner vi den med den eksisterende verdien uten å binde variabelen til en ny verdi. La oss se hvordan dette fungerer:


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

Elixir 1.2 introduserte støtte for festing i kartnøkler og funksjonsklausuler:

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

Et eksempel av festing i funksjonsklausuler:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
```

