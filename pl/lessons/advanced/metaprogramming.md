---
layout: page
title: Metaprogramowanie
category: advanced
order: 7
lang: pl
---

Metaprogramowanie to proces tworzenia kodu, którego zadaniem jest generowanie kodu. W Elixirze mamy możliwość
rozszerzania języka tak by dynamicznie generowany kod dostosowywał się do naszych bieżących potrzeb. Najpierw
przyjrzymy się, jaka jest wewnętrzna reprezentacja kodu Elixira, następnie zobaczmy, jak można ją modyfikować, by w
końcu wykorzystać zdobytą wiedzę do rozszerzania kodu za pomocą makr.

Drobna uwaga:  metaprogramowanie jest zawiłe i powinno być stosowane tylko w ostateczności. Nadużywane wpędzi nasz w 
kłopoty ze zrozumieniem i utrzymaniem zawiłego i skomplikowanego kodu.

## Spis treści

- [Reprezentacja wewnętrzna kodu](#Reprezentacja-wewnętrzna-kodu)
- [Modyfikacja AST](#Modyfikacja-AST)
- [Makra](#macros)
	- [Makra prywatne](#Makra-prywatne)
	- [Sanacja makr](#Sanacja-makr)
	- [Spinanie](#Spinanie)

## Reprezentacja wewnętrzna kodu

Pierwszym krokiem w metaprogramowaniu jest zrozumienie, jak reprezentowana jest składnia programu. W Elixirze drzewo 
składniowe (AST) jest wewnętrznie reprezentowane w postaci zagnieżdżonych krotek. Każda z nich ma trzy elementy: 
nazwę funkcji, metadane i argumenty.

Byśmy zobaczyć tę wewnętrzną strukturę, Elixir udostępnia funkcję `quote/2`.  Używając `quote/2` możemy zamienić kod 
Elixira tak by była dla nas zrozumiała:

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
iex(6)>
```

Zauważyłeś, że pierwsze trzy wywołania nie zwróciły krotek? Istnieje pięć elementów języka, które zachowują się w ten
 sposób:

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Modyfikacja AST

Skoro wiemy już jak uzyskać wewnętrzną reprezentację kodu, to pojawia się pytanie, jak ją modyfikować? By 
wstawić do kodu nową wartość lub wyrażenie użyjemy `unquote/1`. Zostanie ono wyliczone, a następnie wstawione w 
odpowiednie miejsce AST. Zobaczmy, jak działa `unqoute/1` na poniższym przykładzie:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

W pierwszym przykładzie zmienna `denominator` jest elementem drzewa AST i została przedstawiona jako krotka opisująca
 odwołanie do zmiennej. Jednak, gdy użyjemy`unquote/1`, to w rezultacie zostanie wyznaczona wartość zmiennej 
 `denominator` i to ona zostanie wyświetlona.

## Makra

Jak już rozumiemy `quote/2` i `unquote/1`, to możemy przyjrzeć się makrom. Ważną rzeczą do zapamiętania jest to, że 
makra tak jak całe metaprogramowanie powinny być używane oszczędnie.

Najprościej mówiąc makro to rodzaj funkcji, która zwraca fragment AST, które może zostać wstawione do naszego kodu. 
Przy czym makro zostanie zamienione na nasz kod, a nie wywołane jak zwykła funkcja. Dysponując makramy mamy 
wszystkie niezbędne narzędzia, by dynamicznie dodawać kod w naszych aplikacjach.

By zdefiniować makro, użyjemy `defmacro/2`, które, jak wiele rzeczy w Elixirze, samo też jest makrem. W naszym 
przykładzie zaimplementujemy `unless` jako makro. Pamiętaj, że makro musi zwrócić fragment AST:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Zaimportujmy więc nasz moduł i pozwólmy makru działać:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

Because macros replace code in our application, we can control when and what is compiled.  An example of this can be found in the `Logger` module.  When logging is disabled no code is injected and the resulting application contains no references or function calls to logging.  This is different from other languages where there is still the overhead of a function call even when the implementation is NOP.

To demonstrate this we'll make a simple logger that can either be enabled or disabled:

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

With logging enabled our `test` function would result in code looking something like this:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

But if we disable logging the resulting code would be:

```elixir
def test do
end
```

### Makra prywatne

Though not as common, Elixir does support private macros.  A private macro is defined with `defmacrop` and can only be called from the module in which it was defined.  Private macros must be defined before the code that invokes them.

### Sanacja makr

How macros interact with the caller's context when expanded is known as macro hygiene. By default macros in Elixir are hygienic and will not conflict with our context:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

But what if we wanted to manipulate the value of `val`?  To mark a variable as being unhygienic we can use `var!/2`.  Let's update our example to include another macro utilizing `var!/2`:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

Let's compare how they interact with our context:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

By including `var!/2` in our macro we manipulated the value of `val` without passing it into our macro.  The use of non-hygienic macros should be kept to a minimum.  By including `var!/2` we increase the risk of a variable resolution conflict.

### Binding

We already covered the usefulness of `unquote/1`, but there's another way to inject values into our code: binding.  With variable binding we are able to include multiple variables in our macro and ensure they're only unquoted once, avoiding accidental revaluations. To use bound variables we need to pass a keyword list to the `bind_quoted` option in `quote/2`.

To see the benefit of `bind_quote` and to demonstrate the revaluation issue let's use an example.  We can start by creating a macro that simply outputs the expression twice:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts unquote(expr)
      IO.puts unquote(expr)
    end
  end
end
```

We'll try out our new macro by passing it the current system time.  We should expect to see it output twice:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

The times are different!  What happened?  Using `unquote/1` on the same expression multiple times results in revaluation and that can have unintended consequences.  Let's update the example to use `bind_quoted` and see what we get:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts expr
      IO.puts expr
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

With `bind_quoted` we get our expected outcome: the same time printed twice.

Now that we've covered `quote/2`, `unquote/1`, and `defmacro/2` we have all the tools necessary to extend Elixir to suit our needs.
