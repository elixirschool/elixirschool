---
layout: page
title: Specyfikacje i typy
category: advanced
order: 9
lang: en
---

W tej lekcji przyjrzymy się składni `@spec` i `@type`. Pierwszy służy jako dodatek do składni, który pozwala na analizę kodu przez automatyczne narzędzia. Drugi pozwala na pisanie kodu, który jest bardziej czytelny i prostszy w zrozumieniu.

{% include toc.html %}

## Wstęp 

Nie jest niczym niezwykłym, chęć określenia interfejsu funkcji. Można oczywiście użyć [adnotacji @doc](../../basics/documentation), ale jest to jedynie informacja dla innych programistów, która nie jest weryfikowana w czasie kompilacji. W tym celu Elixir ma adnotację `@spec`, która pozwala na opisanie specyfikacji funkcji w sposób zrozumiały dla kompilatora.

Jednakże w niektórych przypadkach specyfikacje mogą być dość złożone. Jeżeli chcemy zredukować tę złożoność, to możemy zdefiniować własny typ. Adnotacja `@type` służy w tym właśnie celu. Z drugiej strony, Elixir pozostaje językiem dynamicznym, co oznacza, że wszystkie informacje o typach zostaną zignorowane przez kompilator. Mogą być jednak one użyte przez inne narzędzia.  

## Specyfikacje

Jeżeli masz doświadczenie w innych językach, jak Java bądź Ruby, to możesz rozumieć specyfikacje jak konstrukcje `interface`. Specyfikacja określa, jaki jest typ parametrów i wartości zwracanej. 

By zdefiniować typy wejściowe i wyjściowe, musimy umieścić dyrektywę `@spec` tuż przed definicją funkcji. Jako parametry przyjmuje ona nazwę funkcji, listę typów parametrów i po `::` typ wartości zwracanej. 

Przyjrzyjmy się temu na poniższym przykładzie:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
    [1, 2, 3]
    |> Enum.map(fn el -> el * a end)
    |> Enum.sum
end
```

Wszystko wygląda poprawnie i gdy wywołamy funkcję, to otrzymamy wynik, ale funkcja `Enum.sum` zwraca `number`, a nie `integer` jak określiliśmy w specyfikacji. To może być źródłem błędów! Możemy zatem wykorzystać narzędzia, takie jak Dialyzer, by odszukać tego typu błędy. O narzędziach porozmawiamy w innej lekcji. 
 
## Custom types

Writing specifications is nice, but sometimes our functions works with more complex data structures than simple numbers or collections. In that definition's case in `@spec` it could be hard to understand and/or change for other developers. Sometimes functions need to take in a large number of parameters or return complex data. A long parameters list is one of many potential bad smells in one's code. In object oriented-languages like Ruby or Java we could easily define classes that help us to solve this problem. Elixir hasn't classes but because is easy to extends that we could define our types.
  
Out of box Elixir contains some basic types like `integer` or `pid`. You  can find full list of available types in [documentation](http://elixir-lang.org/docs/stable/elixir/typespecs.html#types-and-their-syntax).
 
### Defining custom type
  
Let's modify our `sum_times` function and introduce some extra params:

```elixir
@spec sum_times(integer, %Examples{first: integer, last: integer}) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

We introduced a struct in `Examples` module that contains two fields `first` and `last`. That is simpler version of struct from `Range` module. We will talk about `structs` when we get into discussing [modules](../../basics/modules/#structs). Lets imagine that we need to specification with `Examples` struct in many places. It would be annoying to write long, complex specifications and could be a source of bugs. A solution to this problem is `@type`.
 
Elixir has three directives for types:

  - `@type` – simple, public type. Internal structure of type is public. 
  - `@typep` – type is private and could be used only in the module where is defined. 
  - `@opaque` – type is public, but internal structure is private. 

Let define our type:

```elixir
defmodule Examples do

    defstruct first: nil, last: nil

    @type t(first, last) :: %Examples{first: first, last: last}

    @type t :: %Examples{first: integer, last: integer}

end
```

We defined the type `t(first, last)` already, which is a representation of the struct `%Examples{first: first, last: last}`. At this point we see types could takes parameters, but we defined type `t` as well and this time it is a representation of the struct `%Examples{first: integer, last: integer}`.   

What is a difference? First one represents the struct `Examples` of which the two keys could be any type. Second one represents struct which keys are `integers`. That means code like this:
  
```elixir
@spec sum_times(integer, Examples.t) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

Is equal to code like:

```elixir
@spec sum_times(integer, Examples.t(integer, integer)) :: integer
def sum_times(a, params) do
    for i <- params.first..params.last do
        i
    end
       |> Enum.map(fn el -> el * a end)
       |> Enum.sum
       |> round
end
```

### Documentation of types

The last element that we need to talk about is how to document our types. As we know from [documentation](../../basics/documentation) lesson we have `@doc` and `@moduledoc` annotations to create documentation for functions and modules. For documenting our types we can use `@typedoc`:

```elixir
defmodule Examples do
    
    @typedoc """
        Type that represents Examples struct with :first as integer and :last as integer.
    """
    @type t :: %Examples{first: integer, last: integer}

end
```

Directive `@typedoc` is similar to `@doc` and `@moduledoc`.
