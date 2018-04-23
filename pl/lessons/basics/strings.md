---
version: 0.9.1
title: Ciągi znaków
---

Czym są ciągi znaków w Elixirze, listy znaków, grafemy i jak wygląda obsługa kodowania znaków.

{% include toc.html %}

## Ciągi znaków

W Elixirze ciąg znaków to nic innego jak sekwencja bajtów, przykładowo:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
```

>Uwaga: używając `<< >>` określamy, iż liczby w środku kompilator powinien traktować jak bajty.

## Listy znaków

Wewnętrznie Elixir przechowuje ciągi znaków jako sekwencja bajtów, a nie tablice znaków, posiada jednak osobny typ do reprezentowania listy znaków. Różnica polega na tym, że ciągi znaków tworzymy z użyciem podwójnego cudzysłowu `"`, a  listy za pomocą pojedynczego `'`.

Jaka jest różnica pomiędzy nimi? Każdy element na liście znaków to pojedynczy znak ASCII, popatrzmy:

```elixir
iex> char_list = 'hello'
'hello'

iex> [hd|tl] = char_list
'hello'

iex> {hd, tl}
{104, 'ello'}

iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

Listy znaków istnieją w Elixirze, ponieważ są wymagane przez niektóre moduły Erlanga. Na co dzień korzysta się z ciągów znaków.

## Grafemy i kodowanie

Znaki kodowe to zwyczajne znaki Unicode, które mogą być reprezentowane przez jeden albo więcej bajtów, w zależności od tego w której części tabeli UTF-8 się znajdują. Znaki spoza zakresu US ASCII zawsze są zapisywane na co najmniej dwóch bajtach. Na przykład znaki z akcentem albo tyldą: `á, ñ, è` są zazwyczaj zapisywane na dwóch bajtach. Znaki z języków azjatyckich są najczęściej zapisywane na trzech albo czterech bajtach. Grafemy zwierają jeden lub wiele znaków kodowych, które będą reprezentować pojedynczy znak (literę).

Moduł `String` ma dwie metody do ich obsługi, `graphemes/1` i `codepoints/1`. Przyjrzyjmy się na przykładzie:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Popularne funkcje

Przyjrzyjmy się teraz kilku popularnym i ważnym funkcjom z modułu `String`.

### `length/1`

Zwraca liczbę grafemów w ciągu znaków.

```elixir
iex> String.length "Hello"
5
```

### `replace/3`

Zwraca nowy ciąg, w którym zmieniono fragmenty pasujące do wzorca na podane w parametrze. Czwarty parametr jest opcjonalny.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

Tworzy nowy ciąg znaków będący n-krotnym powtórzeniem zadanego.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

Zwraca listę ciągów znaków, będącą wynikiem podziału ciągu według podanego wzorca. 

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Ćwiczenia

Czas na dwa proste ćwiczenia by utrwalić naszą wiedzę o ciągach znaków i module `String`!

### Anagramy

Słowa A i B są anagramami jeżeli zmieniając kolejność liter w jednym z nich otrzymamy drugie: 

A = Wiek
B = Weki 

Jak można w Elixirze sprawdzić czy słowa są anagramami?

Najprościej jest posortować litery alfabetycznie i sprawdzić czy takie listy są sobie równe. Przykładowo:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Przyjrzyjmy się najpierw funkcji `anagrams?/2`. Na początek sprawdzamy, czy parametry są binarne, czy też nie. W Elixirze jest to sposób na weryfikację czy parametr jest ciągiem znaków, czy też nie. 

Następnie wywołujemy funkcję, która posortuje litery alfabetycznie. Najpierw zamieni wszystkie znaki na małe, a następnie korzystając z `String.graphemes`, stworzy listę znaków, która zostanie posortowana. Proste, prawda?

Sprawdźmy wyniki w konsoli `iex`:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

Ostatnie wywołanie `anagrams?` spowodowało `FunctionClauseError`. Błąd ten mówi, że nie można znaleźć dopasowania funkcji, która mogłaby zostać wywołana z niebinarnymi argumentami. I oto nam chodzi, by naszą funkcję móc wywołać tylko z ciągami znaków. 
