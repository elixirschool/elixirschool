---
version: 0.9.1
layout: page
title: Dokumentácia
category: basics
order: 11
lang: sk
---

Komentovanie a dokumentovanie kódu v Elixire.

{% include toc.html %}


## O dokumentovaní v Elixire

Čo všetko a ako podrobne komentovať a dokumentovať zostáva vo svete programovania stále otvorenou otázkou. Všetci sa však asi zhodneme na tom, že dokumentovanie kódu je dôležité pre nás samotných a aj ďalších ľudí, ktorí budú s našim kódom pracovať.

Elixir berie dokumentáciu ako svoju plnohodnotnú súčasť (*first-class citizen*) a ponúka rôzne funkcie pre jej generovanie a jednoduchý prístup k nej. Jadro jazyka ponúka viacero možností anotácie kódu, pozrime sa na základné tri:

  - `#` - pre inline komentáre
  - `@doc` - pre dokumentáciu funkcií
  - `@moduledoc` - pre dokumentáciu celých modulov

### Inline komentáre

Najjednoduchším spôsobom dokumentácie kódu sú inline komentáre. Podobne ako v jazykoch Ruby a Python aj Elixir používa na ich označenie znak `#`:

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts "Hello, " <> "chum."
```

Pri spracovaní tohto kódu Elixir riadok s komentárom odignoruje. Komentár kód nespomalí, no programátorovi ušetrí čas, ktorý by musel stráviť lúštením významu kódu. Treba ich však používať s mierou a nezneužívať ich na rozsiahlejšiu dokumentáciu.

### Dokumentovanie modulov

Anotácia `@moduledoc` nám dovoľuje priamo v kóde zdokumentovať modul. Väčšinou sa používa hneď na začiatku modulu pod riadkom s deklaráciou `defmodule`:

```elixir
defmodule Greeter do
  @moduledoc """
  Poskytuje funkciu `hello/1` ktorá pekne pozdraví
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Dokumentáciu k modulu môžeme zobraziť v konzole IEx pomocnou funkciou `h`:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter

                Greeter

Poskytuje funkciu hello/1 ktorá pekne pozdraví
```

*(Funkcia `c` skompiluje súbor, ktorý dostane v argumente. Modul Greeter si musíme najprv skompilovať, aby sme mohli pristupovať k jeho dokumentácii (a k dokumentácii jeho funkcií).)*

### Dokumentovanie funkcií

Podobne ako pri moduloch, môžeme vytvárať aj dokumentáciou samotných funkcií - pomocou anotácie `@doc`. Je zvykom dokumentovať funkcie hneď nad ich definíciou:

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Vypíše pozdrav

  ## Parametre

    - name: reťazec s menom zdravenej osoby

  ## Príklady

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

Keď teraz naštartujeme IEx a zobrazíme si dokumentáciu k našej funkcii pomocou `h`, mali by sme vidieť niečo takéto:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

`hello/1` Vypíše pozdrav

Parametre

  • name: reťazec s menom zdravenej osoby

Príklady

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Všimnime si, že v dokumentácii je možné používať formátovanie textu pomocou markdown syntaxe. Naša dokumentácia potom vyzerá veľmi prehľadne - či už priamo v konzole alebo vo vygenerovanej HTML verzii pri použití ExDoc.

## ExDoc

ExDoc je oficiálny nástroj Elixiru, ktorý dokáže **vygenerovať HTML dokumentáciu vášho elixirového projektu**. Je dostupný ako open-source na [GitHube](https://github.com/elixir-lang/ex_doc).

Vyskúšajme si ExDoc. Potrebujeme elixirový projekt, takže si vytvorme nový pomocou Mixu:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating mix.exs
* creating config
* creating config/config.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Teraz vytvoríme súbor `lib/greeter.ex` a skopírujeme doňho príklad z časti o dokumentovaní funkcií. Spustíme si IEx s načítaným projektom pomocou `iex -S mix` a skúsime zobraziť dokumentáciu funkcie `hello/1` pomocou `h`:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Inštalácia

Ak všetko prebehlo hladko, môžeme nainštalovať samotný ExDoc. V súbore `mix.exs` pridáme do závislostí projektu dva balíčky - `:earmark` a `:ex_doc`:

```elixir
  def deps do
    [{:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
```

Pri oboch balíčkoch sme pomocou `only: :dev` špecifikovali, že ich chceme sťahovať a kompilovať len vo vývojovom prostredí (v produkčnom nepotrebujeme generovať dokumentáciu, už ju máme).

Balíček Earmark je elixirový parser markdownu a umožňuje nám pekne formátovať text dokumentácie vo vnútri `@moduledoc` a `@doc`. Na tento účel môžeme namiesto Earmarku použiť aj iné formátovače, napríklad Pandoc, Hoedown alebo Cmark - treba však siahnuť hlbšie do konfigurácie (detaily [tu](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool)).

Spusíme inštaláciu pridaných balíčkov:

```bash
$ mix deps.get # stiahne a nainštaluje do projektu ExDoc a Earmark
```

### Generovanie dokumentácie

Máme všetko potrebné zostáva nám už len spustiť generátor:

```bash
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

Ak príkaz zbehol, mali by sme v našom projekte vidieť nový adresár `doc/` a v ňom naša vygenerovaná HTML dokumentácia projektu. Otvorme si súbor `doc/index.html` a mali by sme vidieť niečo takéto:

![ExDoc Screenshot 1]({{ site.url }}/assets/documentation_1.png)

Vidíme, že text je vďaka Earmarku pekne formátovaný.

![ExDoc Screenshot 2]({{ site.url }}/assets/documentation_2.png)

Teraz môžeme dokumentáciu hodiť na GitHub, náš vlastný web, alebo na [HexDocs](https://hexdocs.pm/) (ak sme vytvorili verejný balíček).

## Best Practices

Dokumentácia by mala dodržiavať pravidlá a postupy bežné v danom jazyku. Keďže je Elixir stále relatívne mladým jazykom, niektoré štandardy stále nie sú ustálené. Komunita sa však snaží zbierať a dokumentovať ustálené pravidlá na webe [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide). Určite stojí za návštevu. Pozrime sa na pravidlá a odporúčania ohľadom dokumentácie:

  - Vždy dokumentujte svoje moduly

```elixir
defmodule Greeter do
  @moduledoc """
  Toto je dokumentácia modulu.
  """

end
```

  - Ak svoj modul zatiaľ nechcete dokumentovať, nevynechajte `@moduledoc` - pridajte aspoň prázdnu (false) anotáciu:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

  - Keď v dokumentácii modulu spomínate niektorú jeho funkciu, použite spätné apostrofy (backticks):

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  Tento modul obsahuje funkciu `hello/1`.
  """

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

  - Pod dokumentáciou vždy nechajte jeden voľný riadok:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  Tento modul obsahuje funkciu `hello/1`.
  """

  alias Goodbye.bye_bye
  # a tak ďalej...

  def hello(name) do
    IO.puts "Hello, " <> name
  end
end
```

  - Používajte markdown, aby vaša dokumentácia boľa prehľadná a ľahko čitateľná:

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t) :: String.t
  def hello(name) do
    "Hello, " <> name
  end
end
```

  - Pokúste sa do dokumentácie priložiť aj nejaké príklady použitia. Okrem iného vám to umožní vygenerovať automatické testy funkcií, modulov, či makier pomocou nástroja [ExUnit.DocTest](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html).
