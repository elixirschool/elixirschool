%{
  version: "1.1.2",
  title: "พื้นฐาน",
  excerpt: """
  เริ่มต้น, data type และ operation พื้นฐาน
  """
}
---

## เริ่มต้น

### ติดตั้ง Elixir

ขั้นตอนการติดตั้งสำหรับแต่ละระบบปฏิบัติการสามารถเข้าไปดูในเว็บไซต์ elixir-lang.org ในส่วนของแนวทางการ[ติดตั้ง Elixir](http://elixir-lang.org/install.html)

หลังจากติดตั้งสำเร็จ เราสามารถยืนยันเวอร์ชันที่ติดตั้งได้ง่ายๆ ดังนี้

    $ elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### ลองเล่นกับ Interactive Mode

Elixir มาพร้อมกับ IEx ซึ่งเป็น interactive shell ที่เปิดโอกาสให้เราสามารถประมวลผลนิพจน์ (expression) ของภาษา Elixir ได้อย่างต่อเนื่อง

มาเริ่มต้นกันด้วยการรัน `iex`

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

เอาล่ะ! ทีนี้ลองมาเริ่มจากนิพจน์ง่ายๆ กัน

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

ไม่ต้องกังวลไปถ้ารู้สึกว่ายังไม่เข้าใจความหมายของทุกนิพจน์ แต่หวังว่าจะเข้าใจในแนวคิดของมันนะ

## Data Type พื้นฐาน

### Integers

```elixir
iex> 255
255
```

รองรับเลขฐาน 2 (binary), 8 (octal) และ 16 (hexadecimal) ด้วยในตัว

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Floats

ใน Elixir นั้น เลขทศนิยมต้องใส่จุดทศนิยมหลังตัวเลขอย่างน้อย 1 หลัก รูปแบบที่ใช้เก็บทศนิยมเป็นแบบ 64-bit double precision และรองรับ `e` สำหรับค่า exponential (ใช้เลขฐานมายกกำลัง เช่น 1.0e-10 มี 1.0 เป็นฐาน 10 ก็จะเป็น 1.0 * 10^-10 เป็นต้น)

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Booleans

Elixir นั้นใช้ `true` และ `false` โดยนอกจาก `false` กับ `nil` แล้ว ค่าอื่นๆ นับว่ามีค่าเป็นจริง (truthy)

```elixir
iex> true
true
iex> false
false
```

### Atoms

atom เป็นค่าคงที่ที่มีค่าเป็นชื่อของตัวมันเอง ถ้าเขียน Ruby มาก่อนล่ะก็ มันก็เหมือนกับ symbol นั่นแหละ

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

ซึ่งจริงๆ แล้ว boolean `true` และ `false` นั้นก็เป็น atom `:true` และ `:false` ตามลำดับ

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

ชื่อของ module ใน Elixir ก็เป็น atom อีกเช่นกัน เช่น `MyApp.MyModule` เป็น atom แม้ว่าจะไม่เคยประกาศ module นี้มาก่อนเลยก็ตาม

```elixir
iex> is_atom(MyApp.MyModule)
true
```

นอกจากนี้ atom ยังถูกใช้ในการอ้างอิงถึง module ใน library ที่เขียนด้วย Erlang รวมถึง module ใน Erlang เองด้วย

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Strings

string ใน Elixir นั้นเข้ารหัสด้วย UTF-8 และใช้อัญประกาศคู่ (double quote) ในการประกาศ

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

string รองรับการขึ้นบรรทัดใหม่ และ escape sequences

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir ยังมี data type ที่ซับซ้อนกว่าที่กล่าวมาข้างต้น เราจะได้เรียนเพิ่มเติมตอนที่ไปถึงเรื่องของ [collections](../collections/) และ [functions](../functions/)

## Operation พื้นฐาน

### Arithmetic

คงพอจะเดากันออกว่า Elixir มี `+`, `-`, `*` และ `/` ให้ใช้ สิ่งหนึ่งที่อยากให้จำไว้คือ `/` จะคืนค่าเป็น float เสมอ

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

หากว่าอยากได้ผลหารเป็นจำนวนเต็ม หรือหารเอาเศษ Elixir มีฟังก์ชัน `div` และ `rem` (rem น่าจะมาจาก division remainder คือเศษจากการหาร) ให้ใช้งานตามลำดับ

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Boolean

Elixir มี `||`, `&&` และ `!` เป็น boolean operators ซึ่งสามารถใช้ได้กับทุกๆ type อย่างที่กล่าวไปแล้วว่า นอกจาก `nil` และ `false` แล้ว ทุกๆ ค่าจากมุมมองของ boolean จะมีค่าเป็นจริง (truthy)

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

นอกจากนี้ยังมี operator เพิ่มเติม ที่ argument ตัวแรกต้องเป็น boolean (`true` หรือ `false`) เสมอ

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

### การเปรียบเทียบ

Elixir มาพร้อมกับตัวเปรียบเทียบที่เราคุ้นเคย ซึ่งก็คือ `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<`, และ `>`.

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

สำหรับการเปรียบเทียบที่เข้มงวดระหว่าง integers กับ floats ให้ใช้ `===`

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

คุณสมบัติอย่างหนึ่งที่สำคัญของ Elixir คือ type ที่ต่างกัน สามารถนำมาเปรียบเทียบกันได้ ซึ่งมีประโยชน์โดยเฉพาะในการเรียงลำดับ
ไม่จำเป็นต้องท่องจำลำดับก็ได้ แต่อยากให้รู้เอาไว้ว่ามันมีตัวตนอยู่นะ

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

ซึ่งลำดับข้างต้นทำให้มีการเปรียบเทียบที่น่าสนใจเกิดขึ้น ซึ่งคงจะไม่เจอในภาษาอื่นๆ

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### การสอดแทรก string

หากเคยเขียน Ruby มาก่อน ก็คงจะรู้สึกว่าการสอดแทรก string (string interpolation) ใน Elixir นั้นหน้าตาคุ้นๆ

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### การต่อ string

เราสามารถนำ string มาต่อกันได้โดยใช้เครื่องหมาย `<>`

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
