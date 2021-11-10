%{
  version: "1.1.2",
  title: "Основи",
  excerpt: """
  Настройване, основни типове и операции.
  """
}
---

## Настройване

### Инсталация на Elixir

Инструкции за инсталиране за всяка операционна система могат да бъдат намерени на Elixir-lang.org в раздел [Installing Elixir](http://elixir-lang.org/install.html).

След като Elixir е записан, може лесно да се потвърди инсталираната версия:

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Интерактивен Режим

Elixir инсталира и `iex`, интерактивен команден ред, който ни позволява да изпълняваме код на Elixir в реално време.

За да започнем, нека изпълним `iex`:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Нека го изпробваме, с няколко прости израза:

```elixir
iex>
2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Не се притеснявайте, ако не разбирате всичко, надяваме се просто да схванете идеята.

## Основни Типове

### Прости Числа

```elixir
iex> 255
255
```

Поддръжката на числа в бинарен, осмичен и шестнайсетичен вид са вградени:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Реални Числа

При Elixir, реалните числа изискват десетична точка след поне една цифра; имат 64 битова прецизност и поддържат `e` за номера като експонента:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Булеви стойности

Elixir поддържа `true` и `false` като булеви стойности; всичко е истинно с изключение на `false` и `nil`:

```elixir
iex> true
true
iex> false
false
```

### Атоми

Атом е константа, чието име е стойност. Ако сте запознати с езика за програмиране Ruby, те са синонимни със символи (Symbols):

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Булевите `true` и `false` са също така атомите `:true` и  респективно `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Имената на модулите в Elixir са също атоми. `MyApp.MyModule` е валиден атом, въпреки, че такъв модул още не е деклариран.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Атомите се използват също за рефериране към модули от Erlang библиотеки, включително вградените.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```
### Символни низове

Символните низове в Elixir са кодирани в UTF-8 и са поставени между двойни кавички:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Символните низове поддържат нов ред и специални поредици:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir също има по-сложни типове данни. За тях, ще научим повече, когато разглеждаме Колекции и Функции.

## Основни Операции

### Аритметични

Elixir поддържа основните оператори `+`, `-`, `*`, и `/` както се очаква.  Важно е да се отбележи, че `/` винаги връща реално число:

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

Ако имате нужда от деление на прости числа или от остатъка при деление, Elixir разполага с две полезни функции да постигнете това:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Булеви

Elixir предлага булевите оператори  `||`, `&&`, и `!`. Те поддържат всякакви типове:

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

Има три допълнителни оператора, чиито първи аргумент _трябва_ да е булев (`true` и `false`):

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

### Сравнения

Elixir идва с всички оператори за сравнение, с които сме свикнали: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` и `>`.

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

За стриктни сравнения на прости числа и реални използвайте  `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Важно свойство на Elixir е че всеки два типа могат да бъдат сравнени, което е изключително полезно при сортиране. Не е нужно да запаметяваме реда на сортиране, но е важно да го имаме предвид:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Това може да доведе до някои интересни, но валидни сравнения, които може и да не намерите в други езици:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Интерполация на символни низове

Ако сте ползвали Ruby, интерполацията на симвлни низове в Elixir ще ви изглежда позната:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Конкатенация на символни низове

Конкатенацията на символни низове използва оператора `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
