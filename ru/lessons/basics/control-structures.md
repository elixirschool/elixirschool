---
layout: page
title: Управляющие конструкции
category: basics
order: 5
lang: ru
---

В этом уроке мы рассмотрим доступные в языке Elixir управляющие конструкции.

{% include toc.html %}

## `if` и `unless`

Скорее всего, вы уже встречали оператор `if/2`, а если использовали Ruby, то встречали и `unless/2`. В Elixir они функционируют также, но определены как макрос, а не конструкция языка. Код реализации можно увидеть в модуле [Kernel](http://elixir-lang.org/docs/stable/elixir/#!Kernel.html).

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

## `case`

Если нужно сопоставить с несколькими образцами, используется оператор `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Переменная `_` является важной частью конструкции `case`. Без неё в случае отсутствия найденного сопоставления произойдёт ошибка:

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
Так как `case` основывается на сопоставлении с образцом, то все те же ограничения и особенности продолжают работать. Если нужно сопоставлять со значением переменной вместо ее присвоения, используется уже знакомый оператор `^`:

```elixir
iex> pie = 3.14 
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Другой интересной возможностью `case` является поддержка ограничивающих выражений:

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

Также советуем почитать официальную документацию про [выражения, доступные в ограничивающих выражениях](http://elixir-lang.org/getting-started/case-cond-and-if.html#expressions-in-guard-clauses).

## `cond`

Когда нужно проверять условия, а не значения, можно использовать `cond`. Это похоже на `else if` или `elsif` в других языках:

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

Также как и `case`, `cond` вызовет ошибку, если не пройдёт ни одно из выражений. Для решения этой проблемы можно определить условие в `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

Специальная форма `with` может пригодиться в ситуациях, когда сложно использовать оператор потока, либо когда нужен вложенный вызов `case`. `with` состоит из ключевого слова, генераторов и выражения в конце.

Мы ещё обсудим генераторы в уроке о списковых включениях (list comprehensions), но сейчас нам достаточно знать лишь то, что они используют сопоставление с образцом для сравнения правой части `<-` с левой.

Начнём с простого примера с `with`:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

В случае, если для выражения не найдётся совпадение, вернётся несовпавшее значение:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Давайте взглянем на пример побольше без использования `with`, а затем узнаем, как мы могли бы его улучшить:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(resource, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)
      error -> error
    end
  error -> error
end
```

А теперь благодаря `with` мы в итоге получим короткий и простой для понимания код:

```elixir
with
  {:ok, user} <- Repo.insert(changeset),
  {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token),
  do: important_stuff(jwt, full_claims)
```
