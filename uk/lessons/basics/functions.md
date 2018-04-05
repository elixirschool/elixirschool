---
version: 1.0.1
title: Функції
---

В Elixir, як і в багатьох інших функціональних мовах програмування, функції є повноцінними об'єктами. В цьому уроці ми розглянемо типи функцій в Elixir, чим вони відрізняються і як ними користуватись.

{% include toc.html %}

## Анонімні функції

Як випливає з назви, у анонімної функції нема імені. В уроці `Enum` було показано що вони часто використовуються у якості параметрів інших функцій. Для визначення анонімної функції в Elixir використовуються ключові слова `fn` та `end`. Між ними можна визначити будь-яку кількість параметрів та тіл функції (function body), розділених `->`.

Давайте розглянемо простий приклад:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Короткий синтаксис

Анонімні функції використовуються в мові дуже часто. Тому для них було створено спеціальне скорочення:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Як ви вже могли здогадатися, у скороченій версії параметри доступні як  `&1`, `&2`, `&3` і так далі.

## Зіставлення зі зразком

Зіставлення зі зразком в Elixir застосовується не тільки для зіставлення змінних. Цей же інструмент використовується для оголошення функцій.

Elixir використовує зіставлення зі зразком для визначення першого підходящого набору параметрів та викликає відповідну імплементацію:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Handling result...

iex> handle_result.({:error})
An error has occurred!
```

## Іменовані функції

Також в Elixir є можливість визначати іменовані функції для подальшого їх виклику за цими іменами. Ці функції оголошуються за допомогою ключового слова `def` в контексті модуля. Більш детально ми розглянемо модулі в наступних уроках, а в цьому ми зосередимося тільки на іменованих функціях.

Функції, визначені в модулі, доступні з других модулів:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Якщо функція поміщається в один рядок (однорядкова), то її опис можна скоротити, використовуючи `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Вже розібравшись у зіставленні зі зразком, давайте розглянемо приклад рекурсії з використанням іменованих функцій:

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

### Найменування та арність функцій

Раніше ми зазначали, що функції іменуються шляхом поєднання імені та арності (кількості аргументів). Це дозволяє робити такі речі:

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

В коментарях до функцій ми привели їх найменування. Перша функція не приймає жодних аргументів, тому описується як `hello/0`; друга приймає один параметр, тому описується як `hello/1` і т.д. На відміну від перевантаження функцій в деяких інших мовах програмування, в нашому випадку функції варто вважати _різними_ . (Зіставлення зі зразком, яке ми описували раніше, застосовується тільки у випадку, коли для функцій з _однаковою_ кількістю аргументів надається декілька різних реалізацій.)

### Закриті функції

Якщо ми не хочемо давати доступ до функції з других модулів, ми визначаємо закриті (private) функції. Вони можуть бути викликані тільки з того ж модуля. Такі функції визначаються за допомогою `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Обмежувачі

Ми вже стикалися з обмежувачами у розділі [Керуючі конструкції](../control-structures), тепер давайте розглянемо їх застосування в іменованих функціях. Обмежувачі перевіряються тільки після того, як Elixir зіставив функцію.

В наступному прикладі у нас є дві функції з однаковими сигнатурами. Ми використовуємо обмежувачі для визначення, яку саме з них використовувати на основі типу аргументу:

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

### Аргументи за замовчуванням

Коли ми хочемо, щоб аргумент мав деяке значення за замовчуванням - використовується синтаксис `argument \\ value`:

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

Коли ми застосовуємо одночасно обмежувачі та аргументи за замовчуванням, то все перестає працювати. Давайте подивимось як це виглядає:

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

Elixir не підтримує аргументи за замовчуванням при наявності декількох підходящих функцій. Для вирішення цієї проблеми ми додаємо визначення функції з аргументами за замовчуванням:

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
