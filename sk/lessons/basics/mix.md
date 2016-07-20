---
layout: page
title: Mix
category: basics
order: 9
lang: sk
---

Než sa pustíme do hlbokých vôd, je treba sa pozrieť na nástroj `mix`. Ak poznáte Ruby, mix vám bude propomínať kombináciu nástrojov Bundler, RubyGems a Rake. Je kľúčovou súčasťou každého elixirového projektu a v tejto lekcii si ukážeme niekoľko jeho najdôležitejších funkcií. Vyčerpávajúci zoznam všetkých jeho možností získate príkazom `mix help`.

Doteraz sme pracovali len s interaktívnym príkazovým riadkom `iex`, ktorý však má svoje limity. Pri každom skutočnom projekte potrebujeme svoj kód rozdeliť do samostatných súborov v rôznych adresároch podľa ich významu. Mix nám s tým pomôže.

{% include toc.html %}

## Nový projekt

Pripravení na vytvorenie prvého elixirového projektu? Stačí spustiť `mix new` a mix nám vygeneruje kompletnú adresárovú štruktúru projektu spolu so základnými súbormi potrebnými pre rozbeh aplikácie:

```bash
$ mix new example
```

Z výstupu príkazu vidno, že boli vytvorené všetky štandardné adresáre a súbory:

```bash
* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

V tejto lekcii sa zameriame hlavne na súbor `mix.exs`. V ňom sa nachádza konfigurácia nášho projektu, jeho závislostí, verzií a prostredí pre beh. Po otvorení súboru v editore uvidíme niečo takéto (komentáre v kóde vynechávame v záujme stručnosti):

```elixir
defmodule Example.Mixfile do
  use Mix.Project

  def project do
    [app: :example,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
```

V sekcii `project` definujeme meno projektu (`app`), špecifikujeme jeho verziu (`version`), použitú verziu jazyka Elixir (`elixir`) a nakoniec závislosti (`deps`).

Sekcia `application` slúži na špecifikovanie aplikácii (menších častí projektu, napríklad webserver, logger, databázový pool a podobne), ktoré náš projekt spúšťa a sú potrebné pre jeho beh.

## Kompilácia

Mix je natoľko inteligentný, že dokáže sám zistiť, že sme niečo zmenili a treba to prekompilovať, no občas sa stane, že potrebujeme ručne skompilovať celý projekt. Vtedy stačí v kmeňovom adresári projektu spustiť príkaz `mix compile`:

```bash
$ mix compile
```

V našom projekte zatiaľ skoro nič nie je, takže kompilácia by mala prebehnúť rýchlo a bez problémov:

```bash
Compiled lib/example.ex
Generated example app
```

Pri prvej kompilácii vytvorí mix v projekte adresár `_build`, do ktorého uloží všetok skompilovaný kód. Keď sa do tohto adresára pozrieme, zbadáme našu skompilovanú aplikáciu: `example.app`.

## Interaktívny režim

Niekedy by sa nám hodilo spustiť interaktívny príkazový riadok `iex` v kontexte nášho projektu. Našťastie, mix to umožňuje jednoduchým vytvorením iex session:

```bash
$ iex -S mix
```

Takto povieme iex-u, aby pri svojom spustení rešpektoval všetko, čo je uvedené v súbore `mix.exs`, tzn. natiahol závislosti, pripravil naše vlastné moduly, nastavil behové prostredie a podobne. Môžeme tak priamo z konzoly pracovať s našou bežiacou aplikáciou.

## Závislosti

Náš projekt môže využívať rôzne externé balíčky - v tom prípade je nutné ich niekde explicitne zadefinovať, aby ich mix vedel stiahnuť a pridať do projektu.

V súbore `mix.exs` je definovaná funkcia `deps`, ktorá vracia zoznam balíčkov, na ktorých je projekt závislý. Prvkami tohto zoznamu sú tuple, ktoré obsahujú vždy meno balíčka (atom), jeho verziu (reťazec) a voliteľne aj pomocné parametre. Ak teda chceme pridať do projektu balíček, stačí pridať tuple do zoznamu, ktorý táto funkcia vracia.

Pozrime sa na ukážku z nejakého projektu so závislosťami, napríklad [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [{:phoenix, "~> 1.1 or ~> 1.2"},
   {:phoenix_html, "~> 2.3"},
   {:cowboy, "~> 1.0"},
   {:slime, "~> 0.14"}]
end
```

Ako ste si zrejme domysleli, balíček `cowboy` je nutný len pri vývoji (*development* a testovaní (*test*), v ostrej prevádzke (*production*) ho nepotrebujeme.

Po pridaní závislostí do `deps` nám zostáva už len povedať mixu, aby ich stiahol (v Ruby tomu zodpovedá príkaz `bundle install`):

```bash
$ mix deps.get
```

To je všetko! Definovali a stiahli sme závislosti nášho projektu.

## Prostredia

Mix, rovnako, ako Bundler, podporuje rôzne behové prostredia. Tri základné prostredia, s ktorými projekt ráta hneď po svojom vygenerovaní, sú:

+ `:dev` — vývojové prostredie - v ňom beží aplikácia na našom počítači, keď na nej pracujeme.
+ `:test` — testovacie prostredie - nastaví sa automaticky, keď príkazom `mix test` spustíme naše testy.
+ `:prod` — produkčné prostredie - aplikácia v ňom beží po ostrom nasadení.

V kóde zistíme aktívne prostredie funkciou `Mix.env`.

Behové prostredie môžeme nastaviť pomocou premennej operačného systému `MIX_ENV`, napríklad:

```bash
$ MIX_ENV=prod mix compile
```
