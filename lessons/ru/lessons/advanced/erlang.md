%{
  version: "1.0.2",
  title: "Взаимодействие с Erlang",
  excerpt: """
  Одним из достоинств построения языка на инфраструктуре Erlang VM (BEAM) является изобилие готовых библиотек.
Совместимость позволяет нам использовать все эти библиотеки (включая стандартную библиотеку Erlang) в нашем коде на Elixir.
В этом уроке мы рассмотрим, как получить доступ к функциональности стандартной библиотеки вместе со сторонними пакетами Erlang.
  """
}
---

## Стандартная библиотека

Обширная стандартная библиотека Erlang доступна для использования из любого Elixir кода в нашем приложении. Модули Erlang представлены атомами в нижнем регистре, такими как `:os` и `:timer`.

Давайте воспользуемся `:timer.tc` для измерения времени выполнения функции:

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

Полный список доступных модулей есть в [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/).

## Пакеты Erlang

В предыдущем уроке мы рассмотрели Mix и управление зависимостями.
Подключение библиотек Erlang происходит так же.
В тех случаях, когда библиотеки нет на [Hex](https://hex.pm), можно подключить ее напрямую из Git-репозитория:

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

Теперь мы можем использовать эту библиотеку Erlang:

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Заметные различия

Теперь, зная как использовать Erlang, рассмотрим нюансы этого взаимодействия.

### Атомы

Атомы в Erlang выглядят так же как и аналоги в Elixir, но без двоеточия (`:`). Они содержат буквы в нижнем регистре и подчеркивания:

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Строки

Когда мы говорим о строках в Elixir, имеются ввиду бинарные объекты в UTF-8. В Erlang строки точно так же используют двойные кавычки, но являются списком символов:

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

Многие старые библиотеки Erlang могут не поддерживать бинарные строки, потому нужно рассмотреть как превращать строки Elixir в строковые списки.
К счастью, это легко достигается функцией `to_charlist/1`:

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

### Переменные

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

Вот и всё! В наших приложениях Elixir можно с лёгкостью применять Erlang, что удваивает количество доступных для использования библиотек.
