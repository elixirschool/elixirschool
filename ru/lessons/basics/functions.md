---
version: 1.2.0
title: Функции
---

В Elixir, как и в многих других функциональных языках, функции являются полноценными объектами.
В этом уроке мы рассмотрим типы функций в Elixir, чем они отличаются и как их использовать.

{% include toc.html %}

## Анонимные функции

Как и следует из названия, у анонимной функции нет имени.
В уроке `Enum` было показано что они часто используются в качестве параметров других функций.
Для определения анонимной функции в Elixir используются ключевые слова `fn` и `end`.
Между ними можно определить любое количество параметров и тел функции (function body), разделённых `->`.

Давайте рассмотрим простой пример:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Краткий синтаксис

Анонимные функции используются в языке очень часто. Потому для них было создано специальное сокращение:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Как вы уже могли догадаться, в сокращенной версии параметры доступны как  `&1`, `&2`, `&3` и так далее.

## Сопоставление с образцом

Сопоставление с образцом в Elixir применяется не только для сопоставления переменных. Этот же инструмент используется в объявлении функций.

Elixir использует сопоставление с образцом для проверки возможных вариантов, выбирая для вызова первый соответствующий вариант:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## Именованные функции

Можно определять именованные функции для дальнейшего их вызова по этим именам.
Эти функции объявляются с помощью ключевого слова `def` в контексте модуля.
Про модули будет подробнее рассказано в следующих уроках, а в этом мы сосредоточимся только на именованных функциях.

Функции, определенные в модуле, доступны из других модулей:
Это особенно полезный элемент в Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Если функция однострочная, то ее описание можно сократить с использованием `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Уже разобравшись в сопоставлении с образцом, давайте рассмотрим пример рекурсии с использованием именованных функций:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Наименования и арность функций

Ранее мы отмечали, что функции именуются путём сочетания имени и арности (количества аргументов).
Это позволяет делать такое:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

В комментариях к функциям мы привели их наименования.
Первая функция не принимает аргументы, потому описывается как `hello/0`; вторая принимает один параметр, потому описывается как `hello/1`, и т.д.
В отличие от перегрузки функций в некоторых других языках, в нашем случае функции стоит считать _разными_.
(Сопоставление с образцом, описанное ранее, применяется только в случае, когда для функций с _одинаковым_ количеством аргументов предоставлены несколько различных описаний.)

### Функции и сопоставление с образцом

Под капотом функции используют сопоставление с образцом для аргументов, с которыми они были вызваны.

Допустим, нам нужна функция, принимающая ассоциативный массив, в котором нам интересует лишь определённый ключ.
Можно сопоставить образец с аргумента на наличие этого ключа следующим образом:


```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

Теперь предположим, что у нас есть ассоциативный массив, который представляет человека по имени Fred:
```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

При вызове `Greeter1.hello/1` с данным ассоциативным массивом `fred` мы получим следующий результат:

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```

Что будет, если вызвать функцию с ассоциативным массивом, который _не_ содержит ключ `:name`?

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

Причина такого результата состоит в том, что Elixir сопоставляет переданные аргументы с арностью функции.

Давайте выясним, что происходит при вызове `Greeter1.hello/1`:

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```
`Greeter1.hello/1` ожидает такой аргумент:
```elixir
%{name: person_name}
```
В `Greeter1.hello/1` передаваемый ассоциативный массив (`fred`) сопоставляется с нашим аргументом (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Функция находит, что есть ключ, который соответствует ключу `name` в переданном ассоциативной массиве.
У нас совпадение! И в результате этого значение ключа `:name` в ассоциативном массиве справа (т.е. в массиве `fred`) привязывается к переменной слева (`person_name`).

Теперь, что если мы все ещё хотим присвоить имя Fred в `person_name`, но и кроме этого ТАКЖЕ хотим сохранить весь ассоциативный массив человека? Допустим, нам захотелось выполнить `IO.inspect(fred)` после того, как мы приветствуем его.
Сейчас, поскольку мы сопоставили только `:name` из нашего ассоциативного массив и, таким образом, привязали только значение этого ключа с переменной, функция не знает больше ничего про Фреда.

Чтобы сохранить данные про него, нам нужно присвоить весь связанный с ним ассоциативный массив отдельной переменной, чтобы мы могли его потом использовать.

Давайте создадим новую функцию:
```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Помните о том, что Elixir будет делать сопоставление с аргументом по мере его поступления.
Поэтому в данном случае каждая часть будет сопоставлять образец с переданным аргументом и привязываться к той, с чем было совпадение.
Давайте сначала рассмотрим правую часть:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Теперь переменной `person` присвоена целиком весь ассоциативный массив с данные про Фреда.
Двигаемся дальше к следующему сопоставлению с образцом:

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Сейчас это похоже на нашу оригинальную функция `Greeter1`, где мы сопоставляем образец с ассоциативным массивом и оставляем только имя Фреда.
У нас есть две переменные, которые мы можем использовать вместо одной:
1. `person`, ссылающаяся на `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name`, ссылающаяся на `"Fred"`

Так что теперь, когда мы вызываем `Greeter2.hello/1`, мы можем использовать всю информацию про Фреда:
```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

Таким образом мы увидели сопоставление с образцом Elixir работает на несколько уровней, поскольку каждый аргумент сопоставляется с переданными данными независимо, оставляя нам переменные для их вызова внутри нашей функции.

Итак, мы видели, что шаблон Elixir сопоставляется на нескольких глубинах, потому что каждый аргумент сопоставляется с входящими данными независимо, в результате чего у нас есть переменные, которые можно использовать внутри функции.

Если мы изменим порядок `%{name: person_name}` и `person` в списке, то получим тот же самый результат, потому что каждый из них соответствует fred сам по себе.

Обмениваем переменную и ассоциативный массив:
```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

И теперь вызываем нашу функцию с теми же данными, которые использовали при вызове `Greeter2.hello/1`:
```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Учтите, что, хотя это выглядит так, что `%{name: person_name} = person` сопоставляется с образцом `%{name: person_name}` в переменную `person`, на самом деле _каждое_ сопоставление с образцом производится на переданном аргументе.

**Резюме**: Функции сопоставляют с образцом данные, передаваемые каждому из его аргументов, независимо друг от друга.
Мы можем использовать это для привязки значений к отдельным переменным внутри функции.

### Закрытые функции

Когда мы не хотим давать доступ к функции из других модулей, мы определяем закрытые (private) функции.
Они могут быть вызваны только из этого же модуля. Такие функции определяются с помощью `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase() <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Ограничители

Мы уже затрагивали ограничители в главе [Управляющие конструкции](../control-structures), теперь же рассмотрим их применение в именованных функциях.
Ограничители проверяются только после того как Elixir сопоставил функцию.

В следующем примере у нас есть две функции с одинаковыми сигнатурами. Мы используем ограничители для определения какую из них использовать на основе типа аргумента:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Аргументы по умолчанию

Когда мы хотим иметь некое значение по умолчанию у аргумента - используется синтаксис `argument \\ value`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

Когда мы используем одновременно ограничители и аргументы по умолчанию, то все перестает работать. Давайте посмотрим как это выглядит:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir не поддерживает аргументы по умолчанию при наличии нескольких подходящих функций. Для решения этой проблемы мы добавляем определение функции с аргументами по умолчанию:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
