%{
  version: "1.0.2",
  title: "Зіставлення зі зразком",
  excerpt: """
  Зіставлення зі зразком (pattern matching) - важлива частина мови Elixir. Вона дозволяє зіставляти прості значення, структури та навіть функції. У цьому уроці ми почнемо вивчати як користуватися цією можливістю.
  """
}
---

## Оператор зіставлення

В мові Elixir оператор `=` насправді є оператором зіставлення по аналогії зі знаком рівності в алгебрі. Його використання перетворює вираз на рівняння, і Elixir зіставляє ліву частину виразу з правою. У випадку успішного зіставлення буде повернуто розв'язане рівняння, інакше - виникне помилка:

```elixir
iex> x = 1
1
```

Найпростіше зіставлення:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Зіставлення з колекціями:

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Кортежі

iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Фіксуючий оператор

Ми вже розібрались, що оператор зіставлення робить присвоєння у тих випадках, коли ліва сторона зіставлення включає змінну. В деяких випадках переприсвоєння змінної є небажаним. У таких випадках використовується "фіксуючий оператор" `^`.

Коли ми закріпляємо змінну з його допомогою - зіставлення відбувається з наявним значенням змінної, замість присвоювання нового значення:

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Версія Elixir 1.2 додала підтримку цього оператору в ключі асоціативних масивів і функціональні розгалуження:

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

Приклад використання в функціональному розгалуженні:

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
iex> greeting
"Hello"
```

Варто зазначити, що в прикладі з `"Mornin'"` переназначення `greeting` в `"Mornin'"` відбувається тільки в рамках виконання функції. Поза функцією `greeting` все ще означає `"Hello"`.
