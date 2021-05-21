---
version: 1.0.2
title: Pattern Matching
---

Pattern matching je dôležitou a užitočnou časťou Elixiru. Umožňuje nám hľadať a vyberať jednoduché hodnoty, dátové štruktúry a dokonca aj funkcie. V tejto lekcii si ukážeme, ako ho používať.

{% include toc.html %}

## Match operator

Pripravení na prekvapenie? V Elixire je operátor `=` v skutočnosti match operátorom, porovnateľný so znamienkom rovná sa v algebre. Jeho napísaním sa zmení celý výraz na rovnicu a donúti Elixir nachádzať a vyberať časti vľavo z hodnôt, ktoré sú na pravej strane. Ak nastane zhoda a match je úspešný, vráti hodnotu výrazu. Inak vyhodí chybu. Pozrime sa na to:

```elixir
iex> x = 1
1
```

Skúsme niečo zložitejšie:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Skúsme to s nejakou kolekciou, ktorú poznáme:

```elixir
# Zoznamy
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

## Pin operator

Práve sme sa naučili, že *match* operátor vykoná priradenie, ak sa na jeho ľavej strane nachádza premenná. Niekedy je však toto správanie (tzv. *variable rebinding*) nežiadúce a pre tieto prípady existuje v Elixire operátor pin: `^`.

Keď pri pattern matchingu dáme pred premennú pin (`^`), tak tým Elixiru povieme, aby jej hodnotu len použil pri porovnávaní, no nemenil ju:

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

Od verzie 1.2 podporuje Elixir používanie pinov v mapách a definíciách funkcií:

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

Príklad použitia pinu v definícii funkcie:

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

Všimnite si v príklade s `"Mornin'"`, že premenná `greeting` dostane hodnotu `"Mornin'"` iba vo vnútri funkcie. Mimo funkcie má premenná `greeting` stále hodnotu `"Hello"`.
