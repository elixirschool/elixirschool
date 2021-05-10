%{
  version: "0.9.1",
  title: "Функции",
  excerpt: """
  В Elixir и много функционални езици, функциите са граждани "първи клас".  Ще научим за видовете функции в Elixir, какво ги отличава и как да ги използваме.
  """
}
---

## Анонимни функции

Както името подсказва, анонимната функция няма име.  Както видяхме в урока относно `Enum`, те често се подават към други функции.  За да дефинираме анонимна функция в Elixir се нуждаем от ключовите думи `fn` и `end`.  Между тях може да дефинираме всякакъв брой параметри и имплементации на функции, разграничени от `->`.

Нека погледнем един прост пример:

```elixir
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

Съпоставката с образец не е ограничена само до променливи в Elixir, може да се приложи и върху функции, както ще видим в тази секция.

Elixir използва съпоставката с образец, за да идентифицира първия подходящ набор от параметри и извиква съответната имплементация:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
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

Въоръжени със знанието за съпоставка с образец, нека разгледаме рекурсия използвайки именовани функции:

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

### Именоване на фукнции и Arity

Споменахме по-рано, че функциите се именоват с комбинация от дадено име и arity(броя аргументи). Това означава, че може да се правят неща като:

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

Изредили сме имената на функциите в коментарите отгоре. Първата имплементация приема нула аргумента, за това е `hello/0`; втората приема един аргумент и е `hello/1`, и т.н. За разлика от предефинирани функции в някои други езици, за тези се мисли като __отделни__ една от друга. (Съпоставката с образец, описан преди момент, се отнася само когато няколко дефиниции са осигурени за дефиниции на функции със __същия__ брой аргументи.)

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
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Ограничители

Бегло споменахме ограничители в урока [Контролни структури](../control-structures), сега ще видим как да ги приложим към именовани функции.  Веднъж като Elixir е намерил подходяща функция всички съществуващи ограничители ще бъдат тествани.

В следващия пример имаме две еднакво разписани функции, разчитаме на ограничители, за да разберем коя да бъде използвана базирано на типа на аргумента:

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

### Аргументи по подразбиране

Ако искаме да имаме стойност по подразбиране за аргумент използваме синтаксиса `аргумент \\ стойност`:

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

Когато комбинираме примера ни с ограничители със стойности по подразбиране, се сблъскваме с проблем.  Нека видим как изглежда:

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

Elixir не харесва аргументи със стойност по подразбиране при наличие на няколко подходящи функции, това води до объркване.  За да се справим с това добавяме описателна функция с нашите стойности по подразбиране:

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
