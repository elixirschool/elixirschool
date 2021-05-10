%{
  version: "1.1.0",
  title: "Funkcie",
  excerpt: """
  V Elixire, tak ako iných funkcionálnych jazykoch, sú funkcie základným konceptom. Povieme si o rôznych typoch funkcií v Elixire, rozdiely medzi nimi a ako ich použiť.
  """
}
---

## Anonymné funkcie

Ako naznačuje už ich názov, tieto funkcie nemajú meno. V kapitole o `Enum` sme videli, že sa často odovzdávajú ako argumenty iným funkciám. Na definovanie anonymnej funkcie slúžia v Elixire kľúčové slová `fn` a `end`. Medzi nimi môžeme definovať ľubovoľné množstvo kombinácii argumentov a tiel funkcií - oddelených operátorom `->`.

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

Ako ste asi uhádli, v skrátenom zápise máme k dodaným argumentom prístup cez `&1`, `&2`, `&3` atď.

## Pattern matching

V Elixire nie je pattern matching obmedzený len na premenné - môže byť využitý aj v hlavičkách funkcií. Jeho aplikáciou na vstupné argumenty sa určí, ktoré telo funkcie sa použije (to, ktoré prislúcha k prvej vyhovujúcej hlavičke).

Elixir používa pattern matching na nájdenie zhodnej funkcie a zvolí prvú vyhovujúcu funkciu:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

V príklade sme si definovali funkciu s dvoma telami. Pri jej prvom volaní sa použilo prvé telo, keďže sme jej ako argumenty poslali tuple v tvare `{:ok, result}`. Pri druhom volaní sa použilo druhé telo, keďže ako argument od nás dostala tuple v tvare `{:error}`.

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

### Pomenovanie funkcií a počet argumentov

Už sme si spomenuli skôr, že funkcie sú pomenované kombináciou ich mena a počtom argumentov (`arity`). To znamená, že môžeme spraviť aj niečo ako:

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

V komentároch máme mená funkcii vyššie. Prvá implementácia nemá žiadne argumenty, tak je označená ako `hello/0`. Druhá funkcia má jeden argument, takže jej názov je `hello/1` atď.
Narozdiel od iných jazykov, kde by takéto niečo bolo považované za preťaženie funkcie, no v Elixire sú považované za úplne od seba _rôzne_ funkcie. (Pattern matching, spomenutý vyššie je použitý iba vtedy, keď poskytneme viac definícií pre funkciu s _rovnakým_ počtom argumentov.)

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

V nasledujúcom príklade máme dve funkcie s tou istou hlavičkou, no rôznymi hraničnými podmienkami. Testujeme typ parametra:

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

### Východiskové hodnoty argumentov

Ak chceme, aby mal niektorý z argumentov funkcie východiskovú hodnotu, použijeme syntax `argument \\ hodnota`:

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
