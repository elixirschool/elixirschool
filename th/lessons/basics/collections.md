---
version: 1.2.1
title: การจัดเก็บกลุ่มข้อมูล (Collections)
---

Lists, tuples, keyword lists, และ maps

{% include toc.html %}

## Lists

Lists คือ collection พื้นฐาน
ที่อาจประกอบไปด้วยข้อมูลหลาย type และ lists อาจมีข้อมูลที่ซ้ำกันอยู่ได้ด้วย

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir พัฒนา list collections เป็นแบบ linked lists หมายความว่าความเร็วในการเข้าถึงข้อมูลคือ `O(n)` ด้วยเหตุผลนี้เอง การเพิ่มข้อมูลต่อเข้าไปตอนต้นของ lists จะเร็วกว่าการเพิ่มเข้าไปต่อด้านท้าย

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### List Concatenation

การทำ list concatenation ใช้คำสั่ง `++/2`

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

หมายเหตุเกี่ยวกับ `++/2` ที่ใช้ด้านบน ใน Elixir (และภาษาอย่าง Erlang ที่ภาษา Elixir ต่อยอดมา) ฟังก์ชั่นหรือตัวดำเนินการมี 2 ส่วน คือ ชื่อที่ตั้งให้ (ในที่นี้คือ `++`) และ _arity_ ซึ่ง Arity คือส่วนที่เป็น core เมื่อเราพูดถึง Elixir (และ Erlang) มันคือจำนวนของ arguments ที่ฟังก์ชั่นนั้นรับ (ในที่คือคือ 2) Arity และชื่อที่ตั้งให้รวมกันด้วยเครื่องหมาย / เราจะพูดเกี่ยวกับเรื่องนี้มากขึ้นในภายหลัง ตอนนี้ให้พอเข้าใจความหมายของเครื่องหมายก็พอ

### List Subtraction

การนำ lists มาลบกันทำได้โดยใช้ `--/2` และเราก็สามารถลบกับค่าที่ไม่มีอยู่ได้

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

ลองดูค่าที่ซ้ำกันใน list สำหรับทุกๆ ค่าใน list ทางขวา ตอนลบ ตัวแรกที่เหมือนกันใน list ทางซ้ายมือจะถูกลบออก

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**สังเกต** list subtraction ใช้ [strict comparison](../basics/#comparison) เพื่อ match ค่าต่างๆ

### Head / Tail

ตอนที่เราใช้ list เป็นเรื่องธรรมดาที่เราจะทำงานกับส่วน head กับส่วน tail ของ list โดยส่วน head ของ list คือ element ตัวแรก ในขณะที่ส่วน tail ของ list ก็คือ element ที่เหลือใน list นั้น ภาษา Elixir มี 2 ฟังก์ชั่นที่มาช่วยตรงส่วนเหล่านี้คือ `hd` และ `tl`

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

นอกเหนือจากฟังก์ชั่นที่กล่าวมาข้างต้นแล้ว คุณสามารถใช้ [pattern matching](../pattern-matching/) และตัวดำเนินการ cons `|` เพื่อแยกส่วน head กับ tail ของ list ออกจากกัน เราจะเรียนรู้เกี่ยวกับเรื่อง pattern นี้ในบทเรียนต่อๆ ไป

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuples

Tuples คล้ายกับ lists แต่ข้อมูลใน tuple จะถูกเก็บติดๆ กันในหน่วยความจำ ทำให้การเข้าถึงข้อมูลเร็วกว่าแต่ก็จะเสียทรัพยากรไปในการแก้ไขข้อมูลค่อนข้างเยอะ โดย tuple ตัวใหม่จะเก็บข้อมูลที่ถูกคัดลอกจากข้อมูลที่ถูกแก้ไขทั้งหมดเข้าไปในหน่วยความจำ Tuples จะถูกประกาศกับ curly braces (ปีกกา)

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

เป็นเรื่องปกติสำหรับ tuples ที่จะถูกใช้ในส่วนการ return ของฟังก์ชั่น ประโยชน์ของการทำแบบนี้จะถูกอธิบายให้ชัดเจนมากขึ้นตอนที่เราไปถึงบท [pattern matching](../pattern-matching/)

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists

Keyword lists และ maps คือ associative collections ของภาษา Elixir ซึ่งใน Elixir keyword lists คือ list พิเศษที่ประกอบไปด้วย tuple ที่มี 2 elements โดย element ตัวแรกคือ atom ซึ่งทั้ง 2 elements ก็จะ share performance กับ lists

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

มี 3 ลักษณะพิเศษที่สำคัญของ keyword lists คือ

+ Keys คือ atoms
+ Keys ถูกเรียงลำดับ
+ Keys อาจจะซ้ำได้

ด้วยเหตุผลเหล่านี้ keyword lists ถูกใช้มากตอนที่ส่ง options เข้าไปที่ฟังก์ชั่น

## Maps

ใน Elixir นั้น maps คือการเก็บข้อมูลแบบ "go-to" key-value ซึ่งจะไม่เหมือนกับ keyword lists คือ keys สามารถเป็น type อะไรก็ได้ และไม่จำเป็นต้องเรียงลำดับกัน คุณประกาศ maps โดยใช้ syntax `%{}`

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

ใน ​Elixir เวอร์ชั่น 1.2 ตัวแปรสามารถถูกใช้เป็น map keys ได้

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

ถ้ามีการเพิ่มค่าซ้ำเข้าไปใน maps แล้ว maps จะนำค่านั้นไปทับค่าที่มีอยู่ก่อนหน้า

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

อย่างที่เราเห็นจากผลลัพธ์ข้างต้น จะมี syntax พิเศษสำหรับ maps ที่มีแค่ atom keys

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

นอกเหนือจากนี้ยังมี syntax พิเศษสำหรับการเข้าถึง atom keys

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

คุณสมบัติที่น่าสนใจอีกอย่างของ maps คือ maps จะมี syntax สำหรับการอัพเดทของตัวมันเอง

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```
