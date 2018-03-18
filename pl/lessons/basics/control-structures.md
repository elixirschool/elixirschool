---
version: 1.0.2
title: Struktury sterujące
---

W tej lekcji przyjrzymy się strukturom sterującym dostępnym w Elixirze.

{% include toc.html %}

## `if` i `unless`

Zapewne spotkałeś się już z `if/2` w innych językach, a jeżeli znasz Ruby to `unless/2` nie będzie ci obca.  W Elixirze działają w podobny sposób, ale nie są elementem języka, a makrami; Ich implementacje znajdziesz w dokumentacji [modułu jądra](https://hexdocs.pm/elixir/Kernel.html).

Przypomnijmy, że w Elixirze, jedynymi wartościami fałszywymi są `nil` i wartość logiczna `false`.

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

Użycie `unless/2` jest takie samo jak `if/2` tylko, że warunek działa w przeciwnym kierunku:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Jeżeli chcemy sprawdzić wiele różnych wzorców, to możemy użyć `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Zmienna `_` jest niezbędnym elementem wyrażenia `case`. Bez niej, jeżeli nie będzie istnieć dopasowanie, program zwróci błąd:

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

Konstrukcja `_` działa tak samo, jak `else`, czyli dopasuje "wszystko inne".

Jako że `case` wykorzystuje dopasowanie wzorców, wszystkie zasady tam obowiązujące są zachowane.  Jeżeli chcesz dopasować istniejącą zmienną, to musisz użyć operatora `^`:

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

Więcej szczegółów znajdziesz w dokumentacji, w języku angielskim, [Expressions allowed in guard clauses](http://elixir-lang.org/getting-started/case-cond-and-if.html#expressions-in-guard-clauses).

## `cond`

Jeżeli chcemy sprawdzić wiele warunków, ale nie są to wartości, to należy użyć `cond`; odpowiada on konstrukcjom `else if` czy `elsif` z innych języków:

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

## `with`

Konstrukcja `with` jest to forma, którą możemy użyć zamiast zagnieżdżonych wyrażeń `case` albo w sytuacji, gdy nie mogą być one powiązane w jednoznaczny sposób. Wyrażenie `with` składa się ze słowa kluczowego, generatora i wyrażenia.

Zajmiemy się jeszcze generatorami przy okazji omawiania list składanych, a na chwilę obecną jedyne co musimy wiedzieć to, że używają dopasowania wzorców, by połączyć elementy po prawej stronie `<-` z tymi po lewej.

Zacznijmy od prostego wyrażenia `with`:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

W przypadku gdy żadne z wyrażeń nie zostanie dopasowane, otrzymamy błąd:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Teraz przyjrzyjmy się większemu przykładowi bez `with`, a następnie zrefaktoryzujmy go:

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

Dzięki wprowadzeniu `with` nasz końcowy kod jest krótszy i łatwiejszy do zrozumienia:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token, claims),
     do: important_stuff(jwt, full_claims)
```

Elixir od wersji 1.3 pozwala też na użycie `else` w wyrażeniu `with`:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, res} <- Map.fetch(m, :a),
       true <- is_even(res) do
    IO.puts("Divided by 2 it is #{div(res, 2)}")
  else
    :error -> IO.puts("We don't have this item in map")
    _ -> IO.puts("It's not odd")
  end
```

Pozwala to na łatwiejszą obsługę błędów, która jest podobna do wyrażenia `case`. Przekazywana wartość to pierwsze niedopasowane wyrażenie.
