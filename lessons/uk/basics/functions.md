%{
  version: "1.2.0",
  title: "Функції",
  excerpt: """
  В Elixir, як і в багатьох інших функціональних мовах програмування, функції є повноцінними об'єктами.
В цьому уроці ми розглянемо типи функцій в Elixir, чим вони відрізняються і як ними користуватись.
  """
}
---

## Анонімні функції

Як випливає з назви, у анонімної функції нема імені.
В уроці `Enum` було показано що вони часто використовуються у якості параметрів інших функцій.
Для визначення анонімної функції в Elixir використовуються ключові слова `fn` та `end`.
Між ними можна визначити будь-яку кількість параметрів та тіл функції (function body), розділених `->`.

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

Зіставлення зі зразком в Elixir застосовується не тільки для зіставлення змінних.
Цей же інструмент використовується для оголошення функцій.

Elixir використовує зіставлення зі зразком для перевірки всіх наборів параметрів і вибору першого відповідного набору для виконання:

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

## Іменовані функції

Також в Elixir є можливість визначати іменовані функції для подальшого їх виклику за цими іменами.
Ці функції оголошуються за допомогою ключового слова `def` в контексті модуля.
Більш детально ми розглянемо модулі в наступних уроках, а в цьому ми зосередимося тільки на іменованих функціях.

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

Раніше ми зазначали, що функції іменуються шляхом поєднання імені та арності (кількості аргументів).
Це дозволяє робити такі речі:

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

В коментарях до функцій ми привели їх найменування.
Перша функція не приймає жодних аргументів, тому описується як `hello/0`; друга приймає один параметр, тому описується як `hello/1` і т.д.
На відміну від перевантаження функцій в деяких інших мовах програмування, в нашому випадку функції варто вважати _різними_ .
(Зіставлення зі зразком, яке ми описували раніше, застосовується тільки у випадку, коли для функцій з _однаковою_ кількістю аргументів надається декілька різних реалізацій.)

### Функції і зіставлення зі зразком

За лаштунками функції зіставляють зі зразком аргументи, з якими вони були викликані.

До прикладу, нам потрібно написати функцію, яка приймає асоціативний масив, і ми зацікавлені у використанні лише одного конкретного ключа.
В такому разі ми можемо зіставити аргумент зі зразком таким чином, щоб перевірити наявність цього ключа:

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

Припустімо, що ми маємо асоціативний масив, який описує людину на ім'я Fred:
```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"  
...> }
```

Ось такі результати ми отримаємо, коли викличемо `Greeter1.hello/1` з асоціативним масивом `fred`:

```elixir
# виклик з повним масивом
...> Greeter1.hello(fred)
"Hello, Fred"
```

Що трапиться, коли ми викличемо функцію з асоціативним масивом, що _не_ містить ключ `:name`?

```elixir
# виклик без потрібного ключа повертає помилку
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1    
    The following arguments were given to Greeter1.hello/1:
        # 1
        %{age: "95", favorite_color: "Taupe"}
    iex:12: Greeter1.hello/1
```

Причиною такої поведінки є те, що в Elixir зіставлення аргументів функції зі зразком викликається на арність, з якою ця функція визначена.

Давайте подивимося на те, як виглядають дані, коли вони надходять у `Greeter1.hello/1`:

```Elixir
# вхідний асоціативний масив
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"  
...> }
```
`Greeter1.hello/1` очікує такого аргументу:
```elixir
%{name: person_name}
```
В `Greeter1.hello/1` переданий асоціативний масив (`fred`) зіставляється з нашим аргументом (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Функція виявляє, що у вхідному асоціативному масиві є ключ, який відповідає на `name`.
Зіставлення успішне! І як результат успішного зіставлення, значення ключа `:name` з асоціативного масиву справа (наприклад асоціативний масив `fred`) пов'язується зі змінною зліва (`person_name`).

А тепер, що якби ми все ще хотіли присвоїти ім'я Fred змінній `person_name`, але ми ТАКОЖ хотіли би зберегти знання про всю асоціативну мапу людини?
Скажімо, ми хочемо виконати `IO.inspect(fred)` після привітання.
Наразі через те, що ми зіставили зі зразком лише ключ `:name` із нашого асоціативного масиву, ми пов'язуємо лише значення цього ключа зі змінною - функція не має решти знань про Фреда.

Для того, щоб цю інформацію зберегти і могти використовувати, ми повинні присвоїти весь асоціативний масив окремій змінній.

Давайте напишемо нову функцію:
```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Пам'ятаймо, що Elixir буде на вході зіставляти аргумент зі зразком.
Тому в цьому випадку кожна сторона буде зіставляти зі зразком вхідний аргумент і прив'язувати його до того, що зі зразком співпало.
Для початку глянемо на праву сторону:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Зараз до змінної `person` було прив'язано весь асоціативний масив `fred`.
Далі подивимося на наступне зіставлення зі зразком:
```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Далі все таке ж, як в оригінальній функції `Greeter1`, де ми зіставляли зі зразком асоціативний масив і залишали лише ім'я Фреда.
Нам вдалося отримати дві змінні, які ми можемо використовувати (на противагу одній в оригінальній функції):
1. `person` зберігає дані `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name` зберігає стрічку `"Fred"`

Тому зараз, коли ми викликаємо `Greeter2.hello/1`, ми можемо використовувати всю інформацію про Фреда:
```elixir
# виклик з всією інформацією про людину
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# виклик лише з ключем імені
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# виклик без ключа імені
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1    
    The following arguments were given to Greeter2.hello/1:
        # 1
        %{age: "95", favorite_color: "Taupe"}
    iex:15: Greeter2.hello/1
```

З цього ми бачимо, що в Elixir зіставлення зі зразком має неабияку глибину, оскільки кожен аргумент незалежно зіставляється з вхідними даними, залишаючи нам змінні, за якими ці дані можна викликати в нашій функції.

Якщо ми змінимо порядок `%{name: person_name}` і `person` в списку, то ми отримаємо ідентичний результат, оскільки вони співставляють `fred` незалежно.

Ми обмінюємо змінну і асоціативний масив:
```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

І викликаємо з тими ж даними, які використовували в `Greeter2.hello/1`:
```elixir
# викликаємо з тим же Фредом
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Пам'ятаймо, що хоча виглядає це так, ніби `%{name: person_name} = person` зіставляє `%{name: person_name}` зі змінною `person`, насправді тут _обидві_ сторони зіставляються з вхідним аргументом.

**Підсумок:** Функції незалежно зіставляють вхідні дані з кожним своїм аргументом. Ми можемо це використовувати для того, щоб прив'язувати значення до окремих змінних всередині функції.

### Закриті функції

Якщо ми не хочемо давати доступ до функції з других модулів, ми визначаємо закриті (private) функції.
Вони можуть бути викликані тільки з того ж модуля. Такі функції визначаються за допомогою `defp`:

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

### Обмежувачі

Ми вже стикалися з обмежувачами у розділі [Керуючі конструкції](../control-structures), тепер давайте розглянемо їх застосування в іменованих функціях.
Обмежувачі перевіряються тільки після того, як Elixir зіставив функцію.

В наступному прикладі у нас є дві функції з однаковими сигнатурами.
Ми використовуємо обмежувачі для визначення, яку саме з них використовувати на основі типу аргументу:

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

Коли ми застосовуємо одночасно обмежувачі та аргументи за замовчуванням, то все перестає працювати.
Давайте подивимось як це виглядає:

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

Elixir не підтримує аргументи за замовчуванням при наявності декількох підходящих функцій.
Для вирішення цієї проблеми ми додаємо визначення функції з аргументами за замовчуванням:

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
