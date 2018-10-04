---
version: 1.3.0
title: Enum
---

ชุดของ algorithm สำหรับใช้งานกับ `Enum`

{% include toc.html %}

## Enum

module `Enum` มีมากกว่า 70 function ให้ใช้งาน ที่น่าสนใจคือ colllection ทั้งหมดนอกจาก tuple ที่เราได้เรียนกันมาใน [บทที่แล้ว](../collections/) ล้วนแล้วแต่เป็น `Enum`

บทนี้จะครอบคลุมเพียงแค่ function บางส่วน แต่คุณก็สามารถไปศึกษาเพิ่มได้เอง เอาล่ะ มาทำลองเล่นใน IEx กันสักหน่อยดีกว่า

```elixir
iex> Enum.__info__(:functions) |> Enum.each(fn({function, arity}) ->
...>   IO.puts "#{function}/#{arity}"
...> end)
all?/1
all?/2
any?/1
any?/2
at/2
at/3
...
```

จากที่ลองจะเห็นว่ามี function มากมายให้เราใช้งานจริง ๆ  `Enum` นับเป็น core ของการเขียนโปรแกรมแบบ functional แล้วมันก็มีประโยชน์มาก ๆ เลยทีเดียว 

หากเราใช้มันร่วมกับสิ่งเยี่ยมยอดอื่น ๆ ของ Elixir มันจะทำให้ developer ทำงานได้อย่างมีประสิทธิภาพมากเลยทีเดียว

สำหรับรายชื่อ function ทั้งหมด สามารถเข้าไปอ่านเพิ่มได้ที่ [`Enum`](https://hexdocs.pm/elixir/Enum.html) สำหรับ lazy enumeration ใช้โมดูล [`Stream`](https://hexdocs.pm/elixir/Stream.html).


### all?

เมื่อเราใช้ `all?/2` กับ `Enum` จำนวนมาก เราสามารถใช้งาน function กับ item ทั้งหมดของ collection ได้ โดยจะตอบ `true` เมื่อ item ใน collection ทั้งหมดเป็น `true` นอกจากนั้นจะเป็น `false`

```elixir
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 3 end)
false
iex> Enum.all?(["foo", "bar", "hello"], fn(s) -> String.length(s) > 1 end)
true
```

### any?

`any?/2` จะคืนค่า `true` ถ้ามีตัวใดตัวนึงใน collection เป็น `true`

```elixir
iex> Enum.any?(["foo", "bar", "hello"], fn(s) -> String.length(s) == 5 end)
true
```

### chunk_every

ถ้าคุณต้องการแบ่ง collection เป็นกลุ่มเล็ก ๆ `chunk_every/2` เป็น function ที่คุณกำลังตามหา

```elixir
iex> Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)
[[1, 2], [3, 4], [5, 6]]
```

มีตัวเลือกเล็กน้อยสำหรับ `chunk_every/4` แต่เราจะไม่พูดถึงมันตรงนี้ ดูเพิ่มเติมที่ [`the official documentation of this function`](https://hexdocs.pm/elixir/Enum.html#chunk_every/4)

### chunk_by

ถ้าเราต้องการจับกลุ่ม collection ของเราด้วยค่าอื่นนอกเหนือจาก size ของมัน เราสามารถใช้ function `chunk_by/2` ได้. มันรับ enumerable และ function เข้าไป และคืนค่าเมื่อ function สร้างกลุ่มใหม่ แล้วเริ่มทำกับตัวต่อไป

```elixir
iex> Enum.chunk_by(["one", "two", "three", "four", "five"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"]]
iex> Enum.chunk_by(["one", "two", "three", "four", "five", "six"], fn(x) -> String.length(x) end)
[["one", "two"], ["three"], ["four", "five"], ["six"]]
```

### map_every

บางครั้งการดึงค่าเป็นก้อน ๆ จาก collection ไม่เพียงพอกับสิ่งที่เราต้องการ ในสถานการณ์นี้ `map_every/3` มีประโยชน์มากในการเข้าถึง item ทุก ๆ `nth` ครั้ง เริ่มโดยเข้าถึงตัวแรกสุดก่อน

```elixir
# ใช้ function ทุก ๆ 3 ค่า
iex> Enum.map_every([1, 2, 3, 4, 5, 6, 7, 8], 3, fn x -> x + 1000 end)
[1001, 2, 3, 1004, 5, 6, 1007, 8]
```

### each

มันอาจจะจำเป็นที่จะใช้ค่าแต่ละตัวใน collection โดยไม่สร้างค่าใหม่ สำหรับสถานการณ์นี้เราสามารถใช้ `each/2` ได้

```elixir
iex> Enum.each(["one", "two", "three"], fn(s) -> IO.puts(s) end)
one
two
three
:ok
```

__หมายเหตุ__: function `each/2` จะคืนค่า atom `:ok`

### map

เราสามารถใช้ function กับแต่ละ item เพื่อสร้างเป็น collection ใหม่ได้ด้วย function `map/2`

```elixir
iex> Enum.map([0, 1, 2, 3], fn(x) -> x - 1 end)
[-1, 0, 1, 2]
```

### min

`min/1` หาค่าน้อยที่สุดใน collection

```elixir
iex> Enum.min([5, 3, 0, -1])
-1
```

`min/2` ทำเหมือนกัน แต่ถ้า enumerable เป็นค่าว่างมันจะคืนค่าของ function ที่เราใส่เข้าไปแทน

```elixir
iex> Enum.min([], fn -> :foo end)
:foo
```

### max

`max/1` คืนค่ามากที่สุดของ collection:

```elixir
iex> Enum.max([5, 3, 0, -1])
5
```

`max/2` กลายเป็น `max/1` ถ้า enumerable มีค่า เช่นเดียวกันกับ `min/2` ที่จะกลายเป็น `min/1`:

```elixir
Enum.max([], fn -> :bar end)
:bar
```

### reduce

ด้วย function  `reduce/3` ทำให้เราสามารถรวบ collection ให้เหลือเพียงค่าเดียวได้ การที่จะรวบ collection เราสามารถส่ง accumulator (`10` ในตัวอย่างด้านล่างนี้) เข้าไปใน function ถ้าไม่ได้กำหนด accumulator มันจะใช้ตัวแรกเป็น accumulator แทน

```elixir
iex> Enum.reduce([1, 2, 3], 10, fn(x, acc) -> x + acc end)
16

iex> Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)
6

iex> Enum.reduce(["a","b","c"], "1", fn(x,acc)-> x <> acc end)
"cba1"
```

### sort

การ sort collection สามารถทำได้ง่ายนิดเดียวด้วย 2 function ที่ Elixir มีไว้ให้ใช้

`sort/1` ใช้ term ของ Erlang ในการจัดลำดับ
uses Erlang's term ordering to determine the sorted order:

```elixir
iex> Enum.sort([5, 6, 1, 3, -1, 4])
[-1, 1, 3, 4, 5, 6]

iex> Enum.sort([:foo, "bar", Enum, -1, 4])
[-1, 4, Enum, :foo, "bar"]
```

เราสามารถใช้ sort function ที่เราสร้างขึ้นมาเองได้ใน `sort/2` 

```elixir
# ใช้ function
iex> Enum.sort([%{:val => 4}, %{:val => 1}], fn(x, y) -> x[:val] > y[:val] end)
[%{val: 4}, %{val: 1}]

# โดยไม่ใช้ function
iex> Enum.sort([%{:count => 4}, %{:count => 1}])
[%{count: 1}, %{count: 4}]
```

### uniq_by

เราสามารถใช้ `uniq_by/2` เพื่อลบค่าซ้ำใน enumerables ได้:

```elixir
iex> Enum.uniq_by([1, 2, 3, 2, 1, 1, 1, 1, 1], fn x -> x end)
[1, 2, 3]
```
