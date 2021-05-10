---
version: 1.0.3
title: Dokumentácia
---

Dokumentovanie kódu v Elixire.

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
IO.puts("Hello, " <> "chum")
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
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Poskytuje funkciu hello/1 ktorá pekne pozdraví
```

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
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Keď naštartujeme IEx a zobrazíme si dokumentáciu k našej funkcii pomocou `h`, mali by sme vidieť niečo takéto:

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

**Poznámka:** Anotácia `@spec` je používaná pri statickej analýze kódu. Ak chcete vedieť viac, pozrite si lekciu [Špecifikácie a typy](../../../en/lessons/advanced/typespec).

## ExDoc

ExDoc je oficiálny nástroj Elixiru, ktorý dokáže **vygenerovať HTML dokumentáciu vášho Elixir projektu**. Je dostupný ako open-source na [GitHube](https://github.com/elixir-lang/ex_doc).

Vyskúšajme si ExDoc. Potrebujeme Elixir projekt, takže si vytvorme nový pomocou Mixu:

```bash
$ mix new greet_everyone

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
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
  [{:earmark, "~> 0.1", only: :dev}, {:ex_doc, "~> 0.11", only: :dev}]
end
```

Pri oboch balíčkoch sme pomocou `only: :dev` špecifikovali, že ich nechceme sťahovať a kompilovať v produkčnom prostredí. Balíček Earmark je parser markdownu pre Elixir používaný ExDocom, ktorý nám umožňuje formátovať text dokumentácie vo vnútri `@moduledoc` a `@doc` na pekne vyzerajúce HTML.

Stojí však za zmienku, že nie sme nútení používať Earmark. Namiesto Earmarku môžeme použiť aj iné formátovače, ako Pandoc, Hoedown alebo Cmark - treba však siahnuť hlbšie do konfigurácie (detaily si môžete prečítať [tu](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool)). V tomto tutoriáli však zostaneme pri Earmarku.

### Generovanie dokumentácie

Pokračujeme tým, že spustíme dva nasledujúce príkazy:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

Ak všetko prebehlo podľa plánu, mali by sme vidieť podobnú správu ako výstup v príklade vyššie. Teraz sa môžeme pozrieť na náš Mix projekt a mali by sme vidieť nový adresár s menom **doc/**. V ňom je naša vygenerovaná dokumentácia. Ak si otvoríme index stránku v prehliadači mali by sme vidieť niečo takéto:

![ExDoc Screenshot 1]({% asset documentation_1.png @path %})

Vidíme, že text je vďaka Earmarku pekne naformátovaný.

![ExDoc Screenshot 2]({% asset documentation_2.png @path %})

Teraz môžeme dokumentáciu nasadiť na GitHub, náš vlastný web, alebo na [HexDocs](https://hexdocs.pm/) (ak sme vytvorili verejný balíček).

## Best Practices

Dokumentácia by mala dodržiavať pravidlá a postupy bežné v danom jazyku. Keďže je Elixir stále relatívne mladým jazykom, niektoré štandardy stále nie sú ustálené. Komunita sa však snaží zbierať a dokumentovať ustálené pravidlá na webe [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Vždy dokumentujte moduly

```elixir
defmodule Greeter do
  @moduledoc """
  Toto je dokumentácia modulu.
  """

end
```

  - Ak svoj modul nechcete dokumentovať, nevynechajte `@moduledoc` - pridajte aspoň prázdnu (false) anotáciu:

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
    IO.puts("Hello, " <> name)
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
    IO.puts("Hello, " <> name)
  end
end
```

  - Používajte markdown, aby vaša dokumentácia boľa prehľadná a ľahko čitateľná či už v IEx alebo ExDocu.

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
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

  - Pokúste sa do dokumentácie priložiť aj nejaké príklady použitia. Okrem iného vám to umožní vygenerovať automatické testy funkcií, modulov, či makier pomocou nástroja [ExUnit.DocTest](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html). Aby sme to mohli spraviť, musíme zavolať makro `doctest/1` z test casov a napísať príklady zodpovedajúce pokynom v [oficiálnej dokumentácii][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
