---
version: 1.0.2
title: Mix
---

Než sa ponoríme do Elixiru hlbšie, musíme sa naučiť pracovať s nástrojom Mix. Ak poznáte Ruby, Mix vám bude pripomínať kombináciu nástrojov Bundler, RubyGems a Rake. Je kľúčovou súčasťou každého elixirového projektu a v tejto lekcii si ukážeme len niekoľko z jeho skvelých funkcií. Zoznam všetkého, čo vie Mix ponúknuť zobrazíme príkazom `mix help`.

Doteraz sme pracovali výhradne iba s `iex`, čo však má svoje limity. Pri skutočnom projekte potrebujeme kód rozdeliť do samostatných súborov aby sme ho mohli efektívne spravovať. Mix nám s tým pomôže.

{% include toc.html %}

## Nový projekt

Keď sme pripravený vytvoriť nový Elixir projekt, Mix nám to uľahčí príkazom `mix new`. Ten nám vygeneruje štruktúru adresárov projektu a všetky základné súbory:

```bash
$ mix new example
```

Z výstupu príkazu vidíme, že boli vytvorené všetky štandardné adresáre a súbory:

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

V tejto lekcii sa zameriame hlavne na súbor `mix.exs`. V ňom sa nachádza konfigurácia nášho projektu, jeho závislostí, verzií a prostredí pre beh. Po otvorení súboru v editore uvidíme niečo takéto (komentáre v kóde vynechávame v záujme stručnosti):

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

V sekcii `project` definujeme meno projektu (`app`), špecifikujeme jeho verziu (`version`), použitú verziu jazyka Elixir (`elixir`) a nakoniec závislosti (`deps`).

Sekcia `application` slúži na špecifikovanie aplikácii (menších častí projektu, napríklad webserver, logger, databázový pool a podobne), ktoré náš projekt spúšťa a sú potrebné pre jeho beh.

## Interaktívny režim

Možno budeme musieť použiť `iex` v kontexte našej aplikácie. Našťastie pre nás, Mix nám to uľahčí. Môžeme spustiť novú inštanciu `iex` spolu s Mix takto:

```bash
$ cd example
$ iex -S mix
```

Keď spustíme `iex` týmto spôsobom, tak zároveň načíta našu aplikáciu a aj všetky jej závislosti.

## Kompilácia

Mix je natoľko inteligentný, že dokáže sám zistiť, že sme niečo zmenili a treba to prekompilovať, no občas sa stane, že potrebujeme ručne skompilovať celý projekt. V tejto sekcii sa pozrieme ako skompilovať náš projekt a čo kompilácia vykoná.

Pre kompiláciu stačí v kmeňovom adresári projektu spustiť príkaz `mix compile`:

```bash
$ mix compile
```

V našom projekte zatiaľ skoro nič nie je, takže kompilácia by mala prebehnúť rýchlo a bez problémov:

```bash
Compiled lib/example.ex
Generated example app
```

Pri prvej kompilácii vytvorí mix v projekte adresár `_build`, do ktorého uloží všetok skompilovaný kód. Keď sa do tohto adresára pozrieme, zbadáme našu skompilovanú aplikáciu: `example.app`.

## Správa závislostí

Náš projekt nemá žiadne závislosti ale to zmeníme zachvíľu, tak teraz si prezrieme ako definujeme a sťahujeme závislosti.

Ako prvé musíme novú závislosť pridať do `mix.exs` v sekcii `deps`. Zoznam balíčkov je zložený z tuples, ktoré majú dve požadované hodnoty a jednú voliteľnú hodnotu: meno balíčka v tvare atómu, reťazec verzie a voliteľné pomocné parametre.

Pozrime sa na ukážku z nejakého projektu so závislosťami, napríklad [phoenix_slim](https://github.com/doomspork/phoenix_slim):

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

Ako ste si zrejme domysleli, balíček `cowboy` je nutný len pri vývoji a testovaní.

Po pridaní závislostí nám zostáva už len povedať Mixu, aby ich stiahol (v Ruby tomu zodpovedá príkaz `bundle install`):

```bash
$ mix deps.get
```

To je všetko! Definovali a stiahli sme závislosti nášho projektu. Teraz sme pripravení pridať závislosti keď budeme potrebovať.

## Prostredia

Mix, rovnako, ako Bundler, podporuje rôzne behové prostredia. Tri základné prostredia, s ktorými projekt ráta hneď po svojom vygenerovaní, sú:

+ `:dev` — vývojové prostredie - v ňom beží aplikácia na našom počítači, keď na nej pracujeme.
+ `:test` — testovacie prostredie - nastaví sa automaticky, keď príkazom `mix test` spustíme naše testy.
+ `:prod` — produkčné prostredie - používa sa pri nasadení aplikácie na produkčné servery.

V kóde zistíme aktívne prostredie použitím `Mix.env`. Behové prostredie môžeme nastaviť pomocou premennej operačného systému `MIX_ENV`, napríklad:

```bash
$ MIX_ENV=prod mix compile
```
