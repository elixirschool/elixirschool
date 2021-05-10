%{
  version: "1.1.1",
  title: "Управляющие конструкции",
  excerpt: """
  В этом уроке мы рассмотрим доступные в языке Elixir управляющие конструкции.
  """
}
---

## if и unless

Скорее всего, вы уже встречали оператор `if/2`, а если использовали Ruby, то встречали и `unless/2`. В Elixir они функционируют также, но определены как макрос, а не конструкция языка. Код реализации можно увидеть в модуле [Kernel](https://hexdocs.pm/elixir/Kernel.html).

Стоит заметить что в Elixir единственными ложными значениями являются `nil` и `false`.

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

`unless/2` похож на `if/2`, но работает наоборот:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## case

Если нужно сопоставить с несколькими образцами, используется оператор `case/2`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Переменная `_` является важной частью конструкции `case/2`. Без неё в случае отсутствия найденного сопоставления произойдёт ошибка:

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

Можно рассматривать `_` как `else`, который будет сопоставлен с чем угодно.
Так как `case/2` основывается на сопоставлении с образцом, то все те же ограничения и особенности продолжают работать. Если нужно сопоставлять со значением переменной вместо её присвоения, используется уже знакомый оператор `^/1`:

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Другой интересной возможностью `case/2` является поддержка ограничивающих выражений:

_Этот пример взят из официальной документации [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Также советуем почитать официальную документацию про [выражения, доступные в ограничивающих выражениях](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## cond

Когда нужно проверять условия, а не значения, можно использовать `cond/1`. Это похоже на `else if` или `elsif` в других языках:

_Этот пример взят из официальной документации [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

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

Также как и `case/2`, `cond/1` вызовет ошибку, если не пройдёт ни одно из выражений. Для решения этой проблемы можно определить условие в `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

Специальная форма `with/1` может пригодиться в ситуациях, когда сложно использовать оператор потока, либо когда нужен вложенный вызов `case/2`. `with/1` состоит из ключевых слов, генераторов и выражения в конце.

Мы ещё обсудим генераторы в [уроке о списковых включениях](../comprehensions/), но сейчас нам достаточно знать лишь то, что они используют [сопоставление с образцом](../pattern-matching/) для сравнения правой части `<-` с левой.

Начнём с простого примера с `with/1`:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

В случае, если для выражения не найдётся совпадение, вернётся несовпадающее значение:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Давайте взглянем на пример побольше без использования `with/1`, а затем узнаем, как мы могли бы его улучшить:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

А теперь благодаря `with/1` мы в итоге получим короткий и простой для понимания код:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```

Начиная с версии Elixir 1.3, конструкция `with/1` также начала поддерживать `else`:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
       true <- is_even(number) do
    IO.puts("#{number} divided by 2 is #{div(number, 2)}")
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

Это помогает структурировать код обработки ошибок с помощью сопоставления с образцом в общем блоке-обработчике. Значение, которое туда передаётся &mdash; первое же выражение, которое не сопоставилось в основном теле `with`.
