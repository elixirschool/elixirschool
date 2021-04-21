%{
  version: "0.9.1",
  title: "Контролни структури",
  excerpt: """
  В този урок ще разгледаме какви контролни структури са достъпни за нас в Elixir.
  """
}
---

## if и unless

Най-вероятно сте срещали `if/2` преди, а ако сте ползвали Ruby сте запознати с `unless/2`.  При Elixir те работят по същия начин, но са дефинирани като макроси, а не конструкции на езика; Може да намерите тяхната имплементация в [Kernel module](https://hexdocs.pm/elixir/Kernel.html).

Трябва да се отбележи, че в Elixir единствените неверни стойности са `nil` и булевото `false`.

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

Използването на `unless/2` е като `if/2`, само че работи върху невярното:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## case

Ако е необходимо да се съпоставя върху няколко образеца, може да използваме `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Променливата `_` е важна добавка в условията на `case`. Без нея при ненамиране на съпоставка ще се генерира грешка:

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

Гледайте на `_` като на `else`, който ще се съпостави с "всичко друго".
Понеже `case` разчита на patern matching, всички правила и рестрикции са валидни.  Ако възнамерявате да съпоставяте срещу съществуващи променливи, трябва да използвате оператора `^`:

```elixir
iex> pie = 3.14
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Друго добро свойство на `case` е неговата поддръжка за предпазващи клаузи:

_Този пример е директно от официалното ръководство на Elixir [Начални стъпки](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Проветеве официалната документация за [Допустими изрази в предпазващи клаузи](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## cond

Когато трябва да съпоставяме условия, а не стойности, може да се обърнем към `cond`; това е сходно с `else if` или `elsif` от други езици:

_Този пример е директно от официалното ръководство на Elixir [Начални стъпки](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

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

Както при `case`, `cond` ще генерира грешка, ако няма съпоставка.  За да се справим с това, може да дефинираме условия и да го устойностим като `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

Специалната форма `with` е полезна, когато бихте използвали внедрени `case` клаузи или при ситуации, които трудно могат да бъдат обвързани. Изразът `with` е съставен от ключовата дума, генератори и на последно място израз.

Ще дискутираме генераторите повече в урока за обхващане на списъци (List Comprehensions), но засега имаме нужда само да знаем, че те използват съпоставка с образец, за да сравнят дясната страна откъм `<-` към лявата.

Ще започнем с прост пример с `with` и след това ще разгледаме още няколко:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

В случай, че израз не може да бъде съпоставен, несъпоставената част ще бъде върната обратно:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Нека сега разгледаме по-голям пример без `with` и след това да опитаме да го пренапишем:

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

Когато използваме `with` разполагаме с код, който е лесен за разбиране и съдържа по-малко редове:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token, claims),
     do: important_stuff(jwt, full_claims)
```
