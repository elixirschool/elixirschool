---
layout: page
title: Функции
category: basics
order: 7
lang: bg
---

При Elixir и много функционални езици, функциите са граждани "първа класа".  Ще научим за видовете функции в Elixir, какво ги отличава и как да ги използваме.

{% include toc.html %}

## Анонимни функции

Както името подсказва, анонимната функция няма име.  Както видяхме в урока относно `Enum` , те често се предават към други функции.  За да дефинираме анонимна функция в Elixir се нуждаем от ключовите думи `fn` и `end`.  Между тях може да дефинираме всякакъв брой параметри и имплементации на функции, разграничени от `->`.

Нека погледнем един прост пример:

```elixirre
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Съкращението &

Да се използват анонимни функции е толкова често срещано в  Elixir, че за употребата им има съкращение:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Както сигурно сте се досетили, в съкратената версия параметрите ни са достъпни за нас като `&1`, `&2`, `&3`, и т.н.

## Съпоставка с образец

Съпоставката с образец не е ограничена само до променливи в Elixir, тя може да се приложи и върху функции, както ще видим в тази секция.

Elixir използва съпоставка с образец, за да идентифицира първия подходящ набор от параметри и извиква съответната имплементация:

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

## Именовани функции

Можем да дефинираме функции с имена, за да ги достъпваме на по-късен етап, тези наименовани функции се дефинират с ключовата дума `def` в модул.  Ще научим повече за модулите в следващите уроци, засега ще се фокусираме само върху именовани функции.

Функции дефинирани в модул са достъпни и от други модули, това е изключително полезна конструкция в Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Ако нашата имплементация на функция е само един ред, може да я скъсим допълнително с `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

Въоръжени със знанието за съпоставка с образци, нека разгледаме рекурсия използвайки именовани функции:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_|t]), do: 1 + of(t)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Частни функции

Когато не желаем други модули да достъпват дадена функция може да ползваме частни функции, които могат да бъдат достъпвани само от техния модул.  Можем да ги дефинираме в Elixir посредством `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) undefined function: Greeter.phrase/0
    Greeter.phrase()
```

### Ограничители

Бегло споменахме ограничители в урока [Контролни структури](../control-structures.md), сега ще видим как да ги приложим към именовани функции.  Веднъж като Elixir е намерило подходяща функция всички съществуващи ограничители ще бъдат тествани.

В следващия пример имаме две еднакво разписани функции, разчитаме на ограничители, за да разберем коя да бъде използвана върху типа на аргумента:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### Аргументи по подразбиране

Ако искаме да имаме стойност по подразбиране за аргумент използваме синтаксиса `аргумент \\ стойност`:

```elixir
defmodule Greeter do
  def hello(name, country \\ "en") do
    phrase(country) <> name
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

Когато комбинираме примера ни с ограничители със стойности по подразбиране, се сблъскваме с проблем.  Нека видим как изглежда:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country \\ "en") when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) def hello/2 has default values and multiple clauses, define a function head with the defaults
```

Elixir не харесва аргументи със стойност по подразбиране при наличие на няколко подходящи функции, това води до объркване.  За да се справим с това добавяме описателна функция с нашите стойности по подразбиране:

```elixir
defmodule Greeter do
  def hello(names, country \\ "en")
  def hello(names, country) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country) when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
