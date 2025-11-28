%{
  version: "1.0.4",
  title: "Взаємодія з Erlang",
  excerpt: """
  Однією з додаткових переваг створення на базі віртуальної машини Erlang (BEAM) є безліч наявних бібліотек.
  Сумісність дозволяє нам використовувати ці бібліотеки та стандартну бібліотеку Erlang з нашого коду Elixir.
  У цьому уроці ми розглянемо, як отримати доступ до функціональності у стандартній бібліотеці та сторонніх бібліотеках Erlang.
  """
}
---

## Стандартна бібліотека

Розширена стандартна бібліотека Erlang доступна з будь-якого коду Elixir.
Модулі Erlang представлені атомами в нижньому регістрі, такими як `:os` та `:timer`.

Давайте використаємо `:timer.tc` для вимірювання часу виконання функції:

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

Повний список доступних модулів можна знайти в [Документації до стандартної бібліотеки Erlang](http://erlang.org/doc/apps/stdlib/).

## Пакети Erlang

У попередньому уроці ми розглядали Mix та керування залежностями.
Підключення бібліотек Erlang працює так само.
Якщо бібліотеку Erlang не опубліковано в [Hex](https://hex.pm), можна посилатися безпосередньо на git-репозиторій:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Тепер ми можемо отримати доступ до нашої бібліотеки Erlang:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Помітні відмінності

Тепер, коли ми знаємо, як використовувати Erlang, розглянемо деякі особливості взаємодії з Erlang.

### Атоми

Атоми Erlang виглядають майже так само, як їхні аналоги в Elixir, але без двокрапки (`:`).
Вони записуються малими літерами та символом підкреслення:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Рядки

У Elixir під рядками ми розуміємо бінарні дані, закодовані в UTF-8.
В Erlang рядки також записуються в подвійних лапках, але є списками символів:

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

Важливо зазначити, що багато старих бібліотек Erlang можуть не підтримувати бінарні дані, тому нам потрібно конвертувати рядки Elixir у списки символів.
На щастя, це легко можна зробити за допомогою функції `to_charlist/1`:

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

### Змінні

У Erlang змінні починаються з великої літери та не можуть бути перевизначені.

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

Ось і все! Використання Erlang у наших програмах Elixir фактично подвоює кількість доступних бібліотек!
