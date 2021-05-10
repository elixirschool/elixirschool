%{
  version: "0.9.1",
  title: "Strenger",
  excerpt: """
  Strenger, Karakter lister, Grafemer og Kode punkter.
  """
}
---

## Strenger

En streng i Elixir er ikke noe annet enn en sekvens av byte. La oss se på et eksempel:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
```

>NOTE: Ved bruk av syntaksen << >> så sier vi til kompilatoren at elementene på innsiden av det symbolet er bytes.

## Karakter lister

Internt, så er strenger i Elixir representert som en sekvens av bytes og ikke som en array av bokstaver. Elixir har også en karakter list type. En streng i Elixir er definert med dobbel anførselstegn ("streng"), mens en karakter liste er definert med enkelt anførsesltegn ('karakter liste').

Så hva er forskjellen? Hver verdi fra en karakter liste er ASCII verdien for karakteren. La oss ta en titt:

```elixir
iex> char_list = 'hello'
'hello'

iex> [hd|tl] = char_list
'hello'

iex> {hd, tl}
{104, 'ello'}

iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

Når man programmerer i Elixir, så bruker vi strenger, og ikke karakter lister. Grunnen til at vi har karakter lister i Elixir, er fordi noen Erlang moduler bruker karakter lister og ikke strenger.

## Grafemer og Kode punkter

Et kode punkt er bare en enkle Unicode karakterer, som er representert med en eller flere bytes, avhengig av UTF-8 enkodingen. Karakterer som ikke er med i den amerikanske ASCII standarden vil alltid enkodes med mer enn en byte. For eksempel, latinske karakterer med en tilde eller aksenter (`á, ñ, è`) er typisk enkodet med to bytes. Karakterer fra asiatiske språk er ofte enkodet med tre eller fire bytes. Mens grafemer vil bestå av et eller flere kode punkt som representerer en enkel karakter.

Streng modulen har to metoder for å få tak i dem, `graphemes/1` og `codepoints/1`. La oss ta en titt på et eksempel:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

# Streng funksjoner

La oss ta en titt på noen av de viktigste og mest brukbare funksjonene i String modulen. Vi vil kun gå gjennom et par av funksjonene tilgjengelig i String modulen. For å se alle tilgjengelige funksjoner kan du se på den offisielle [`String`](https://hexdocs.pm/elixir/String.html) dokumentasjonen.

### length/1

Returnerer antallet grafemer i strengen.

```elixir
iex> String.length "Hello"
5
```

### replace/3

Returnerer en ny streng som erstatter et mønster i den nåværende strengen med en ny streng.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### duplicate/2

Returnerer en ny streng som er repetert n ganger etter hverandre.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### split/2

Returnerer en liste av strenger som er splittet basert på et gitt mønster.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Øvelser

La oss gå gjennom et par enkle øvelser for å forstå strenger i Elixir bedre.

### Anagrammer

A og B er anagrammer hvis det er mulig å omskrive ordet på en måte som gjør den like. For eksempel:

+ A = super
+ B = perus

Hvis endrer rekkefølgen på bokstavene i strengen A, så kan vi få strengen B og omvendt.

Så hvordan kan vi sjekke om to strenger er anagrammer i Elixir? Den enkleste måten er å sortere grafemene i hver streng alfabetisk også sjekke om de er like. La oss prøve det ut:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

La oss først ta en titt på `anagrams?/2`. Vi sjekker først om paramaterene vi mottar er en binary eller ikke. Dette er en måten vi kan sjekke om en parameter er en streng i Elixir.

Etter det, så kaller vi bare funksjonen som ordner strengen i alfabetisk rekkefølge, først så vil den gjøre om alle bokstavene til småbokstaver også vil den bruke `String.graphemes`, som returner en liste med grafemer for strengen.

La oss se på resultatet i iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Som du kan se, det siste kallet til `anagrams?` førte til at vi fikk en FunctionClauseError. Denne feilen forteller oss at det ikke finnes en funksjon i vår modul som tar to ikke-binaries som argument, og det er akkurat det vi ønsker, at vi kun skal motta to strenger, ikke noe annet.