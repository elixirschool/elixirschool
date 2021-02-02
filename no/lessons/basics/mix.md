---
version: 0.9.2
title: Mix
---

Før vi kan dykke dypere i Elixir, må vi første lære om Mix. Hvis du er kjent med Ruby, så er Mix ekvivalent med Bundler, RubyGems og Rake kombinert sammen. Mix er en kritisk del av hvilket som helst Elixir prosjekt, og i denne leksjonen vil vi gå igjennom et par av Mix sine fantastiske funksjonaliteter. For å se alt det mix har å tilby kjør `mix help`.

Til nå har vi kun jobbet i `iex`, som har sine begrensninger. For å bygge noe betydelig trenger vi å dele opp prosjektet i flere filer, slik at koden vår blir lettere å jobbe med. Dette er svært enkelt med Mix.

{% include toc.html %}

## Nye Prosjekter

For å opprette et nytt Elixir prosjekt, benytter vi oss enkelt og greit av `mix new`. Denne kommandoen vil opprette prosjektets mappestruktur, samt andre nødvendigheter. La oss hoppe rett ut i det:

```bash
$ mix new example
```
Om vi tar en titt i konsollen vår, kan vi se at mix opprettet de nødvendige filene og mappene vi trenger til prosjektet vårt:

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

I denne leksjonen vil vi rette fokuset mot `mix.exs`. I denne filen konfigurerer vi applikasjonen vår, tilleggspakker, omgivelser og prosjektets versjon. Åpne filen i din foretrukne teksteditor (kommentarene er fjernet for enkelhetens skyld):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```
I første seksjon ser vi `project`. Her gir vi navn til applikasjonen vår (`app`), spesifiserer prosjektets versjon (`version`), Elixir’s versjon (`elixir`) og til slutt andre tilleggspakker (`deps`).

`application` seksjonen er brukt under generering av vår applikasjonsfil, som vi vil dekke neste gang.

## Interaktivt

Det kan være nødvendig å kjøre applikasjonen vår i `iex`. Heldigvis gjør Mix dette veldig enkelt for oss:

```bash
$ cd example
$ iex -S mix
```

Å starte `iex` på denne måten vil laste applikasjonen og tilleggspakkene (`deps`)

## Kompilasjon

Mix er smart, og vil kompilere forandringer når det trengs, men det kan fortsatt være nødvendig å eksplisitt kompilere prosjektet. I denne seksjonen vil vi lære hvordan vi kompilerer prosjektet vårt, og hva kompileringen gjør.

For å kompilere et mix prosjekt så trenger vi kun å kjøre `mix compile` i vår øverste mappe av prosjektet:

```bash
$ mix compile
```
Det er ikke mye som har skjedd i prosjektet vårt, så det som blir skrevet ut er ikke så spennende. Kompileringen burde fullføre uten feil:

```bash
Compiled lib/example.ex
Generated example app
```
Når vi kompilerer et prosjekt, vil mix lage en `_build` mappe for våre artefakter. Om vi tar en titt i `_build` mappen, vil vi se vår kompilerte applikasjon: example.app.

## Håndtere Tilleggspakker

Prosjektet vårt inneholder for øyeblikket ingen tilleggspakker, men det skal vi straks gjøre noe med! La oss nå se på hvordan man definerer tilleggspakker, samt hvordan man henter dem

For å legge til en ny pakke, må vi først legge den til `mix.exs` i `deps` seksjonen. Listen av tilleggspakker består av tupler med to påkrevde og en valgfri verdi; navnet til tilleggspakken som et atom, versjonen til tilleggspakken som en streng, og et valgfritt alternativ.

I dette eksemplet skal vi se på et prosjekt med tilleggspakker - [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```
Som du sikkert ser fra listen av tilleggspakker ovenfor, er `cowboy` kun nødvendig under utvikling og testing. Når vi har definert våre tilleggspakker gjenstår det kun et siste steg - å hente dem. Om du er kjent med Ruby, er dette ekvivalent med `bundle install`:

```bash
$ mix deps.get
```
Og det var det! Vi har definert, og hentet tilleggspakkene som prosjektet vårt avhenger av. Vi har nå lært hvordan man legger til nye tilleggspakker, til prosjektene vi jobber med.

## Omgivelser
Mix, på samme måte som Bundler, støtter forskjellige omgivelser. Prekonfigurert fungerer mix med tre ulike omgivelser:

+ `:dev` — Standard omgivelser
+ `:test` — Brukt av `mix test`. Dekket mer i vår neste leksjon.
+ `:prod` — Brukt når vi skal ta i bruk vår applikasjon i produksjon.

Den nåværende omgivelsen kan bli aksessert ved å bruke `Mix.env`. Merk at vi kan forandre omgivelsene med omgivelsesvariabelen `MIX_ENV`

```bash
$ MIX_ENV=prod mix compile
```
