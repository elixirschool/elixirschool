%{
  version: "0.9.0",
  title: "Comprehensions",
  excerpt: """
  List comprehension er syntaktisk sukker for å iterere seg gjennom en kolleksjon i Elixir. I denne leksjonen så vil vi se på hvordan vi kan bruke comprehensions for både iterering over verdier, men også generering av verdier.
  """
}
---

## Grunnleggende

Som oftest så vil comprehensions bli brukt for å produsere en eller flere konsise uttrykk for `Enum` og `Stream`.
La oss starte med å se på en enkel comprehension også bryte den ned:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Det første vi kan merke oss er bruken av `for` og en generator. Så hva er egentlig en generator? En generator her er uttrykket `x <- [1, 2, 3, 4]` som er med i list comprehensionen. Den er ansvarlig for å generere den neste verdien.

Heldigvis for oss, så er ikke comprehensions begrenset til lister; faktisk så vil de fungere med alle kolleksjoner.

```elixir
# Keyword Lists
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Maps
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Binaries
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Som mange andre ting i Elixir, så er generatorer avhengig av mønstersammenligning (pattern matching) for å sammenligne verdien satt i venstreside av variabelen. I det tilfellet hvor de ikke er like, så vil verdien bli ignorert:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], do: val
["Hello", "World"]
```

Det er mulig å bruke flere generatorer, akkurat som med nøstede løkker:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

For å bedre kunne illustrere iterasjonen som skjer, la oss bruke `IO.puts` for å vise de to genererte verdiene:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

List comprehensions er syntaktisk sukker som burde kun bli brukt, når det er egnet.

## Filtere

Du kan tenke på filtere som en form for vakt for en comprehension. Når den filtrert verdi returnerer `false` eller `nil` så er den eksludert fra den avsluttende listen. La oss iterere oss gjennom en sekvens av tall, hvor vi kun bryr oss om partall. Vi vil bruke `is_even/1` funksjonen fra Integer modulen for å sjekke om en verdi er et partall eller et oddetall.

```elixir
import Integer
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Som generatorer, så kan vi ta i bruk flere filtere. La oss utvide vår sekvens av tall og kun filtrere for verdier som er partall eller tall delelig med 3 som gir et partall.

```elixir
import Integer
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Bruke `:into`

Hva om vi har lyst til å produsere noe annet enn en ny liste? Hvis vi tar i bruk `:into` så har vi muligheten til å gjøre det! Som en tommelfinger regel, `:into` akseptere en hvilken som helst datastruktur som implementerer `Collectable` protokollen.

Med bruk av `:into`, la oss lage en map fra en nøkkelordsliste:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Siden bitstrenger er en kolleksjon så kan vi bruke en list comprehension og `:into` for å lage en streng:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

Det er det! List comprehensions er en enkel måte for å iterere seg gjennom kolleksjoner på en konsis måte.
