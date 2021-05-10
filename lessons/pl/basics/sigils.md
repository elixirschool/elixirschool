%{
  version: "1.0.2",
  title: "Sigile",
  excerpt: """
  Tworzenie i praca z sigilami.
  """
}
---

## Czym są sigile

Elixir posiada specjalną składnię pozwalającą na pracę z literałami.
Sigil, bo o nim mowa, rozpoczyna się znakiem tyldy `~`, poprzedzającym pojedynczą literę.
Biblioteka standardowa Elixira dostarcza predefiniowane sigile, ale można też stworzyć własne, gdy potrzebujemy w jakiś sposób rozszerzyć możliwości języka.

Lista dostępnych sigili to:

  - `~C` Tworzy listę znaków **bez uwzględnienia** interpolacji i interpretacji znaków specjalnych.
  - `~c` Tworzy listę znaków **z uwzględnieniem** interpolacji i interpretacji znaków specjalnych.
  - `~R` Tworzy wyrażenie regularne **bez uwzględnienia** interpolacji i interpretacji znaków specjalnych.
  - `~r` Tworzy wyrażenie regularne **z uwzględnieniem** interpolacji i interpretacji znaków specjalnych.
  - `~S` Tworzy ciąg znaków **bez uwzględnienia** interpolacji i interpretacji znaków specjalnych.
  - `~s` Tworzy ciąg znaków **z uwzględnieniem** interpolacji i interpretacji znaków specjalnych.
  - `~W` Tworzy listę słów **bez uwzględnienia** interpolacji i interpretacji znaków specjalnych.
  - `~w` Tworzy listę słów **z uwzględnieniem** interpolacji i interpretacji znaków specjalnych.
  - `~N` Tworzy strukturę `NaiveDateTime`.
  - `~U` Tworzy strukturę `DateTime` (od Elixira 1.9.0).

Listę możemy utworzyć korzystając ze znaków:

  - `<...>` Nawiasy ostrokątne
  - `{...}` Nawiasy klamrowe
  - `[...]` Nawiasy kwadratowe
  - `(...)` Nawiasy okrągłe
  - `|...|` Para kresek pionowych
  - `/.../` Para ukośników prawych (ang. slash)
  - `"..."` Cudzysłów
  - `'...'` Cudzysłów pojedynczy

### Listy znaków

Za pomocą sigili `~c` i `~C` możemy utworzyć listę znaków.
Na przykład:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

Jak widać, sigil `~c`, pisany małą literą, przeprowadza obliczenia, w przeciwieństwie do `~C`, pisanego wielką literą.
Jak się później przekonamy, konwencja wyliczania bądź niewyliczania wartości przy użyciu odpowiednio małej albo wielkiej litery jest taka sama dla wszystkich sigili.

### Wyrażenia regularne

Sigile `~r` i `~R` służą do tworzenia wyrażeń regularnych.
Można też w tym celu użyć funkcji `Regex`:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

Jak widzimy pierwszy test nie powiódł się, ponieważ `Elixir` nie pasuje do wyrażenia, gdyż w tym przypadku uwzględniona była wielkość liter.
Ponieważ Elixir wspiera wyrażenia regularne kompatybilne z Perlem (PCRE – Perl Compatible Regular Expressions), możemy dodać `i` na końcu sigila by dopasowanie nie brało pod uwagę wielkości liter.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Elixir posiada też moduł [Regex](https://hexdocs.pm/elixir/Regex.html), którego API jest oparte o bibliotekę do obsługi wyrażeń regularnych z Erlanga.
Zaimplementujmy funkcję `Regex.split/2` z użyciem sigila:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

Jak widać, ciąg znaków  `"100_000_000"` został podzielony za pomocą `~r/_/`.
Funkcja `Regex.split` zwróciła listę.

### Ciągi znaków

Sigile `~s` i `~S` są używane do pracy z ciągami znaków:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```
Jaka jest między nimi różnica? Taka sama jak w przypadku list znaków, które już omawialiśmy.
Sigil pisany wielką literą wykona się na ciągu już zinterpretowanym, w którym wykonano też sekwencje ucieczki.
Przyjrzyjmy się temu na kolejnym przykładzie:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Listy słów

Sigile służące do tworzenia listy słów, `~w` i `~W`, są czasami bardzo przydatne.
Mogą oszczędzić nam mnóstwo czasu, klepania w klawiaturę oraz zredukować złożoność naszego kodu.
Na prostym przykładzie:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

Widać tu, że ciąg znaków został podzielony na słowa.
Oczywiście pomiędzy tymi dwoma wywołaniami nie ma różnicy, bo znowuż leży ona w interpolacji ciągu i użyciu znaków ucieczki, tak jak w poniższym przykładzie:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### Struktura `NaiveDateTime`

Struktura [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) jest uproszczeniem `DateTime`, które **nie posiada informacji o strefie czasowej**.

W większości wypadków nie powinniśmy tworzyć tej struktury w bezpośredni sposób, ale wyjątek stanowi tu użycie jej w dopasowaniach wzorców:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

### Struktura DateTime

[DateTime](https://hexdocs.pm/elixir/DateTime.html) możemy użyć do stworzenia struktury `DateTime` **ze strefą UTC**.
Ponieważ używana jest tu strefa czasowa UTC, a dane mogą reprezentować czas w innej strefie, trzecia zwracana wartość reprezentuje przesunięcie w sekundach.

Spójrzmy na przykłady:

```elixir
iex> DateTime.from_iso8601("2015-01-23 23:50:07Z") == {:ok, ~U[2015-01-23 23:50:07Z], 0}
iex> DateTime.from_iso8601("2015-01-23 23:50:07-0600") == {:ok, ~U[2015-01-24 05:50:07Z], -21600}
```

## Tworzenie sigili

Jednym z założeń Elixira jest możliwość łatwego rozszerzania języka.
Nie jest zatem żadną niespodzianką możliwość tworzenia własnych sigili w łatwy sposób.
Nasz przykładowy sigil będzie zmieniać ciąg znaków na wielkie litery.
Oczywiście Elixir ma odpowiednią funkcję w standardowym API (`String.upcase/1`) i nasze rozwiązanie będzie z niej korzystać.

```elixir

iex> defmodule MySigils do
...>   def sigil_p(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~p/elixir school/
ELIXIR SCHOOL
```

Najpierw zdefiniowaliśmy moduł `MySigils`, a w nim funkcję `sigil_u`.
Nie ma sigila `~p` wśród istniejących, a zatem możemy taki utworzyć.
Zapis `_p` oznacza, że w nasz sigil będzie zapisywany jako `p` poprzedzone tyldą.
Funkcja musi przyjmować dwa parametry — dane wejściowe i listę.
