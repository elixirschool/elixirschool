---
version: 0.9.1
title: Współpraca z Erlangiem
---

Jedną z zalet działania w ramach maszyny wirtualnej Erlanga jest bogactwo istniejących rozwiązań. Interoperacyjność pozwala nam na wykorzystanie tych rozwiązań, jak i standardowej biblioteki Erlanga w naszym Elixirowym kodzie. W tej lekcji przyjrzymy się, jak możemy łączyć nasz kod z bibliotekami stworzonymi w Erlangu.

{% include toc.html %}

## Biblioteka standardowa

Do kodu napisanego w Erlangu możemy odwołać się w dowolnym miejscu naszego kodu. Moduły Erlanga są reprezentowane przez atomy, pisane małymi literami, na przykład `:os` czy `:timer`.

Użyjmy `:timer.tc` by zmierzyć czas wykonania funkcji:

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

Pełna lista modułów jest dostępna w podręczniku [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/).

## Pakiety Erlanga

W jednej z poprzednich lekcji poznaliśmy narzędzie Mix służące do zarządzania zależnościami. Dodawanie zależności do bibliotek Erlangowych działa w taki sam sposób. Jedyny wyjątek stanowi to, że biblioteki Erlanga nie są opublikowane w [Hex](https://hex.pm), ale można się do nich odwołać podając nazwę repozytorium na githubie:


```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

I teraz mamy dostęp do biblioteki napisanej w erlangu:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Najważniejsze różnice 

Jak już wiemy jak korzystać z Erlanga musimy jeszcze poznać pewne pułapki wynikające z tego rozwiązania.

### Atomy

Atomy w Erlangu wyglądają bardzo podobnie do tych z Elixira. Nie zawierają dwukropka (`:`), są pisane małymi literami i można w nich użyć znaku podkreślenia:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Ciągi znaków

W Elixirze, gdy mówimy o ciągach znaków mamy na myśli dane bitowe interpretowane jako UTF-8. W Erlangu ciągi znaków też używają cudzysłowów, ale są listami znaków:

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

Musimy pamiętać, że wiele starszych bibliotek Erlanga, nie wspiera formy binarnej i musimy zamienić ciągi znaków z Elixira na listy.  Na całe szczęście mamy do tego odpowiednią funkcję `to_charlist/1`:

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

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Zmienne

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

I to wszystko! Możliwość wykorzystania Erlanga z kodu aplikacji pisanych w Elixirze jest proste i efektywnie zwiększa ilość bibliotek, które możemy wykorzystać.
