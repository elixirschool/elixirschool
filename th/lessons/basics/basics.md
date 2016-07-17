---
layout: page
title: ความรู้เบื้องต้น
category: basics
order: 1
lang: th
---

การติดตั้ง, ชนิดของตัวแปรพื้นฐาน และการดำเนินการ

{% include toc.html %}

## ติดตั้ง

### ลง Elixir

คู่มือการลง Elixir ของแต่ละ OS สามารถเข้าไปอ่านได้ที่ Elixir-lang.org โดยผ่านหัวข้อตรงนี้ [Installing Elixir](http://elixir-lang.org/install.html) guide.

### การใช้ REPL ของ Elixir

ใช้คำสั่ง `iex`, ซึ่งสามารถทำให้เราลองใช้คำสั่งของ Elixir ได้แบบ พิมพ์ แสดงผลลัพธ์ได้เลย

เริ่มต้น, โดยการพิมพ์ว่า `iex`:

	Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

## ชนิดของข้อมูลพื้นฐาน

### Integers (แบบจำนวนเต็ม)

```elixir
iex> 255
255
iex> 0xFF
255
```

สามารถกำหนดค่าแบบไบนารี่, เลขฐานแปด, และ เลขฐานสิบหกได้เลย ดังนี้:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Floats (เลขทศนิยม)

ภาษา Elixir, ต้องการเลขหลักอย่างน้อย 1 ตัวก่อนเครื่องหมายจุด (.); they have 64 bit double precision and support `e` for exponent numbers:

```elixir
iex> 3.41
3.41
iex> .41
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Booleans

Elixir ใช้ `true` และ `false` แทนจริงหรือเท็จ; ทุกอย่างเป็นจริงหมดยกเว้น `false` และ `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atoms

อะตอม(atom) เป็นตัวแปรที่มีชื่อเป็นค่าของตัวแปร คล้ายๆกับ Symbols ของภาษา Ruby

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

หมายเหตุ: Booleans `true` และ `false` สามารถแทนด้วยอะตอม `:true` และ `:false` ก็ได้เช่นกัน

```elixir
iex> true |> is_atom
true
iex> :true |> is_boolean
true
iex> :true === true
true
```

### Strings

สตริงในภาษา Elixir ใช้ UTF-8 และอยู่ภายใต้เครื่องหมาย ""

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

สตริงสามารถใช้ข้อความหลายบรรทัด หรือใช้ escape sequences ได้ (escape sequences เช่น \n, \t,...)

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

## การดำเนินการพื้นฐานของตัวแปร

### Arithmetic (การคำนวณ)

Elixir สามารถใช้ `+`, `-`, `*`, และ `/` แทนการบวก ลบ คูณ และหาร.  ข้อควรจำการหาร `/` ผลลัพธ์ที่ได้จะเป็นเลขทศนิยมเท่านั้น:

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

ถ้าต้องการหารจำนวนเต็มเพื่อเอาเศษ หรือ หารเพื่อเอาส่วนที่เหลือ Elixir เตรียมฟังก์ชั่นไว้ให้ใช้ ดังนี้

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean (ตรรกะ)

Elixir เตรียม `||`, `&&`, และ `!` สำหรับการดำเนินการ 'หรือ', 'และ', 'ตรงกันข้าม'. และสนับสนุนหลายๆชนิดของข้อมูล ดังนี้:

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

ถ้าต้องการใช้ and, or, not ข้างหน้าต้องเป็นตัวแปรแบบบูเลี่ยน(boolean) `true`, `false` เท่านั้น

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

### Comparison (การเปรียบเทียบ)

Elixir ใช้: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` และ `>`.

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

ถ้าต้องการเปรียบเทียบทั้งค่าและชนิดของตัวแปรให้ใช้ `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

ถ้าหากต้องการเปรียบเทียบ ตัวแปรที่ประเภทของข้อมูลแตกต่างกัน จะเรียงกันตามลำดับ ข้างล่างนี้ จากน้อยไปหามาก

```elixir
number < atom < reference < functions < port < pid < tuple < maps < list < bitstring
```

ยกตัวอย่างข้างล่างนี้ atom จะมีค่ามากกว่า ตัวเลข หรือ จำนวน ซึ่งจะไม่พบในภาษาโปรแกรมมิ่งอื่นๆ

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### String interpolation (การแก้ไขหรือแทนที่สตริง)

ถ้าคุณเคยใช้ภาษา Ruby มาก่อน, การเชื่อมสตริงของภาษา Elixir ก็คล้ายๆกัน

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### String concatenation (การเชื่อมต่อสตริง)

ใช้ `<>` เป็นตัวดำเนินการ:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
