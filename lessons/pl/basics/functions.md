%{
  version: "1.2.0",
  title: "Funkcje",
  excerpt: """
  W Elixirze i w wielu innych językach funkcyjnych, funkcje są konceptem absolutnie podstawowym.
W tej lekcji poznamy rodzaje funkcji, różnice pomiędzy nimi oraz ich zastosowania.
  """
}
---

## Funkcje anonimowe

Jak sama nazwa wskazuje, funkcje anonimowe nie mają nazw.
W lekcji `Enum` zobaczyliśmy, że funkcje często są przekazywane do innych funkcji jako parametry.
Jeżeli chcemy zdefiniować funkcję anonimową w Elixirze, musimy użyć słów kluczowych `fn` i `end`.
Funkcja taka może posiadać wiele parametrów, które są oddzielone od jej ciała za pomocą symbolu `->`.

Przyjrzyjmy się prostemu przykładowi:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Znak & jako skrót

Funkcje anonimowe są tak często wykorzystywane, że istnieje skrócony sposób ich zapisu:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Jak można się domyślić, w skróconej formie zapisu argumenty funkcji są dostępne jako `&1`,`&2`, `&3`, itd.

## Dopasowanie wzorców

Dopasowanie wzorców w Elixirze nie jest ograniczone tylko do zmiennych – jak przekonamy się w tej sekcji, może ono zostać wykorzystane do dopasowania funkcji na podstawie listy ich parametrów.

Elixir używa dopasowania wzorców, by odnaleźć pierwszy pasujący zestaw parametrów i wykonać połączony z nim kod:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Obsługa wyniku..."
...>   {:ok, _} -> IO.puts "To nie zostanie nigdy wykonane, gdyż poprzedni wzorzec zawsze będzie dopasowany jako pierwszy."
...>   {:error} -> IO.puts "Wystąpił błąd!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## Funkcje nazwane

Możemy zdefiniować funkcję i nadać jej nazwę, by móc się do niej później odwołać.
Robimy to w ramach modułu, wykorzystując słowo kluczowe `def`.
O modułach będziemy jeszcze mówić w kolejnych lekcjach, teraz skupimy się na samych funkcjach.

Funkcje zdefiniowane w module są też domyślnie dostępne w innych modułach.
Jest to szczególnie użyteczny element konstrukcyjny w Elixirze:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Możemy też zapisać funkcję w jednej linijce, wykorzystując wyrażenie `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Wykorzystując naszą wiedzę o dopasowaniu wzorców, stwórzmy funkcję rekurencyjną:

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

### Nazywanie i arność funkcji

Jak już wspominaliśmy wcześniej, pełna nazwa funkcji jest kombinacją jej nazwy i arności (liczby argumentów).
Można to rozumieć w następujący sposób:

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

Wypisaliśmy pełne nazwy funkcji w komentarzach powyżej.
Pierwsza z nich nie przyjmuje żadnego argumentu, zatem jest nazwana `hello/0`; druga przyjmuje jeden argument, zatem nazwa to `hello/1` i tak dalej.
Nie należy mylić tego z przeciążaniem funkcji w innych językach, każda z tych funkcji jest _niezależna_ od innych.
(Dopasowanie wzorców, o którym przed chwilą mówiliśmy, zostanie zastosowane jedynie wtedy, gdy mamy wiele definicji funkcji o takich samych nazwach i liczbie argumentów).

### Funkcje i dopasowanie wzorców

Za kulisami funkcje dopasowują wzorce do argumentów, z którymi są wywoływane.

Powiedzmy, że potrzebujemy funkcji, która akceptuje mapę jako argument, ale interesuje nas użycie jedynie konkretnego klucza.
Możemy wykorzystać dopasowanie wzorców do sprawdzenia, czy dany klucz występuje w mapie przekazanej jako argument, jak pokazano w poniższym przykładzie:

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

Powiedzmy teraz, że mamy mapę opisującą osobę o imieniu Fred:

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

Wyniki, które uzyskamy wywołując funkcję `Greeter1.hello/1` z mapą `fred` jako argumentem, są następujące:

```elixir
# wywołanie z całą mapą jako argumentem
...> Greeter1.hello(fred)
"Hello, Fred"
```

Co dzieje się w sytuacji, gdy mapa _nie_ zawiera klucza `:name`?

```elixir
# wywołanie bez klucza, którego potrzebujemy, zwraca błąd
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

Przyczyną takiego zachowania jest to, że Elixir dopasowuje argumenty, z którymi funkcja jest wywoływana, do arności funkcji zgodnie z jej definicją.

Zastanówmy się jak wyglądają dane, kiedy docierają do funkcji `Greeter1.hello/1`:

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

`Greeter1.hello/1` oczekuje argumentu takiego jak ten:

```elixir
%{name: person_name}
```

W `Greeter1.hello/1`, przekazywana przez nas mapa (`fred`) jest porównywana z naszym argumentem (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Porównanie wykazuje, że w przekazanej mapie występuje klucz odpowiadający `name`.
Mamy dopasowanie! Zatem w wyniku pomyślnego dopasowania, wartość odpowiadająca kluczowi `:name` po prawej stronie (tj. w mapie `fred`) jest wiązana ze zmienną po lewej (`person_name`).

Co jednak, gdybyśmy dalej chcieli dopasować imię Freda do `person_name` ORAZ zachować całą mapę? Powiedzmy, że chcemy użyć polecenia `IO.inspect(fred)` po tym, jak przywitamy się z Fredem.
W tym momencie, ponieważ dopasowaliśmy jedynie klucz `:name` z naszej mapy, a więc jedynie ta wartość przypisana jest do jakiejkolwiek zmiennej, funkcja nie ma żadnych innych informacji na temat Freda.

Aby zachować te informacje, musimy przypisać całą mapę do oddzielnej zmiennej, której będziemy mogli użyć.

Zacznijmy z nową funkcją:

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Pamiętajmy, że Elixir dopasuje wzorzec do argumentu, gdy taki się pojawi.
W tym przypadku każda strona będzie dopasowywana do przekazanego argumentu i przypisana do wszystkiego, do czego będzie pasować.
Rozważmy najpierw prawą stronę:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Tu widzimy, że zmienna `person` została porównana i powiązana z całą mapą `fred`.
Spójrzmy na kolejne dopasowanie wzorców:

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Tu działa to tak samo jak w naszej pierwotnej funkcji w `Greeter1`, gdzie z dopasowanej mapy zachowaliśmy jedynie imię Freda.
To, co uzyskaliśmy, to — zamiast jednej — dwie zmienne, których możemy użyć:

1. `person`, odnosząca się do wartości `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name`, odnosząca się do wartości `"Fred"`.

Teraz więc, kiedy wywołujemy funkcję `Greeter2.hello/1`, możemy użyć wszystkich informacji na temat Freda:

```elixir
# wywołanie z pełną mapą
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# wywołanie jedynie z kluczem dla imienia (name)
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# wywołanie bez klucza dla imienia (name)
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

Zobaczyliśmy zatem, że Elixir dopasowuje wzorce na wielu poziomach, ponieważ każdy argument jest porównywany z przekazywanymi danymi niezależnie, co daje nam zmienne, których możemy użyć w naszej funkcji.

Jeśli zamienimy kolejność `%{name: person_name}` i `person`, uzyskamy dokładnie taki sam wynik, ponieważ każde z powyższych zostanie niezależnie porównane z mapą `fred`.

Zamieńmy więc miejscami zmienną i mapę:

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Wywołajmy funkcję z tymi samymi danymi, co w przypadku `Greeter2.hello/1`:

```elixir
# wywołanie z tym samym, starym Fredem
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Pamiętaj, że choć wygląda jakby `%{name: person_name} = person` było próbą dopasowania `%{name: person_name}` i zmiennej `person`, tak naprawdę _każdy_ z tych elementów dopasowywany jest do przekazanego argumentu.

**Podsumowanie:** Funkcje dopasowują przekazane dane do każdego z argumentów niezależnie.
Możemy tego użyć do powiązania wartości z oddzielnymi zmiennymi w funkcji.

### Funkcje prywatne

Jeżeli nie chcemy, by inne moduły mogły wywołać naszą funkcję, możemy zdefiniować ją jako prywatną.
Będzie można jej użyć tylko w module, w którym została stworzona.
W Elixirze służy do tego słowo kluczowe `defp`:

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

### Strażnicy

Pokrótce omówiliśmy strażników w lekcji o [strukturach kontrolnych](../control-structures), a teraz przyjrzymy się bliżej, jak można wykorzystać ich w funkcjach.
Elixir, odszukując funkcję do wywołania, sprawdza warunki dla wszystkich strażników.

W poniższym przykładzie mamy dwie funkcje o takiej samej sygnaturze, ale wywołanie właściwej jest możliwe dzięki strażnikom sprawdzającym typ argumentu:

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

### Argumenty domyślne

Jeżeli chcemy, by argument miał wartość domyślną, to należy użyć konstrukcji `argument \\ wartość`:

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

Należy uważać, kiedy łączymy mechanizmy strażników i domyślnych argumentów, ponieważ może to spowodować wystąpienie błędów.
Zobaczmy jak może to wyglądać:

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

Domyślne argumenty nie są preferowane przez Elixira w mechanizmach dopasowania wzorców, ponieważ mogą być mylące.
By temu zaradzić, możemy dodać nagłówek funkcji z naszymi argumentami domyślnymi:

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
