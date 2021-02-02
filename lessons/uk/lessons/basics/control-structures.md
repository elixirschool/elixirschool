%{
  version: "1.1.1",
  title: "Керуючі конструкції",
  excerpt: """
  В цьому уроці ми розглянемо доступні в мові Elixir керуючі конструкції.
  """
}
---

## `if` та `unless`

Скоріш за все, ви вже зустрічали оператор `if/2`, а якщо програмували на Ruby, то зустрічали і `unless/2`. В Elixir вони функціонують так само, але визначені як макрос, а не конструкція мови. Код реалізації можливо побачити в модулі [Kernel](https://hexdocs.pm/elixir/Kernel.html).

Варто зазначити, що в Elixir єдиним хибними значеннями є `nil` та `false`.

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

`unless/2` схожий на `if/2`, але працює навпаки:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Якщо потрібно зіставити з декількома зразками, використовується оператор `case/2`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Змінна `_` є важливою частиною конструкції `case/2`. Без неї, у випадку відсутності знайденого зіставлення, станеться помилка:

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

Змінну `_` можливо розглядати як `else`, котрий буде зіставлений з чим завгодно.
Так, як `case/2` базується на зіставлені зі зразком, то всі ті ж обмеження і особливості продовжують діяти. Якщо потрібно провести зіставлення зі значенням змінної замість її присвоєння, використовується вже знайомий оператор `^/1`:

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Другою цікавою можливістю `case/2` є підтримка обмежувальних виразів:

_Цей приклад взятий з офіційної документації [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Також рекомендуємо почитати офіційну документацію про [вирази, доступні в обмежувальних виразах](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## `cond`

Коли потрібно перевіряти умови, а не значення, можна скористатися `cond/1`. Це схоже на `else if` чи `elsif` в інших мовах:

_Цей приклад взятий з офіційної документації [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

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

Так само, як і `case/2`, `cond/1` викличе помилку, якщо не пройде жоден з виразів. Для вирішення цієї проблеми можна визначити умову в `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

Спеціальна форма `with/1` може знадобитися в ситуаціях, коли важко використовувати оператор потоку, або коли потрібен вкладений виклик `case/2`. `with/1` складається з ключових слів, генераторів та виразу в кінці.

Ми ще поговоримо про генератори в [уроці про спискові включення](../comprehensions/), але зараз нам достатньо знати лише те, що вони використовують [зіставлення зі зразком](../pattern-matching/) для порівняння правої частини `<-` з лівою.

Почнемо з простого прикладу з `with/1`:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

У випадку, якщо для виразу не знайдеться збіг, повернеться значення, яке не збіглося:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Давайте глянемо на приклад побільше без використання `with/1`, а потім подивимось, як його можна покращити:

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

А тепер, завдяки `with/1`, ми отримаємо короткий та простий для розуміння код:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```

Починаючи з версії Elixir 1.3, конструкція `with/1` також почала підтримувати `else`:

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

Це допомагає структурувати код обробки помилок за допомогою зіставлення зі зразком в загальному блоці-обробнику. Значення, котре туди передаєтеся &mdash; перший же вираз, який не зіставився в основному тілі `with`.
