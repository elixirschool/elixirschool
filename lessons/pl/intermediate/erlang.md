%{
  version: "1.0.3",
  title: "Współpraca z Erlangiem",
  excerpt: """
  Jedną z zalet działania w ramach maszyny wirtualnej Erlanga (BEAM) jest bogactwo istniejących bibliotek, których możemy użyć.
  Interoperacyjność pozwala nam na wykorzystanie tych rozwiązań oraz standardowej biblioteki Erlanga w naszym elixirowym kodzie.
  W tej lekcji przyjrzymy się, jak możemy łączyć nasz kod z bibliotekami stworzonymi w Erlangu.
  """
}
---

## Biblioteka standardowa

Obszerna biblioteka standardowa Erlanga może być użyta w dowolnym miejscu elixirowego kodu w naszej aplikacji.
Moduły Erlanga są reprezentowane przez atomy, pisane małymi literami, na przykład `:os` czy `:timer`.

Użyjmy `:timer.tc`, by zmierzyć czas wykonania funkcji:

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

Pełna lista modułów jest dostępna w tym miejscu: [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/).

## Pakiety Erlanga

W jednej z poprzednich lekcji poznaliśmy narzędzie Mix, służące do zarządzania zależnościami.
Dodawanie zależności do bibliotek erlangowych działa w taki sam sposób.
Jedyny wyjątek stanowi to, że biblioteki Erlanga nie są opublikowane w [Hex](https://hex.pm), ale można się do nich odwołać poprzez odnośnik do repozytorium gita:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Teraz możemy użyć naszej erlangowej biblioteki:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Najważniejsze różnice 

Skoro wiemy już, jak korzystać z Erlanga, musimy jeszcze poznać pewne pułapki wynikające z tego rozwiązania.

### Atomy

Atomy w Erlangu wyglądają bardzo podobnie do tych z Elixira, jednak nie mają dwukropka z przodu (`:`).
Są pisane małymi literami i można w nich użyć znaku podkreślenia:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Ciągi znaków

Gdy mówimy o ciągach znaków w Elixirze, mamy na myśli dane bitowe interpretowane jako UTF-8.
W Erlangu ciągi znaków też używają cudzysłowów, ale są listami znaków:

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

Musimy pamiętać, że wiele starszych bibliotek Erlanga nie wspiera formy binarnej i musimy zamienić ciągi znaków z Elixira na listy.
Na szczęście mamy do tego odpowiednią funkcję `to_charlist/1`:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist() |> :string.words
2
```

### Zmienne

W Erlangu nazwy zmiennych rozpoczynają się wielką literą, a przypisywanie nowych wartości do istniejących już zmiennych nie jest dozwolone.

Elixir:

```elixir
iex> x = 10
10

iex> x = 20
20

iex> x1 = x + 10
30
```

Erlang:

```erlang
1> X = 10.
10

2> X = 20.
** exception error: no match of right hand side value 20

3> X1 = X + 10.
20
```

I to wszystko! Możliwość wykorzystania Erlanga w kodzie aplikacji pisanych w Elixirze jest proste i istotnie zwiększa liczbę bibliotek, z których możemy korzystać.
