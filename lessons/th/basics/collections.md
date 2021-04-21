%{
  version: "1.2.1",
  title: "กลุ่มข้อมูล (Collections)",
  excerpt: """
  List, tuple, keyword list, และ map
  """
}
---

## Lists

list คือ collection พื้นฐานที่อาจประกอบไปด้วยข้อมูลหลาย type นอกจากนี้ list ยังสามารถเก็บข้อมูลที่ซ้ำกันได้อีกด้วย

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir พัฒนา list collection เป็นแบบ linked list หมายความว่า complexity ในการเข้าถึงข้อมูลคือ `O(n)` ด้วยเหตุผลนี้เอง การเพิ่มข้อมูลต่อเข้าไปตอนต้นของ list จะเร็วกว่าการเพิ่มเข้าไปต่อด้านท้าย

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### List Concatenation

list concatenation นั้น ใช้ operator `++/2`

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

หมายเหตุเกี่ยวกับ `++/2` ที่ใช้ด้านบน ใน Elixir (และภาษาอย่าง Erlang ที่ภาษา Elixir ต่อยอดมา) function หรือ operator มี 2 ส่วน คือ ชื่อที่ตั้งให้ (ในที่นี้คือ `++`) และ _arity_

arity คือส่วนที่เป็น core เมื่อเราพูดถึง Elixir (และ Erlang) มันคือจำนวนของ argument ที่ function นั้นรับ (ในที่นี้คือ 2) arity และชื่อที่ตั้งให้รวมกันกับเครื่องหมาย / เราจะพูดเกี่ยวกับเรื่องนี้มากขึ้นในภายหลัง ตอนนี้ให้พอเข้าใจความหมายของเครื่องหมายก็พอ

### List Subtraction

การนำ list มาลบกัน ทำได้โดยใช้ `--/2` และเราก็สามารถลบค่าที่ไม่มีอยู่ใน list ตั้งต้นได้

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

สังเกตค่าที่ซ้ำกันใน list สำหรับทุกๆ ค่าใน list ทางขวา ตอนลบ ตัวแรกที่ปรากฏใน list ทางซ้ายมือจะถูกลบออก

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**หมายเหตุ** list subtraction ใช้ [strict comparison](../basics/#การเปรียบเทียบ) เพื่อ match ค่าต่างๆ

### Head / Tail

ตอนที่เราใช้ list เป็นเรื่องธรรมดาที่เราจะทำงานกับส่วน head กับส่วน tail ของ list โดยส่วน head ของ list คือ element ตัวแรก ในขณะที่ส่วน tail ของ list ก็คือ element ที่เหลือใน list นั้น ภาษา Elixir มี 2 function ที่มาช่วยตรงส่วนเหล่านี้คือ `hd` และ `tl`

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

นอกเหนือจาก function ที่กล่าวมาข้างต้นแล้ว เราสามารถใช้ [pattern matching](../pattern-matching/) และ cons operator `|` เพื่อแยกส่วน head กับ tail ของ list ออกจากกัน เราจะเรียนรู้เกี่ยวกับเรื่อง pattern นี้ในบทเรียนต่อๆ ไป

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuples

tuple คล้ายกับ list แต่ข้อมูลใน tuple จะถูกเก็บติดๆ กันในหน่วยความจำ ทำให้การเข้าถึงข้อมูลเร็วกว่าแต่ก็จะเสียทรัพยากรไปในการแก้ไขข้อมูลค่อนข้างเยอะ เนื่องจากจะต้องคัดลอก tuple ใหม่ทั้งหมดเข้าไปในหน่วยความจำ

tuple ประกาศได้ด้วยเครื่องหมายปีกกา

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

เป็นเรื่องปกติสำหรับ tuple ที่จะถูกใช้ในส่วนการ return ของ function ประโยชน์ของการใช้งานในลักษณะนี้จะถูกอธิบายให้ชัดเจนมากขึ้นตอนที่เราไปถึงบท [pattern matching](../pattern-matching/)

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists

keyword list และ map คือ associative collection ของภาษา Elixir ซึ่งใน Elixir keyword list คือ list พิเศษที่ประกอบไปด้วย tuple ที่มี 2 element โดย element ตัวแรกคือ atom

keyword list นั้นมี performance แบบเดียวกับ list

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

3 ลักษณะพิเศษที่สำคัญของ keyword list คือ

+ key คือ atom
+ key ถูกเรียงลำดับ
+ key อาจจะซ้ำได้

ด้วยเหตุผลเหล่านี้ keyword list จึงถูกนิยมใช้สำหรับส่ง option เข้าไปที่ function

## Maps

ใน Elixir นั้น map คือการเก็บข้อมูลแบบ "go-to" key-value ซึ่งจะไม่เหมือนกับ keyword list คือ key สามารถเป็น type อะไรก็ได้ และไม่จำเป็นต้องเรียงลำดับกัน

เราสามารถประกาศ map ได้โดยใช้ syntax `%{}`

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

ใน ​Elixir เวอร์ชั่น 1.2 ตัวแปรสามารถถูกใช้เป็น key ของ map ได้

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

ถ้ามีการเพิ่มค่าซ้ำเข้าไปใน map แล้ว map จะนำค่านั้นไปทับค่าที่มีอยู่ก่อนหน้า

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

อย่างที่เราเห็นจากผลลัพธ์ข้างต้น จะมี syntax พิเศษสำหรับ map ที่มีแต่ key ที่เป็น atom

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

นอกเหนือจากนี้ยังมี syntax พิเศษสำหรับการเข้าถึง key ที่เป็น atom อีกด้วย

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

คุณสมบัติที่น่าสนใจอีกอย่างของ map คือ map มี syntax ของตัวเองสำหรับการอัพเดต

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```
