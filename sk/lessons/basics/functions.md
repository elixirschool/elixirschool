---
version: 1.1.0
title: Funkcie
---

V Elixire, tak ako iných funkcionálnych jazykoch, sú funkcie základným konceptom. Povieme si o rôznych typoch funkcií v Elixire, rozdiely medzi nimi a ako ich použiť.

{% include toc.html %}

## Anonymné funkcie

Ako naznačuje už ich názov, tieto funkcie nemajú meno. V kapitole o `Enum` sme videli, že sa často odovzdávajú ako argumenty iným funkciám. Na definovanie anonymnej funkcie slúžia v Elixire kľúčové slová `fn` a `end`. Medzi nimi môžeme definovať ľubovoľné množstvo parametrov a volaní funkcií - oddelených operátorom `->`.

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

Ako ste asi uhádli, v skrátenom zápise máme k dodaným parametrom prístup cez `&1`, `&2`, `&3` atď.

## Pattern matching

V Elixire nie je pattern matching obmedzený len na premenné - môže byť využitý aj v hlavičkách funkcií ako si ukážeme v tejto sekcii.

Elixir používa pattern matching na nájdenie zhodnej funkcie a zvolí prvú vyhovujúcu funkciu:

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

## Pomenované funkcie

Funkcie môžeme definovať menom aby sme na ne mohli odkazovať neskôr. Pomenované funkcie sú definované v moduloch s použitím kľúčového slova `def`. O Moduloch si povieme viac v ďalšej lekcii, teraz sa budeme sústrediť iba na pomenované funkcie

Funkcie definované v module sú k dispozícii pre použitie v iných moduloch. Toto je veľmi užitočný stavebný blok v Elixire:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Ak má telo funkcie len jeden riadok, môžme ho skrátiť pomocou zápisu s `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Vyzbrojení našími znalosťami o pattern matchingu, si vyskúšajme rekurziu pomocou pomenovaných funkcií:

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

### Pomenovanie funkcií a počet parametrov

Už sme si spomenuli skôr, že funkcie sú pomenované kombináciou ich mena a počtom parametrov (`arity`). To znamená, že môžeme spraviť aj niečo ako:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

V komentároch máme názvy funkcii vyššie. Prvá implementácia nemá žiadne argumenty, tak je označená ako `hello/0`. Druhá funkcia má jeden argument, takže jej názov je `hello/1` atď. Narozdiel od iných jazykov, kde by takéto niečo bolo považované za preťaženie funkcie, no v Elixire sú považované za úplne _rôzne_ funkcie. (Pattern matching, spomenutý vyššie je použitý iba vtedy, keď poskytneme viac definícií pre funkciu s _rovnakým_ počtom parametrov.)

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
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Hraničné podmienky

Hraničných podmienok (*guards*) sme sa krátko dotkli v kapitole o [riadiacich štruktúrach](../control-structures). Teraz sa pozrieme na ich využitie pri definovaní pomenovaných funkcií.
Keď Elixir vybral funkciu, akékoľvek existujúce hraničné podmienky budú otestované.

V nasledujúcom príklade máme dve funkcie s tou istou hlavičkou, no rôznymi hraničnými podmienkami, kde testujeme typ parametra:

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

### Východiskové hodnoty

Ak chceme, aby mal niektorý z parametrov funkcie východiskovú hodnotu, použijeme syntax `argument \\ hodnota`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("sk"), do: "Ahoj, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "sk")
"Ahoj, Sean"
```

Problém môže nastať, ak nevhodne skombinujeme hraničné podmienky s východiskovými parametrami:

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

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir nerád vidí východiskové argumenty vo viacerých zhodných hlavičkách funkcie, pretože to môže byť mätúce. Riešenie spočíva v pridaní hlavičky s východiskovými argumentami, pričom z pôvodných hlavičiek východiskové argumenty odstránime:

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
