%{
  version: "1.2.0",
  title: "Ciągi znaków",
  excerpt: """
  Czym są ciągi znaków w Elixirze, listy znaków, grafemy i jak wygląda obsługa kodowania znaków.
  """
}
---

## Ciągi znaków

W Elixirze ciąg znaków to nic innego jak sekwencja bajtów, przykładowo:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

Łącząc ciąg z bajtem `0`, IEx wyświetla ciąg jako binarny, ponieważ nie jest już prawidłowym ciągiem znaków.
Ta sztuczka może pomóc nam zobaczyć bajty dowolnego ciągu.

>Uwaga: używając składni `<< >>` wskazujemy kompilatorowi, że elementy wewnątrz tych symboli są bajtami.

## Listy znaków

Wewnętrznie Elixir przechowuje ciągi znaków jako sekwencję bajtów, a nie tablicę znaków.
Język posiada jednak osobny typ do reprezentowania listy znaków.
Różnica polega na tym, że ciągi znaków tworzymy z użyciem podwójnego cudzysłowu `"`, a listy za pomocą pojedynczego `'`.

Jaka jest różnica pomiędzy nimi?
Każdy element na liście znaków jest punktem kodu Unicode znaku, podczas gdy w pliku binarnym punkty kodowe są zakodowane jako UTF-8.

```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` to punkt kodowy Unicode dla ł, ale jest zakodowany w UTF-8 jako dwa bajty `197`, `130`.

Możesz uzyskać punkt kodowy znaku, używając `?`

```elixir
iex> ?Z
90
```

Pozwala to na użycie notacji `?Z` zamiast 'Z' dla symbolu.

Podczas programowania w Elixirze zwykle używamy ciągów znaków, a nie list znaków.
Obsługa list znaków jest zawarta głównie dlatego, że jest wymagana dla niektórych modułów Erlanga.

Więcej informacji można znaleźć w oficjalnym [`Getting Started Guide`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## Grafemy i kodowanie

Znaki kodowe to zwyczajne znaki Unicode, które mogą być reprezentowane przez jeden albo więcej bajtów, w zależności od tego w której części tabeli UTF-8 się znajdują.
Znaki spoza zakresu US ASCII zawsze będą kodowane jako więcej niż jeden bajt.
Na przykład znaki łacińskie z tyldą lub akcentami: `á, ñ, è` są zazwyczaj zapisywane na dwóch bajtach.
Znaki z języków azjatyckich są najczęściej zapisywane na trzech albo czterech bajtach.
Grafemy zwierają jeden lub wiele znaków kodowych, które będą reprezentować pojedynczy znak (literę).

Moduł String zawiera dwie metody do ich obsługi, `graphemes/1` i `codepoints/1`.
Spójrzmy na przykład:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## Popularne funkcje z modułu String

Przyjrzyjmy się niektórym z najważniejszych i najbardziej przydatnych funkcji modułu String.
W tej lekcji omówimy tylko podzbiór dostępnych funkcji.
Aby zobaczyć pełny zestaw funkcji, odwiedź oficjalną dokumentację [`String`](https://hexdocs.pm/elixir/String.html).

### length/1

Zwraca liczbę grafemów w ciągu znaków.

```elixir
iex> String.length "Hello"
5
```

### replace/3

Zwraca nowy ciąg, w którym zmieniono fragmenty pasujące do wzorca na podane w parametrze.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### duplicate/2

Tworzy nowy ciąg znaków będący n-krotnym powtórzeniem zadanego.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### split/2

Zwraca listę ciągów znaków, będącą wynikiem podziału ciągu według podanego wzorca.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Ćwiczenia

Przejdźmy przez proste ćwiczenie, aby pokazać, że jesteśmy gotowi do pracy z ciągami znaków!

### Anagramy

Słowa A i B są anagramami, jeżeli zmieniając kolejność liter w jednym z nich, otrzymamy drugie:

+ A = Wiek
+ B = Weki

Jak można w Elixirze sprawdzić, czy słowa są anagramami?

Najprostszym rozwiązaniem jest po prostu posortowanie grafemów każdego ciągu alfabetycznie, a następnie sprawdzenie, czy obie listy są równe.
Przykładowo:

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

Przyjrzyjmy się najpierw funkcji `anagrams?/2`.
Na początek sprawdzamy, czy parametry są binarne, czy też nie.
W Elixirze jest to sposób na weryfikację czy parametr jest ciągiem znaków, czy też nie.

Następnie wywołujemy funkcję, która porządkuje ciąg alfabetycznie.
Najpierw konwertuje ciąg na małe litery, a następnie korzystając z `String.graphemes`, stworzy listę grafemów, która zostanie posortowana.
Proste, prawda?

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

Ostatnie wywołanie `anagrams?` spowodowało wystąpienie `FunctionClauseError`.
Błąd ten mówi nam, że w naszym module nie ma funkcji, która spełniałaby wzorzec otrzymywania dwóch niebinarnych argumentów.
I oto nam chodzi, by naszą funkcję móc wywołać tylko z ciągami znaków.
