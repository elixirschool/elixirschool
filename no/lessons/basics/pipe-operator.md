---
version: 0.9.1
title: Pipeoperatoren
---

Pipeoperatoren `|>` fører resultatet av et utrykk som første parameter til et nytt utrykk.

{% include toc.html %}

## Introduksjon

Programmering kan bli rotete. Funksjoner som kaller på andre funksjoner kan bli så integrerte at de blir vanskelig å følge. Ta en titt på dette eksemplet av nestede funksjoner:

```elixir
foo(bar(baz(new_function(other_function()))))
```

Her fører vi verdien `other_function/0` til `new_function/1`, og `new_function/1` til `baz/1`, og `baz/1` til `bar/1`, og til slutt resultatet av `bar/1` til `foo/1`. Elixir har en pragmatisk løsning på dette syntaktiske rotet - pipeoperatoren. Pipeoperatoren `|>` *tar resultatet av et utrykk og fører det videre*. La oss ta eksemplet over, og skrive det om ved hjelp av pipeoperatoren:

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

Pipeoperatoren tar resultatet på venstre side, og fører det over som første argument på høyre side.

## Eksempler

Disse eksemplene benytter seg av Elixirs innebygde Strengemodul.

- Tokenisering av streng (løs)

```shell
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- Token i store bokstaver

```shell
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- Kontrollere endingen av en streng

```shell
iex> "elixir" |> String.ends_with?("ixir")
true
```

## Beste Praksis

Hvis nummeret av argumenter til en funksjon(aritet) er mer enn 1, må vi benytte oss av paranteser. Dette er ikke så viktig for Elixir, men det er viktig for andre utviklere som kan misforstå kodene du har skrevet. Hvis vi tar det tredje eksemplet over, og fjerner parantesene fra `String.ends_with?/2` gir Elixir oss en advarsel:


```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
