---
version: 1.2.1
title: Основи
---

Встановлення Elixir, базові типи даних та прості операції.

{% include toc.html %}

## Початок роботи з Elixir

### Встановлення

Інструкції для встановлення для кожної ОС знаходяться на офіційному сайті elixir-lang.org в розділі [Installing Elixir](http://elixir-lang.org/install.html).

Після того як Elixir встановлено, ви можете легко перевірити, яку саме версію було встановлено:

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Інтерактивний режим роботи

Elixir поставляється з утилітою `iex`, інтерактивною консоллю, яка дозволяє виконувати код Elixir.

Для початку запустимо утиліту `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

То ж спробуймо написати декілька простих виразів:

```elixir
iex>
2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Не біда, якщо ви поки не розумієте деталей кожного виразу. До них ми ще дійдемо.

## Прості типи даних

### Цілі числа

```elixir
iex> 255
255
```

Також підтримуються числа в двійковій, вісімковій та шістнадцятковій системах числення:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Числа з рухомою комою

В Elixir числа з рухомою комою потребують наявності цифри на початку.

```elixir
iex> 3.41
3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Булевий тип

Elixir підтримує `true` та `false` як логічний тип. Крім `false` та `nil` все є істиною:

```elixir
iex> true
true
iex> false
false
```

### Атоми

Атом - це константа, значенням якої є її ім'я. 
Якщо ви знайомі з мовою програмування Ruby, то це схоже на символи:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Логічні значення `true` та `false` також є відповідними атомами:

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Назви модулів в Elixir також є атомами. `MyApp.MyModule` це валідний атом, навіть якщо такий модуль ще не був заявлений:

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Атоми також використовуються для доступу до Erlang бібліотек та модулів:

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Рядки

Рядки в Elixir кодуються в UTF-8 та об’являються за допомогою подвійних лапок:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Вони підтримують спецсимволи, такі як початок нового рядка:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir також включає складніші типи даних. 
Ми розберемо їх в подальших частинах, коли розглядатимемо [колекції](../collections/) and [функції](../functions/).

## Базові операції

### Арифметика

Elixir підтримує базові оператори `+`, `-`, `*` та `/` очевидним чином.
Важливо запам’ятати, що `/` завжди повертає число з рухомою комою:

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

Якщо потрібне цілочисельне ділення або залишок, для цього є спеціальні функції:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Логічні операції

Elixir має оператори `||`, `&&`, `!`. 
Вони підтримують будь-який тип аргументів:

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

Також є три додаткових оператори, в яких першим аргументом _повинен_ бути логічний тип (`true` and `false`):

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

Примітка: `and` і `or` в Elixir насправді відповідають `andalso` і `orelse` в Erlang.

### Порівняння

Elixir має всі стандартні оператори порівняння, до яких ми звикли: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` та `>`.

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

Для строгих порівнянь цілих чисел з числами з рухомою комою можна використовувати `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Важливою особливістю Elixir є той факт, що будь-які два типи можуть бути порівняні.
Це дуже корисно при сортуванні. Не має сенсу запам'ятовувати порядок сортування, але варто знати що він є:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Це веде до не очевидних порівнянь, яких немає в інших мовах програмування:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Інтерполяція рядків

Якщо ви програмували на Ruby, то інтерполяція в Elixir може здатися знайомою:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Об’єднання рядків

Операція об’єднання двох рядків (конкатенація) виконується за допомогою оператора `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
