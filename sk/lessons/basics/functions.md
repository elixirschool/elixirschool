---
version: 0.9.1
title: Funkcie
---

V Elixire, tak ako iných funkcionálnych jazykoch, sú funkcie ústredným konštruktom. Povieme si o rôznych typoch funkcií v Elixire, rozdieloch medzi nimi a ako ich používať.

{% include toc.html %}

## Anonymné funkcie

Ako naznačuje už ich názov, tieto funkcie nemajú priradené meno. V kapitole o `Enum` sme videli, že sa často odovzdávajú ako argumenty iným funkciám. Na definovanie anonymnej funkcie slúžia v Elixire kľúčové slová `fn` a `end`. Medzi nimi môžeme definovať ľubovoľné množstvo sád parametrov a tiel funkcií - oddelených operátorom `->`.

Pozrime sa na jednoduchý príklad:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

Všimnite si, že anonymnú funkciu je nutné volať cez `.`.

### Skratka &

Používanie anonymných funkcií je v Elixire natoľko bežné, že na ich definovanie existuje skrátený zápis pomocou `&`:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Ako ste asi uhádli, v skrátenom zápise pristupujeme k parametrom cez `&1` (prvý odovzdaný parameter), `&2` (druhý odovzdaný parameter) atď.

## Pattern matching

V Elixire nie je pattern matching obmedzený len na premenné - môže byť využitý aj v hlavičkách funkcií. Jeho aplikáciou na vstupné premenné sa určí, ktoré telo funkcie sa použije:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

V príklade sme si definovali funkciu s dvoma telami. Pri jej prvom volaní sa použilo prvé telo, keďže sme jej ako parameter poslali tuple v tvare `{:ok, result}`. Pri druhom volaní sa použilo druhé telo, keďže ako parameter od nás dostala tuple v tvare `{:error}`.

## Pomenované funkcie

Druhým spôsobom, ako definovať funkciu, je priradiť jej už pri definícii meno, ktorým na ňu neskôr budeme odkazovať. Pri tomto spôsobe použijeme kľúčové slovo `def` vo vnútri nejakého modulu (o moduloch si povieme viac v ďalšej lekcii).

Funkcie definované v module sú k dispozícii pre použitie v iných moduloch. V Elixire sú moduly jedným z najdôležitejších stavebných blokov.

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Ak má telo funkcie len jediný riadok, môžme použiť kratší zápis definície pomocou `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Vyzbrojení pattern matchingom, vyskúšajme si rekurziu pomocou pomenovaných funkcií:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Privátne funkcie

Ak nechceme, aby naša funkcia mohla byť volaná z iných modulov, môžeme ju zadefinovať ako privátnu - takto ju bude možné volať len z vnútra jej vlastného modulu. Na definovanie privátnych funkcií slúži kľúčové slovo `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) undefined function: Greeter.phrase/0
    Greeter.phrase()
```

Volanie funkcie `Greeter.phrase` vyhodilo chybu, pretože bola definovaná ako privátna a my sme ju zavolali zvonka.

### Hraničné podmienky

Hraničných podmienok (*guards*) sme sa krátko dotkli v kapitole o [riadiacich štruktúrach](../control-structures). Teraz sa pozrieme na ich využitie pri definovaní pomenovaných funkcií.

Hraničné podmienky sú vyhodnocované hneď po tom, čo Elixir pattern matchingom vyberie jedno z definovaných tiel funkcie.

V nasledujúcom príklade máme dve funkcie s tou istou hlavičkou, no rôznymi hraničnými podmienkami testujeme typ argumentu:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

Prvé telo sa použije, ak je argument typu zoznam, druhé ak je argumentom reťazec.

### Východiskové argumenty

Ak chceme, aby mal niektorý z argumentov funkcie východiskovú hodnotu, použijeme syntax `argument \\ hodnota`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Problém môže nastať, ak nevhodne skombinujeme hraničné podmienky s východiskovými argumentami:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) def hello/2 has default values and multiple clauses, define a function head with the defaults
```

Elixir nevidí rád východiskové argumenty vo viacerých zhodných hlavičkách funkcie, pretože to môže byť mätúce. Riešenie spočíva v pridaní hlavičky s východiskovými argumentami, pričom z pôvodných hlavičiek východiskové argumenty odstránime:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")
  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
