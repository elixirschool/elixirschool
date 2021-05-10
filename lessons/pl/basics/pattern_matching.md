%{
  version: "1.0.2",
  title: "Dopasowanie wzorców",
  excerpt: """
  Dopasowanie wzorców, to jeden z najmocniejszych elementów Elixira, który pozwala dopasować wartości, struktury danych, a nawet funkcje.
Tę lekcję rozpoczniemy od przyjrzenia się jak używać tego mechanizmu.
  """
}
---

## Operator dopasowania

Gotowi na niespodziankę? W Elixirze operator `=` to w rzeczywistości operator dopasowania, który można porównać do znaku równości w algebrze. Wykorzystanie go w zapisie powoduje, że wyrażenie zostanie potraktowane jak równanie. Elixir przypisze wartości po lewej stronie wartość po prawej. Jeżeli przypisanie się powiedzie, to zostanie zwrócony jego wynik. W przeciwnym przypadku zostanie zwrócony błąd. Spójrzmy:

```elixir
iex> x = 1
1
```

Spróbujmy zatem coś dopasować:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

A teraz spróbujmy tego samego ze znanymi nam już kolekcjami:

```elixir
# Listy
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Krotki
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Operator przypięcia

Jak już wiemy, operator dopasowania pozwala na przypisanie, jeżeli lewa strona wyrażenia zawiera zmienną.
W niektórych przypadkach takie zachowanie jest niepożądane.
Do ich obsługi wykorzystujemy operator przypięcia: `^`.

Kiedy przypinamy zmienną, to dopasowujemy ją do istniejącej wartości, a nie tworzymy nową.
Zobaczmy, jak to działa:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2 wprowadził możliwość użycia przypięć w kluczach map i funkcjach:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Przykładowe przypięcie w funkcji:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
iex> greeting
"Hello"
```

W przykładzie z `"Mornin'"` zauważ, że zmiana przypisania `greeting` na `"Mornin'"` następuje jedynie wewnątrz funkcji. Poza nią `greeting` nadal ma wartość `"Hello"`.