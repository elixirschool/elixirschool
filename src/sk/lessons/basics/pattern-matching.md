---
version: 0.9.1
title: Pattern Matching
---

Pattern matching je dôležitou a mocnou vymoženosťou Elixiru. Umožňuje nám hľadať a vyberať jednoduché hodnoty, dátové štruktúry a dokonca aj funkcie. V tejto lekcii si ukážeme, ako ho používať.

{% include toc.html %}

## Match operator

Pripravení na prekvapko? V Elixire je operátor `=` v skutočnosti match operátorom. Pomocou neho môžeme nachádzať, vyberať a priraďovať časti vyhovujúce našim kritériam.

Nasledujúcim spôsobom matchneme hocičo (nešpecifikujeme žiadne kritériá) a priradíme to do premennej `x`:

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

Druhý výraz zlyhal, pretože v premennej `x` už bola hodnota `1`, takže nenastala zhoda (match).

Teraz to skúsme s nejakou kolekciou:

```elixir
# Zoznamy
iex> list = [1, 2, 3]
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

## Pin operator

Práve sme sa naučili, že *match* operátor vykoná priradenie, ak sa na jeho ľavej strane nachádza premenná. Niekedy je však toto chovanie (tzv. *variable rebinding*) nežiadúce - pre tieto prípady existuje v Elixire operátor *pin*: `^`.

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

V príklade sme si definovali funkciu `greet` dvojitým spôsobom - ak ako prvý parameter prijme reťazec `"Hello"`, vykoná sa prvá verzia tela, inak sa použije druhá.
