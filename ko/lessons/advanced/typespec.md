---
layout: page
title: Specifications and types
category: advanced
order: 9
lang: ko
---

이번 수업에서 `@spec`과 `@type` 구문을 공부해보도록 하겠습니다. `@spec`이 문서화 도구가 코드를 분석해서 문서화에 힘을 실어주는 구문이라면, `@type`은 더 읽고 이해하기 쉬운 코드를 쓸 수 있게 도와주는 구문입니다.

{% include toc.html %}

## 소개

It's not uncommon you would like to describe interface of your function. Of course You can use [@doc annotation](/ko/lessons/basic/documentation), but it is only information for other developers that is not checked in compilation time. For this purpose Elixir has `@spec` annotation to describe specification of function that will be checked by compiler.

However in some cases specification is going to be quite big and complicated. If you would like to reduce complexity, you want to introduce custom type definition. Elixir has `@type` annotation for that. In the other hand, Elixir is still dynamic language. That means all information about type will be ignored by compiler, but could be used by other tools.   

## 스펙

If you have experience with Java or Ruby you could think about specification as an `interface`. Specification defines what should be type of function parameters and return value.

To define input and output types we use `@spec` directive placed right before function definition and taking as a `params` name of function, list of parameter types, and after `::` type of return value.  

Let's take a look at example:

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
    [1, 2, 3]
    |> Enum.map(fn el -> el * a end)
    |> Enum.sum
end
```

Everything looks ok and when we call valid result will be return, but function `Enum.sum` returns `number` not `integer` as we expected in `@spec`. It could be source of bugs! There are tools like Dialyzer to static analysis of code that helps us to find this type of bugs. We will talk about them in another lesson.
 
## 커스텀 타입

Writing specifications is nice, but sometimes our functions works with more complex data structures than simple numbers or collections. In that definition's case in `@spec` it could be very hard to understand and/or change for other developers. Sometimes functions need to take in a large number of parameters or return complex data. A long parameters list is one of many potential bad smells in one's code. In object oriented-languages like Ruby or Java we could easily define classes that help us to solve this problem. Elixir hasn't classes but because is easy to extends that we could define our types.
  
Out of box Elixir contains some basic types like `integer` or `pid`. You  can find full list of available types in [documentation](http://elixir-lang.org/docs/stable/elixir/typespecs.html#types-and-their-syntax).
 
### 커스텀 타입 정의하기
  
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

We introduced a struct in `Examples` module that contains two fields `first` and `last`. That is simpler version of struct from `Range` module. We will talk about `structs` when we get into discussing [modules](lessons/basics/modules/#structs). Lets imagine that we need to specification with `Examples` struct in many places. It would be very annoying to write long, complex specifications and could be a source of bugs. A solution to this problem is `@type`.
 
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

### 타입 문서화하기

The last element that we need to talk about is how to document our types. As we know from [documentation](/lessons/basic/documentation) lesson we have `@doc` and `@moduledoc` annotations to create documentation for functions and modules. For documenting our types we can use `@typedoc`:

```elixir
defmodule Examples do
    
    @typedoc """
        Type that represents Examples struct with :first as integer and :last as integer.
    """
    @type t :: %Examples{first: integer, last: integer}

end
```

Directive `@typedoc` is similar to `@doc` and `@moduledoc`.
