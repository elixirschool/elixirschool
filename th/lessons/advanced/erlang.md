---
version: 1.0.1
title: การใช้งานร่วมกับ Erlang
---

หนึ่งในประโยชน์ของการสร้างบน Erlang VM (BEAM) คือมี library ให้เลือกใช้มากมายก่ายกอง ความสามารถในการทำงานร่วมกับ Erlang ทำให้เราเราสามารถใช้ library และ Erlang standard lib ได้ใน code Elixir 

ในบทนี้เราจะมาดูวิธีการใช้งาน funtion ใน standard lib ไปพร้อมๆ กับ แพ็คเกจ third-party ของ Erlang

{% include toc.html %}

## Standard Library

standard library เสริมของ ของ Erlang สามารถใช้งานได้ทุกที่ใน code Elixir ของ application เรา โมดูล Erlang จะอยู่ในรูปของ atom แบบ lowercase เช่น `:os` และ `:timer`

ลองใช้ `:timer.tc` เพื่อดูเวลาการทำงานของ function ที่ใช้

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

ดู list ของ module ที่ใช้ได้ทั้งหมดที่ [Erlang Reference Manual](http://erlang.org/doc/apps/stdlib/)

## Erlang Packages

ในบทก่อน เราได้พูดถึง Mix และการจัดการกับ dependency ไปแล้ว library ของ Erlang ก็ทำงานเช่นเดียวกัน ในสถานการณ์ที่ library ขอ Erlang ไม่ได้อยู่ใน [Hex](https://hex.pm) คุณสามารถดึงมันจาก git repository แทนได้

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

คราวนี้เราก็สามารถใช้งาน library Erlang ได้แล้ว

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## Notable Differences

ตอนนี้เรารู้แล้วว่าเราจะใช้ Erlang ยังไง เราควรจะรู้ลูกเล่นอื่นๆ ที่มาพร้อมกับ Erlang interoperability

### Atoms

atom ของ Erlang ดูเหมือนคล้ายกับ Elixir ต่างกันตรงที่มันไม่มี colon (`:`) มันจะอยู่ในรูปของอักษร lowercase และ underscore

Elixir:

```elixir
:example
```

Erlang:

```erlang
example.
```

### Strings

ใน Elixir เมื่อเราพูดถึง string เราจะหมายถึง UTF-8 encoded binaries แต่ใน Erlang string ยังใช้ double quote แต่จะหมายถึง char list แทน

Elixir:

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

เรื่องสำคัญที่ควรจำคือ library ของ Erlang เก่าๆ หลายตัวที่ไม่ได้รองรับ binary ดังนั้นเราต้องแปลง string ของ Elixir ให้กลายเป็น chat list ก่อน และแน่นอนว่าต้องขอบคุณที่มีวิธีง่ายๆ ในการทำอย่างนั้น นั่นคือ function `to_charlist/1`:

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2
    (stdlib) string.erl:380: :string.strip_left("Hello World", 32)
    (stdlib) string.erl:378: :string.strip/3
    (stdlib) string.erl:316: :string.words/2

iex> "Hello World" |> to_charlist |> :string.words
2
```

### Variables

Elixir:

```elixir
iex> x = 10
10

iex> x1 = x + 10
20
```

Erlang:

```erlang
1> X = 10.
10

2> X1 = X + 1.
11
```

แค่นั้นเลย การใช้ประโยชน์ Erlang ในแอพ Elixir ของเรา ช่างง่ายและยังเพิ่มจำนวน library ให้เราใช้งานได้อย่างมีประสิทธิภาพอีกด้วย
