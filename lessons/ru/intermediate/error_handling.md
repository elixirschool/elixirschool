---
version: 1.1.0
title: Обработка ошибок
---

Несмотря на то, что функции обычно возвращают кортеж вида `{:error, reason}`, Elixir поддерживает исключения. В этом уроке мы узнаем как обрабатывать ошибки и познакомимся с различными доступными для нас методами.

Общепринятый в Elixir способ &mdash; создать функцию (`example/1`), возвращающую `{:ok, result}` и `{:error, reason}` и отдельную функцию (`example!/1`), возвращающую необернутый `result` или порождающую ошибку.

В этом уроке мы сосредоточимся на взаимодействии с последней.

{% include toc.html %}

## Общие соглашения

На данный момент сообщество Elixir пришло к некоторым соглашениям относительно возврата ошибок:

* Для ошибок, которые являются частью обычной работы функции (например, пользователь ввел неверный тип даты), функция возвращает соответственно `{: ok, result}` и `{: error, cause}`.
* Для ошибок, которые не являются частью обычных операций (например, невозможность разобрать конфигурацию), вы генерируете исключение.

Обычно мы обрабатываем стандартные ошибки потока с помощью [сопоставления с образцом](../../basics/pattern-matching/), но в этом уроке мы сосредоточимся на втором случае - на исключениях.

Часто в общедоступных API вы также можете найти альтернативную версию функции с расширением! (`example!/1`), который возвращает развернутый результат или вызывает ошибку.

## Обработка ошибок

Прежде чем мы сможем обрабатывать ошибки, нам надо их создать, а простейший способ сделать это &mdash; `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Если мы хотим указать тип и сообщение, то надо воспользоваться `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Если нам известно, что может возникнуть ошибка, мы можем обработать её с помощью `try/rescue` и сопоставления с образцом:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

Можно сопоставлять сразу несколько ошибок в одном `rescue`:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

Иногда бывает необходимо выполнить какое-либо действие после `try/rescue` независимо от ошибки.
Для этого у нас есть `try/after`.
Если вы знакомы с Ruby, то это то же, что и `begin/rescue/ensure` или `try/catch/finally` в Java:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Обычно это используется с файлами или соединениями, которые должны быть закрыты:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Делаем что-нибудь опасное
after
  File.close(file)
end
```

## Новые ошибки

Elixir включает в себя несколько встроенных типов ошибок как, например, `RuntimeError`, но у нас также есть возможность создавать свои, если потребуется что-нибудь особенное.
Создавать новые ошибки легко с макросом `defexception/1`, который принимает параметр `:message` для установки сообщения об ошибке по умолчанию:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Давайте посмотрим на нашу новую ошибку в действии:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

Ещё один механизм для работы с ошибками в Elixir это `throw` и `catch`.
На практике они очень редко встречаются в новом коде Elixir, но несмотря на это важно знать и понимать их.

Функция `throw/1` даёт нам возможность прерывать выполнение с определённым значением, которое мы можем получить и использовать с помощью `catch`:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Как уже было отмечено, `throw/catch` встречается довольно редко и, как правило, используется в качестве временной меры, когда библиотека не предоставляет адекватный API.

## Выход

Последний механизм обработки ошибок, предоставляемый нам Elixir, это `exit`.
Сигналы выхода возникают, когда процесс завершается, и это важная часть отказоустойчивости Elixir.

Для явного выхода можно использовать `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Несмотря на то, что можно отлавливать выход с помощью `try/catch`, так делают _очень_ редко.
Почти во всех случаях выгоднее оставить обработку выхода из процесса супервизору:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
