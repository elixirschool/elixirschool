%{
  version: "1.1.1",
  title: "Struktury sterujące",
  excerpt: """
  W tej lekcji przyjrzymy się strukturom sterującym dostępnym w Elixirze.
  """
}
---

## if i unless

Zapewne spotkałeś się już z `if/2` w innych językach, a jeżeli znasz język Ruby, to również `unless/2` zapewne nie będzie Ci obce.
W Elixirze instrukcje te działają w podobny sposób, ale nie są elementami języka, a makrami. Ich implementacje możesz znaleźć w dokumentacji [modułu jądra](https://hexdocs.pm/elixir/Kernel.html).

Przypomnijmy, że w Elixirze jedynymi wartościami traktowanymi jako _fałsz_ są `nil` i wartość logiczna `false`.

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

Użycie `unless/2` jest podobne do `if/2`, tylko że warunek działa na odwrót:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## case

Jeżeli chcemy sprawdzić wiele różnych wzorców, to możemy użyć `case/2`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Zmienna `_` jest istotnym elementem wyrażenia `case/2`. Bez niej, jeżeli nie będzie istnieć dopasowanie, program zwróci błąd:

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

Konstrukcję `_` możesz rozumieć jako `else` – dopasowuje bowiem „wszystko inne”.

Jako że `case/2` wykorzystuje dopasowanie wzorców, wszystkie zasady tam obowiązujące są zachowane.
Jeżeli chcesz dopasować istniejącą zmienną, musisz użyć operatora przypięcia `^`:

```elixir
iex> pie = 3.14 
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Kolejną właściwością `case` jest wsparcie dla wyrażeń strażników:

_Ten przykład pochodzi z oficjalnego przewodnika po języku Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Więcej szczegółów znajdziesz w dokumentacji w języku angielskim, w module [Expressions allowed in guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## cond

Jeżeli chcemy sprawdzić warunki niebędące wartościami, możemy użyć `cond/1`; wyrażenie to odpowiada konstrukcjom `else if` czy `elsif` z innych języków:

_Ten przykład pochodzi z oficjalnego przewodnika po języku Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

Podobnie jak `case`, `cond` zwróci błąd, jeżeli żadne z wyrażeń nie będzie spełnione. By obsłużyć taką sytuację, możemy jako warunek podać `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

Konstrukcji `with/1` możemy użyć zamiast wielu zagnieżdżonych wyrażeń `case/2` lub w sytuacjach, gdy nie mogą być one powiązane w jednoznaczny sposób. Wyrażenie `with/1` składa się ze słowa kluczowego, generatora i wyrażenia.

Zajmiemy się jeszcze generatorami przy okazji omawiania [list składanych](../comprehensions/), ale na chwilę obecną jedyne, co musimy wiedzieć, to że używają [dopasowania wzorców](../pattern-matching/), by połączyć elementy po prawej stronie `<-` z tymi po lewej.

Zacznijmy od prostego wyrażenia `with/1`:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

W przypadku, kiedy żadne z wyrażeń nie zostanie dopasowane, zostanie zwrócona niepasująca wartość:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Teraz przyjrzyjmy się większemu przykładowi bez `with/1`, a następnie zrefaktoryzujmy go:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Dzięki wprowadzeniu `with/1` nasz końcowy kod jest krótszy i łatwiejszy do zrozumienia:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```

Elixir od wersji 1.3 pozwala też na użycie `else` w wyrażeniach `with/1`:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
    true <- is_even(number) do
      IO.puts "#{number} divided by 2 is #{div(number, 2)}"
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

Pozwala to na łatwiejszą obsługę błędów, która jest podobna do wyrażenia `case`.
Przekazywana wartość to pierwsze niedopasowane wyrażenie.
