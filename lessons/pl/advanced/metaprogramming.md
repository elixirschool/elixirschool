%{
  version: "1.0.3",
  title: "Metaprogramowanie",
  excerpt: """
  Metaprogramowanie to proces tworzenia kodu, którego zadaniem jest generowanie kodu.
  W Elixirze mamy możliwość rozszerzania języka tak, by dynamicznie generowany kod dostosowywał się do naszych bieżących potrzeb.
  Najpierw przyjrzymy się, jaka jest wewnętrzna reprezentacja kodu Elixira, następnie zobaczmy, jak można ją modyfikować, by w końcu wykorzystać zdobytą wiedzę do rozszerzania kodu za pomocą makr.

  Drobna uwaga: metaprogramowanie jest zawiłe i powinno być stosowane tylko w ostateczności.
  Nadużywane go może doprowadzić do stworzenia zbyt skomplikowanego kodu, który będzie trudny do zrozumienia i debugowania.
  """
}
---

## Reprezentacja wewnętrzna kodu

Pierwszym krokiem w metaprogramowaniu jest zrozumienie, jak reprezentowana jest składnia programu.
W Elixirze drzewo składniowe (ang. _Abstract Syntax Tree_ — AST) jest wewnętrznie reprezentowane w postaci zagnieżdżonych krotek.
Każda z nich ma trzy elementy: nazwę funkcji, metadane i argumenty.

Abyśmy mogli zobaczyć tę wewnętrzną strukturę, Elixir udostępnia funkcję `quote/2`.
Używając `quote/2` możemy zamienić kod Elixira tak, by struktura ta była dla nas zrozumiała:

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

Zauważyłeś, że pierwsze trzy wywołania nie zwróciły krotek? Istnieje pięć elementów języka, które zachowują się w ten sposób:

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # Wszystkie liczby
1
iex> [1, 2] # Listy
[1, 2]
iex> {"hello", :world} # Dwuelementowe krotki
{"hello", :world}
```

## Modyfikacja AST

Wiemy już, jak uzyskać wewnętrzną reprezentację kodu — jak możemy ją natomiast modyfikować? By wstawić do kodu nową wartość lub wyrażenie, użyjemy `unquote/1`.
Zostanie ono wyliczone, a następnie wstawione w odpowiednie miejsce AST.
Zobaczmy, jak działa `unquote/1` na poniższym przykładzie:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

W pierwszym przykładzie zmienna `denominator` jest elementem drzewa AST i została przedstawiona jako krotka opisująca odwołanie do zmiennej.
Gdy użyjemy jednak `unquote/1`, to w rezultacie zostanie wyznaczona wartość zmiennej `denominator` i to ona zostanie wyświetlona.

## Makra

Jeśli rozumiemy już `quote/2` i `unquote/1`, możemy przyjrzeć się makrom.
Ważną rzeczą do zapamiętania jest to, że makra, tak jak całe metaprogramowanie, powinny być używane oszczędnie.

Najprościej mówiąc, makro to rodzaj funkcji, która zwraca fragment AST, które może zostać wstawione do naszego kodu.
Makro zostanie przy tym zamienione na nasz kod, a nie wywołane jak zwykła funkcja.
Dysponując makrami mamy wszystkie niezbędne narzędzia, by dynamicznie dodawać kod w naszych aplikacjach.

By zdefiniować makro, użyjemy `defmacro/2`, które, jak wiele rzeczy w Elixirze, samo też jest makrem.
W naszym przykładzie zaimplementujemy `unless` jako makro.
Pamiętaj, że makro musi zwrócić fragment AST:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Zaimportujmy więc nasz moduł i pozwólmy makru działać:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

Jako że makra podmieniają kod w naszej aplikacji, to mamy wpływ na to, co i kiedy zostanie skompilowane.
Przykład tego typu zabiegów znajdziemy w module `Logger`.
Kiedy logowanie jest wyłączone, żaden kod nie zostanie dopisany i w rezultacie nasza aplikacja nie będzie miała śladu po wywołaniach loggera.
Takie zachowanie wyróżnia Elixira spośród innych języków, w których nadal istnieje narzut związany z wywołaniem funkcji, które ze względu na konfigurację nic nie robią.

By zademonstrować to zachowanie, stwórzmy prosty logger, który będzie można włączyć i wyłączyć:

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

Gdy logowanie jest włączone funkcja `test` będzie wyglądać mniej więcej w ten sposób:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

Ale jeżeli jest wyłączone to kod będzie następujący:

```elixir
def test do
end
```

## Debugowanie

Dobrze — wiemy już, jak używać `quote/2`, `unquote/1` i pisać makra.
Co jednak, jeśli mamy duży kawałek kodu rozłożonego na drzewo składniowe i chcemy go zrozumieć? W tym przypadku możemy użyć funkcji `Macro.to_string/2`.
Spójrzmy na tem przykład:

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

Kiedy natomiast chcemy zobaczyć kod generowany przez makra, możemy użyć funkcji `Macro.expand/2` i `Macro.expand_once/2`, które rozwijają makra do tworzonego przez nie kodu na podstawie drzewa składniowego.
Pierwsza z nich może rozwijać makra wiele razy, druga — tylko raz.
Dla przykładu zmodyfikujmy nasze makro `unless` z poprzedniej sekcji:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

Jeśli uruchomimy ten sam kod z funkcją `Macro.expand/2`, wynik może być nieco intrygujący:

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

Być może pamiętasz, jak wspomnieliśmy o tym, że instrukcja `if` w Elixirze także jest makrem — tutaj widzimy ją rozwiniętą do instrukcji `case`, na której opiera się jej implementacja.

### Makra prywatne

Niespotykanym w innych językach rozwiązaniem jest wspierany przez Elixira mechanizm makr prywatnych.
Makro prywatne definiujemy za pomocą `defmacrop` i można je wywołać tylko w module, w którym zostało zdefiniowane.
Prywatne makra muszą być zdefiniowane przed kodem, który je wywołuje.

### Separacja makr

Sposób, w jaki makro wchodzi w interakcję z kontekstem wywołującego, jest nazywane separacją makr.
Domyślnie Elixir odseparowuje makra od kontekstu, by nie powodowały konfliktów:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

Co, jeżeli chcielibyśmy manipulować zmienną `val` w makrze? Możemy oznaczyć naszą zmienną jako nieodseparowaną za pomocą `var!/2`.
Dodajmy do przykładu kolejne, nieodseparowane makro, używające `var!/2`:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

Porównajmy, jaki wpływ mają na nasz kontekst:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

Dodając `var!/2` możemy manipulować wartością `val` bez konieczności przekazywana jej jako parametru.
Używanie nieodseparowanych makr powinno być ograniczone do minimum.
Używając `var!/2` zwiększamy szansę na pojawienie się konfliktu nazw i zakresów wśród zmiennych.

### Spinanie

Wiemy już, jak użyteczna jest funkcja `unquote/1`, ale poza nią istnieje jeszcze inna metoda wstawiania wartości do kodu — spinanie.
Wykorzystując spinanie zmiennych, możemy używać zmiennej wiele razy w jednym makrze bez obawy, że nastąpi zmiana jej wartości.
By tego dokonać, musimy przekazać opcję `bind_quoted` do funkcji `quote/2`.

By pokazać zalety `bind_quote` oraz problem zmiany wartości zmiennej, posłużmy się przykładem.
Stwórzmy proste makro, które będzie dwukrotnie wypisywać przekazaną wartość:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

Przetestujmy je, podając aktualny czas.
W rezultacie powinniśmy zobaczyć dwie linie:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

Wartości są różne! Co się stało? Gdy użyliśmy `unquote/1` na tym samym wyrażeniu kilka razy, to pomiędzy naszymi wywołaniami wartość wyrażenia zmieniła się, co doprowadziło do nieoczekiwanego zachowania.
Poprawmy kod, używając `bind_quoted`, i zobaczmy, co się stanie:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

Kod z `bind_quoted` zadziałał zgodnie z oczekiwaniami: dwukrotnie pojawiła się taka sama wartość.

Teraz, gdy znamy `quote/2`, `unquote/1` i `defmacro/2`, mamy już wszystkie potrzebne narzędzia, by rozszerzać Elixira wedle naszych potrzeb.
