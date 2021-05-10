%{
  version: "1.1.1",
  title: "Riadiace štruktúry",
  excerpt: """
  V tejto lekcii sa pozrieme na riadiace štruktúry, ktoré máme k dispozícii v Elixire.
  """
}
---

## if a unless

Na funkciu `if/2` ste už pravdepodobne narazili a ak ste pracovali s Ruby, poznáte aj `unless/2`. V Elixire fungujú úplne rovnako, no sú implementované ako makrá, nie sú to skutočné jazykové konštrukty. Ich implementáciu si môžete pozrieť v dokumentácii [modulu Kernel](https://hexdocs.pm/elixir/Kernel.html).

Len pre pripomenutie: je dôležité si uvedomiť, že jediné hodnoty, ktoré Elixir vyhodnotí ako `false` (v angličtine sa používa výraz *falsey*), sú hodnoty `nil` a `false`.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

Použitie `unless/2` je analogické k `if/2` - pracuje opačne, t.j. ako *if not*:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## case

Ak potrebujeme hodnotu porovnať s viacerými možnosťami (vzormi), môžeme použiť `case/2`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Špeciálna premenná `_` má v `case/2` význam *žolíka*, teda matchne čokoľvek. Používa sa podobne, ako *else* alebo *default* vetva v iných jazykoch. Bez nej nám `case/2` vyhodí chybu, ak sa mu nepodarí matchnúť hodnotu do niektorej zo svojich vetiev:

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Keďže výraz `case/2` je založený na pattern matchingu, platia preň všetky jeho pravidlá a obmedzenia. Ak chceme matchovať oproti existujúcim premenným (t.j. nepriraďovať do nich), musíme použiť operátor *pin* (`^/1`):

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Výborná vec, ktorú nám `case/2` umožňuje použiť, sú tzv. *guard clauses* (hraničné podmienky):

_Nasledujúci príklad pochádza priamo z oficiálnej príručky Elixiru [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Pozrite si príslušnú kapitolu v oficiálnej dokumentácii [Expressions allowed in guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).


## cond

Keď potrebujeme vetviť na základe podmienok, nie hodnôt, použijeme `cond/1` - funguje to podobne ako séria `else if` alebo `elsif` v iných jazykoch:

_Nasledujúci príklad pochádza priamo z oficiálnej príručky Elixiru [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "Do tejto vetvy sa nedostaneme"
...>   2 * 2 == 3 ->
...>     "Ani do tejto"
...>   1 + 1 == 2 ->
...>     "No do tejto áno"
...> end
"No do tejto áno"
```

Podobne ako `case/2` aj `cond/1` vyhodí chybu, ak nenájde použiteľnú vetvu. V tom prípade musíme vytvoriť vetvu s podmienkou `true`, ktorá takéto prípady odchytí:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

Špeciálna riadiaca štruktúra `with/1` je užitočná, keď potrebujeme použiť vnorené `case/2` výrazy alebo v situácii keď ich nemôžeme spojiť pomocou operátora pipe. Výraz `with/1` je zložený z kľúčových slov, generátorov a výrazu.

O generátoroch si povieme viac v [lekcii o comprehensions](../comprehensions/), ale zatiaľ stačí keď vieme, že používajú [pattern matching](../pattern-matching/) na porovnanie pravej strany operátora `<-` s ľavou stranou.

Začneme s jednoduchým príkladom ako použiť `with/1`:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

V prípade, že pattern matching výrazu je neúspešný, nehodiaca sa hodnota bude vrátená:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Teraz máme väčší príklad bez `with/1` a potom sa pozrieme ako ho môžeme zrefaktorovať:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Keď zavedieme `with/1`, dostaneme kód, ktorý je ľahšie pochopiteľný, čitateľný a má menej riadkov:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```

Od verzie Elixiru 1.3, `with/1` výrazy podporujú `else`:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
       true <- is_even(number) do
    IO.puts("#{number} divided by 2 is #{div(number, 2)}")
    :even
  else
    :error ->
      IO.puts("We don't have this item in map")
      :error

    _ ->
      IO.puts("It is odd")
      :odd
  end
```

To nám pomáha spracovať chyby tým, že poskytuje pattern matching podobný `case`. Vzor vo vetve `else` je prvá nehodiaca sa hodnota výrazu.
