%{
  version: "1.3.0",
  title: "Основы",
  excerpt: """
  Базовая настройка, типы и операторы.
  """
}
---

## Настройка

### Установка Elixir

Инструкции по установке для всех ОС есть на [официальном сайте](http://elixir-lang.org/install.html).

После того, как Elixir установлен, вы с лёгкостью можете проверить, какая именно версия была установлена.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Интерактивный режим

Вместе с языком в комплекте идет приложение интерактивной командной строки IEx, которое позволяет выполнять выражения языка на лету.

Для того чтобы начать, запустите `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Примечание: В Windows PowerShell вам нужно написать `iex.bat`.

Попробуем написать несколько простых выражений:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Не стоит волноваться, если пока вы поняли не все выражения.

## Базовые типы

### Целые числа

```elixir
iex> 255
255
```

Поддерживаются также бинарные, восьмеричные и шестнадцатеричные числа:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Числа с плавающей запятой

В Elixir числа с плавающей запятой требуют наличия хотя бы одной цифры перед точкой. Также они поддерживают `e` для описания экспонентной части:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Логический тип

Elixir поддерживает два значения логического типа: `true` и `false`. Абсолютно все значения в языке считаются истинными кроме `false` и `nil`:

```elixir
iex> true
true
iex> false
false
```

### Атомы

Атом &mdash; константа, название которой является и значением.
В других языках (например, в Ruby) они называются символами:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Стоит отметить, что булевы значения `true`, `false` являются атомами `:true` и `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Названия модулей в Elixir — тоже атомы. `MyApp.MyModule` — валидный атом, даже если такой модуль ещё не был объявлен.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Также атомы используются в качестве ссылок на модули из библиотек Erlang, в том числе и встроенные.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Строки

Строки в Elixir всегда представлены в кодировке UTF-8 и заключаются в двойные кавычки:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Строки могут включать разрывы и экранированные последовательности:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

В Elixir есть и более сложные типы данных.
Мы узнаем о них больше, когда познакомимся с [коллекциями](../collections/) и [функциями](../functions/).

## Базовые операторы

### Арифметика

В Elixir, ожидаемо, есть базовые операторы `+`, `-`, `*`, `/`.
Стоит отметить что результатом вызова `/` всегда будет число с плавающей запятой:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

Если нужно целочисленное деление или получение остатка &mdash; в языке есть две удобные функции специально для этого:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Логические операторы

Elixir предоставляет операторы `||`, `&&`, `!`, которые поддерживают работу с любыми типами:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

Также есть три дополнительных оператора, у которых первый аргумент _обязан_ быть логического типа (`true` или `false`):

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

Примечание: операторы `and` и `or` в Elixir на самом деле соответствуют `andalso` и `orelse` в Erlang.

### Сравнения

В Elixir поддерживаются все стандартные операторы сравнения: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<`, `>`.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

Для строгого сравнения целых чисел и чисел с плавающей запятой используется `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Удобной возможностью языка является то, что любые типы сравнимы друг с другом. Это удобно при сортировках. Порядок не стоит запоминать, но о его существовании стоит знать:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Это приводит к некоторым интересным правильным сравнениям, которых обычно нет в других языках программирования:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Интерполяция строк

Если вы использовали язык Ruby, то интерполяция в Elixir покажется вам знакомой:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Объединение строк

Для объединения двух строк используется оператор `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
