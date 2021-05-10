%{
  version: "0.9.0",
  title: "Składanie kolekcji",
  excerpt: """
  Składanie list (ang. list comprehensions), to lukier składniowy pozwalający na wygodniejszą pracę z kolekcjami i danymi przeliczalnymi. W tej lekcji przyjrzymy się jak mechanizm ten, ułatwia przetwarzanie oraz tworzenie kolekcji na bazie już istniejących.
  """
}
---

## Podstawy

Najczęściej składanie list używane jest do tworzenia bardziej zwięzłego kodu z wykorzystaniem `Enum` oraz `Stream`. Przyjrzyjmy się prostemu porównaniu, a następnie omówmy jego elementy:

```elixir
iex> list = [1, 2, 3, 4, 5]
iex> for x <- list, do: x*x
[1, 4, 9, 16, 25]
```

Pierwsze co widać to użycie słowa kluczowego `for` i generatora. Czym jest generator?  Generatorem nazywamy wyrażenie `x <- [1, 2, 3, 4]` znajdujące się w liście składanej. Odpowiada ono za dostarczenie kolejnych wartości.

Oczywiście składania można stosować nie tylko do list, ale do wszystkich kolekcji i danych binarnych:

```elixir
# Listy asocjacyjne
iex> for {_key, val} <- [one: 1, two: 2, three: 3], do: val
[1, 2, 3]

# Mapy
iex> for {k, v} <- %{"a" => "A", "b" => "B"}, do: {k, v}
[{"a", "A"}, {"b", "B"}]

# Dane binarne
iex> for <<c <- "hello">>, do: <<c>>
["h", "e", "l", "l", "o"]
```

Jak zapewne zauważyłeś, generatory opierają się o dopasowanie wzorców, by przypisać dane do zmiennej po lewej stronie. Jeżeli jakiś element nie zostanie dopasowany, to jest po prostu ignorowany:

```elixir
iex> for {:ok, val} <- [ok: "Hello", error: "Unknown", ok: "World"], 
...> do: val
["Hello", "World"]
```

Możliwe jest użycie wielu generatorów naraz, co trochę przypomina zagnieżdżanie pętli:

```elixir
iex> list = [1, 2, 3, 4]
iex> for n <- list, times <- 1..n do
...>   String.duplicate("*", times)
...> end
["*", "*", "**", "*", "**", "***", "*", "**", "***", "****"]
```

By lepiej zilustrować to zachowanie, użyjmy `IO.puts` by wyświetlić wartości z dwóch generatorów:

```elixir
iex> for n <- list, times <- 1..n, do: IO.puts "#{n} - #{times}"
1 - 1
2 - 1
2 - 2
3 - 1
3 - 2
3 - 3
4 - 1
4 - 2
4 - 3
4 - 4
```

Składanie list, to tzw. lukier składniowy i powinno być stosowane tylko w razie potrzeby.

## Filtrowanie

O filtrowaniu możemy myśleć jak o strażnikach dla odwzorowania. Gdy filtr zwraca wartość `false` lub `nil` to wartość ta jest wyłączana z przetwarzania przez odwzorowanie. Przefiltrujmy pewien zakres liczb tak, by uzyskać tylko liczby  parzyste:

```elixir
iex> for x <- 1..10, is_even(x), do: x
[2, 4, 6, 8, 10]
```

Filtry, podobnie jak generatory, możemy łączyć. Przefiltrujmy liczby tak, by uzyskać tylko te, które są parzyste i podzielne przez trzy:

```elixir
iex> for x <- 1..100,
...>   is_even(x),
...>   rem(x, 3) == 0, do: x
[6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96]
```

## Użycie `:into`

A co jeżeli chcemy otrzymać coś innego niż listę?  W tym celu służy`:into`! Ogólna zasada jest taka, że `:into` akceptuje jako argument dowolną strukturę implementującą protokół `Collectable`.

Przykład użycia `:into`, by stworzyć mapę z listy asocjacyjnej:

```elixir
iex> for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
%{one: 1, three: 3, two: 2}
```

Jako że binarne ciągi znaków są przeliczalne, możemy zatem użyć składania w połączeniu z `:into` by stworzyć ciąg 
znaków:

```elixir
iex> for c <- [72, 101, 108, 108, 111], into: "", do: <<c>>
"Hello"
```

I to wszystko! Składania są mechanizmem pozwalającym na tworzenie zwięzłego kodu do obsługi kolekcji.  
