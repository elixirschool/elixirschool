---
version: 0.9.0
title: Enum
---

Et sett med algoritmer for å iterere over kolleksjoner.

{% include toc.html %}

## Enum

Modulen `Enum` inneholder over hundre funksjoner som vi kan benytte av oss når vi jobber med kolleksjoner.

Denne leksjonen vil kun dekke en brøkdel av de tilgjengelige funksjonene. For en komplett liste av alle funksjonene, se den offisielle  [`Enum`](https://hexdocs.pm/elixir/Enum.html) dokumentasjonen, eller [`Stream`](https://hexdocs.pm/elixir/Stream.html) for lazy enums.


### all?

Ved bruk av `all?` (og de fleste andre av Enums funksjoner), forsyner vi kolleksjonens elementer med en funksjon. I `all?` sitt tilfelle, må hele kolleksjonen evalueres til `true`, ellers vil `false` bli returnert:


```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

I motsetning til eksemplet over, vil `any?` returnere `true` hvis minst et av elementene evalueres til `true`:

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every/2

Hvis vi trenger å dele opp kolleksjonen i mindre deler, kan vi benytte oss av funksjonen `chunk_every/2`:

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

Det finnes flere alternativer for `chunk_every/2`, men vi blir ikke å gå igjennom dem. Se  [`chunk_every/4`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4) i den offisielle dokumentasjonen for å lære mer.

### chunk_by

Hvis vi trenger å gruppere kolleksjonen vår basert på noe annet enn størrelse, kan vi bruke funksjonen `chunk_by`. Den tar en gitt kolleksjon og en funksjon som argument, og når retur verdien av funksjonen endrer seg så vil en ny gruppe bli lagd og den starter så å lage den neste gruppen:

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

Noen ganger så vil det å dele opp en kolleksjon, ikke være akkurat det vi trenger. Hvis dette er tilfellet så kan `map_every/3` brukes til å kun endre på spesifikke elementer.

```elixir
iex> Enum.map_every([1, 2, 3, 4], 2, fn x -> x * 2 end)
[2, 2, 6, 4]
```

### each

Det kan bli nøvendig å måtte iterere over en kolleksjon uten å produsere en verdi. Vi kan da bruke funksjonen `each`:

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__Merk__: Funksjonen `each` returnerer atomet `:ok`.

### map

For å forsyne funksjonen vår til hvert element, og produsere en ny kolleksjon kan vi benytte oss av `map`:

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

For å finne den minste verdien i kolleksjonen vår kan vi bruke `min/1`:

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

Funksjonen `min/2` gjør det samme, men tillater oss å spesifisere en standard verdi til `Enum` i en anonym funksjon som blir sendt inn:

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` returnerer den største verdien i kolleksjonen:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` gjør det samme og oppfører seg som `min/2`,
den tillater oss å sende inn en anonym funksjon med en standard verdi til `Enum`:


```elixir
Enum.max([], fn -> :bar end)
:bar
```

### reduce

Vi kan vanne ut kolleksjonen vår ned til kun et enkelt element ved å bruke `reduce`. Vi kan tilføye en valgfri akkumulator (`10` i eksemplet under) til funksjonen vår. Hvis ingen akkumulator er gitt, vil det første elementet bli brukt:

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16
iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6
iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

Sortering av en kolleksjon er enkelt ved hjelp av to `sort` funksjoner. Det første alternativet bruker Elixirs eget begrep for sortering til å avgjøre sorteringsrekkefølgen:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

Den andre alternativet lar oss velge sorteringsrekkefølgen selv:

```elixir
# Med vår egen funksjon
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# uten vår egen funksjon
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

Vi kan benytte oss av `uniq_by/2` for å fjerne duplikater fra kolleksjonen vår:

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```

Denne funksjonen var tidligere kjent som `uniq/1` som vil bli deprekert i Elixir 1.4, men fortsatt tilgjengelig (med advarsler).
