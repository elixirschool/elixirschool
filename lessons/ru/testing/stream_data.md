---
version: 1.1.1
title: StreamData
---

Ориентированная на примеры библиотека для модульного тестирования вроде [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) - это отличный инструмент, чтобы удостовериться, что ваш код работает так, как вы от него ожидаете. 
Тем не менее, тестирование на примерах имеет некоторые недостатки:

* Бывает легко упустить крайние случаи, так как тестируется ограниченный набор входных данных.
* Такие тесты могут быть написаны без тщательного продумывания требований к коду.
* Также они могут содержать много кода, если использовать несколько примеров для каждой функции.

В этом уроке мы узнаем, как библиотека [StreamData](https://github.com/whatyouhide/stream_data) может помочь нам справиться с этими недостатками.

{% include toc.html %}

## Что такое StreamData?

[StreamData](https://github.com/whatyouhide/stream_data) - это библиотека для тестирования на основе свойств.

StreamData запускает каждый тест [100 раз по умолчанию](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options), используя случайные входные данные каждый раз.
Когда тест выдаёт ошибку, StreamData попытается [уменьшить](https://hexdocs.pm/stream_data/StreamData.html#module-shrinking) входные данные до наименьшего значения, которое вызывает ошибку.
Это может быть полезным при отладке вашего кода!
Если список из 50 элементов ломает вашу функцию, и только один из элементов проблемный, StreamData может помочь вам определить этот элемент.

В этой библиотеке два основных модуля.
[`StreamData`](https://hexdocs.pm/stream_data/StreamData.html) генерирует потоки случайных данных.
[`ExUnitProperties`](https://hexdocs.pm/stream_data/ExUnitProperties.html) позволяет вам запускать тесты на функциях, используя генерированные данные как входные.

Вы можете задаться вопросом: как можно разумно рассуждать о функции, если точно неизвестно, какие входные данные. Читайте далее!

## Установка StreamData

Во-первых, создадим новый Mix-проект.
Если вам нужна помощь, обратитесь к разделу [Создание проекта](https://elixirschool.com/ru/lessons/basics/mix/#%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5-%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B0).

Во-вторых, добавим StreamData как зависимость в файле `mix.exs`:

```elixir
defp deps do
  [{:stream_data, "~> x.y", only: :test}]
end
```

Замените `x` и `y` на версию StreamData, указанную в [инструкции по установке](https://github.com/whatyouhide/stream_data#installation).

В-третьих, запустите эту команду в вашем терминале:

```shell
mix deps.get
```

## Использование StreamData

Чтобы проиллюстрировать функциональность StreamData, мы напишем несколько простых функций, которые повторяют значения.
Предположим, что мы хотим функцию вроде [`String.duplicate/2`](https://hexdocs.pm/elixir/String.html#duplicate/2), но она должна повторять строки, списки и кортежи.

### Строки

Сначала давайте напишем функцию для повторения строк.
Какие требования могут быть к этой функции?

1. Первый аргумент должен быть строкой.
Эту строку мы будем повторять.
2. Второй аргумент должен быть неотрицательным целым числом.
Столько раз мы будем повторять первый аргумент.
3. Функция должна возвращать строку.
Эта новая строка - просто исходная строка, повторённая ноль или больше раз.
4. Если исходная строка пустая, повторённая строка тоже должна быть пустой.
5. Если второй аргумент равен `0`, повторённая строка должна быть пустой.

Когда мы используем нашу функцию, это должно выглядеть так:

```elixir
Repeater.duplicate("a", 4)
# "aaaa"
```

В Elixir есть функция `String.duplicate/2`, которая сделает это за нас.
Наша новая функция `duplicate/2` будет просто делегировать всё этой функции:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end
end
```

Положительные случаи легко проверять с помощью [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html).

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicate/2" do
    test "создаёт новую строку из первого аргумента, повторённого указанное количество раз" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end
  end
end
```

Но это едва ли полноценный тест.
Что должно произойти, если второй аргумент равен `0`?
Каким должен быть результат, если первый аргумент - пустая строка?
Что вообще значит "повторять пустую строку"?
Как функция должна работать с символами Юникод?
Будет ли функция работать с большими входными строками?

Мы могли бы написать ещё больше примеров для проверки крайних случаев и больших строк.
Но давайте попробуем использовать StreamData для тщательной проверки этой функции без большого количества кода.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "создаёт новую строку из первого аргумента, повторённого указанное количество раз" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do

        assert ??? == Repeater.duplicate(str, times)
      end
    end
  end
end
```

Как это работает?

* Мы заменили `test` на [`property`](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109).
Это позволяет нам описать свойство для проверки.
* [`check/1`](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1) - это макрос, который позволяет описать данные для использования в тесте.
* [`StreamData.string/2`](https://hexdocs.pm/stream_data/StreamData.html#string/2) генерирует случайные строки.
Мы можем опустить имя модуля при вызове `string/2`, потому что `use ExUnitProperties` [включает функции StreamData](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109).
* `StreamData.integer/0` генерирует случайные целые числа.
* `times >= 0` очень похоже на ограничивающее выражение.
Оно гарантирует, что случайные целые числа в нашем тесте всегда больше или равны нулю.
Существует функция [`SreamData.positive_integer/0`](https://hexdocs.pm/stream_data/StreamData.html#positive_integer/0), но она не совсем подходит в данном случае, так как `0` - приемлемое значение для нашей функции.

`???` - просто добавленный мной псевдокод.
Что именно мы хотим утвердить?
Мы _могли бы_ написать:

```elixir
assert String.duplicate(str, times) == Repeater.duplicate(str, times)
```

... но такое утверждение использует фактическую реализацию функции, поэтому оно не имеет смысла.
Мы можем ослабить наше утверждение, проверяя только длину строки:

```elixir
expected_length = String.length(str) * times
actual_length =
  str
  |> Repeater.duplicate(times)
  |> String.length()

assert actual_length == expected_length
```

Это лучше, чем ничего, но не идеально.
Этот тест все равно бы проходил успешно, если бы наша функция генерировала случайные строки правильной длины.

В действительности мы хотим проверить два сценария:

1. Наша функция генерирует строку правильной длины.
2. Содержимое результата - это исходная строка, повторённая несколько раз.

Это просто ещё один способ [перефразировать свойство](https://www.propertesting.com/book_what_is_a_property.html#_alternate_wording_of_properties).
У нас уже есть код для проверки пункта 1.
Для проверки пункта 2, давайте разделим результат на исходной строке, и утвердим, что мы получили список из нуля или более пустых строк.

```elixir
list =
  str
  |> Repeater.duplicate(times)
  |> String.split(str)

assert Enum.all?(list, &(&1 == ""))
```

Давайте объединим наши утверждения:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "создаёт новую строку из первого аргумента, повторённого указанное количество раз" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end
  end
end
```

Если сравнить это с изначальными тестами, версия с использованием StreamData длиннее в два раза.
Но если добавить больше примеров в изначальные тесты...

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "повторение строки" do
    test "повторяет первый аргумент столько раз, как указано во втором аргументе" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end

    test "возвращает пустую строку, если первый аргумент - пустая строка" do
      assert "" == Repeater.duplicate("", 4)
    end

    test "возвращает пустую строку, если второй аргумент равен 0" do
      assert "" == Repeater.duplicate("a", 0)
    end

    test "работает на более длинных строках" do
      alphabet = "abcdefghijklmnopqrstuvwxyz"

      assert "#{alphabet}#{alphabet}" == Repeater.duplicate(alphabet, 2)
    end
  end
end
```

...версия на StreamData получается короче.
StreamData также проверяет случаи, которые разработчик мог забыть проверить.

### Списки

Теперь давайте напишем функцию для повторения списков.
Она должна работать таким образом:

```elixir
Repeater.duplicate([1, 2, 3], 3)
# [1, 2, 3, 1, 2, 3, 1, 2, 3]
```

Вот правильная, но не очень производительная реализация:

```elixir
defmodule Repeater do
  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end
end
```

Тест с использованием StreamData может выглядеть вот так:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "создаёт новый список, в котором элементы исходного списка повторены указанное количество раз" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end
  end
end
```

Мы использовали `StreamData.list_of/1` и `StreamData.term/0` для создания списков случайной длины, элементы которых могут быть любого типа.

Как в тестах для повторения строк, мы сравниваем длину нового списка с произведением длины исходного списка и `times`.
Второе утверждение стоит объяснить:

1. Мы разбиваем новый список на части, длина каждой из которых равна длине `list`.
2. Затем мы проверяем, равна ли каждая часть `list`.

Другими словами, мы убеждаемся, что исходный список оказался в результате нужное количество раз, и что никаких _лишних_ элементов в результате не оказалось.

Зачем мы использовали условие?
Первое утверждение и условие вместе говорят нам, что и исходный список, и результат пусты, и нет нужды их сравнивать.
Более того, `Enum.chunk_every/2` требует, чтобы второй аргумент был положительным.

### Кортежи

В конце давайте напишем функцию для повторения элементов кортежа.
Она должна работать вот так:

```elixir
Repeater.duplicate({:a, :b, :c}, 3)
# {:a, :b, :c, :a, :b, :c, :a, :b, :c}
```

Один из подходов - перевести кортеж в список, повторить список, и перевести результат обратно в кортеж.

```elixir
defmodule Repeater do
  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

Как это можно тестировать?
Давайте попробуем немного другой подход.
Для строк и списков мы делали утверждения касательно длины результата и самих данных результата.
Этот же подход для кортежей возможен, но код для таких тестов может не быть таким же простым.

Рассмотрим две серии операций, которые можно осуществить над кортежем:

1. Вызвать `Repeater.duplicate/2` на кортеже, и перевести результат в список
2. Перевести кортеж в список, и передать его в `Repeater.duplicate/2`

Это - применение паттерна, который Scott Wlaschin называет ["Пути разные, цель одна"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/#different-paths-same-destination).
Я ожидаю, что обе серии вернут один и тот же результат.
Давайте применим этот подход в тесте.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "создаёт новый кортеж, в котором элементы исходного кортежа повторены указанное количество раз" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

## Итог

Теперь у нас есть три версии функции для повторения строк, списков и кортежей.
Также у нас есть несколько тестов, основанных на свойствах, которые вселяют нам твёрдую уверенность в правильности нашей реализации.

Вот финальный код нашего приложения:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end

  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end

  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

А вот тесты, основанные на свойствах:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "создаёт новую строку из первого аргумента, повторённого указанное количество раз" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end

    property "создаёт новый список, в котором элементы исходного списка повторены указанное количество раз" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end

    property "создаёт новый кортеж, в котором элементы исходного кортежа повторены указанное количество раз" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

Вы можете запустить эти тесты с помощью этой команды:

```shell
mix test
```

Помните, что каждый тест с использованием StreamData запускается 100 раз по умолчанию.
Также некоторые виды случайных данных генерируются дольше, чем другие.
Суммарный эффект - такие тесты будут медленнее модульных тестов, основанных на примерах.

Даже несмотря на это, тестирование через свойства - это отличное дополнение к модульному тестированию, основанному на примерах.
Оно позволяет писать короткие тесты, которые покрывают широкий спектр входных данных.
Если вам не нужно сохранять состояние между запусками тестов, у StreamData есть удобный синтаксис для написания тестов, основанных на свойствах.
