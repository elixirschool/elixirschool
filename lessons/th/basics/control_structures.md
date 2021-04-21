%{
  version: "1.1.1",
  title: "Control Structures",
  excerpt: """
  ในบทนี้เราจะมาดูเรื่อง control structure ที่ใช้ได้ใน Elixir กัน
  """
}
---

## `if` และ `unless`

คุณน่าจะเคยใช้งาน `if/2` กันมาก่อน และถ้าหากว่าคุณมาจากโลกของ Ruby จะต้องคุ้นเคยกับ `unless/2` อย่างแน่นอน ใน Elixir มันก็จะทำงานเหมือนกันนั่นแหละ แต่ว่ามันถูกสร้างขึ้นในรูปของ macros (ไม่ใช่จากโครงสร้างภาษา) ซึ่งคุณก็สามารถหาอ่านเพิ่มเติมว่ามันสร้างขึ้นมายังไง ได้ที่ [โมดูล Kernel](https://hexdocs.pm/elixir/Kernel.html)

ข้อควรรู้อย่างหนึ่งคือ ใน Elixir ค่าที่เป็นเท็จ มีเพียงแค่ `nil` และ boolean `false` เท่านั้น

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

การใช้ `unless/2` ก็จะคล้าย ๆ กับ `if/2` ต่างกันตรงที่มันจะทำงานเมื่อเงื่อนไขเป็นเท็จ

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

ถ้าหากว่าบางสถานการณ์คุณต้องการ match ค่า กับ pattern ต่างๆ เราก็สามารถใช้ `case/2` ได้

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

ตัวแปร `_` เป็นตัวแปรสำคัญมาก ๆ ใน `case/2` เพราะถ้าค่ามันไม่ match กับอะไรเลย มันจะทำให้เกิด error 

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

ลองมอง `_` ให้เป็น `else` เพื่อให้มัน match กับทุกสิ่งอย่างนอกเหนือจากที่กำหนดไว้

เนื่องจาก `case/2` จะทำงานอยู่บน pattern matching ดังนั้นทุก ๆ กฎเกณฑ์และข้อจำกัดของ pattern matching จะถูกนำมาใช้ ถ้าหากว่าต้องการ match เทียบกับตัวแปรที่มีค่าอยู่แล้ว คุณก็สามารถใช้ pin `^/1` operator ได้

```elixir
iex> pie = 3.14
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

feature เท่ๆ อีกอย่างของ `case/2` ก็คือมันรองรับ guard clauses

_ตัวอย่างนี้มาจาก official Elixir [Getting Started] (http://elixir-lang.org/getting-started/case-cond-and-if.html#case)_

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

ดู official doc เพิ่มเติมเกี่ยวกับ [Expression ที่ใช้ได้กับ guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## `cond`

เมื่อเราต้องการจะ match เงื่อนไขแทนที่จะเทียบกับค่า เราสามารถเปลี่ยนมาใช้ `cond/1` แทนได้ เทียบได้กับ `else if` หรือ `elsif` ในภาษาอื่น ๆ 

_ตัวอย่างนี้มาจาก official Elixir [Getting Started] (http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)_

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

เหมือนกันกับ `case/2` เจ้า `cond/1` ก็จะ error เมื่อมันไม่ match กับอะไรเลย ดังนั้นเพื่อไม่ให้เกิด error เราสามารถตั้ง condition ว่า `true` ได้

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

รูปแบบพิเศษ `with/1` จะมีประโยชน์มากเลย หากเห็นว่าอาจจะต้องใข้ case/2 ซ้อนกัน หรือในสถานการณ์ที่คุณไม่สามารถ pipe ต่อกันได้อย่างสวยงาม เจ้า `with/1` จะประกอบด้วย keyword, generator และ expression

เราจะมาจับเข่าคุยถึง generator ใน [บท list comprehensions](../comprehensions/) แต่สำหรับตอนนี้เราควรจะรู้แค่ว่ามันใช้ pattern matching เพื่อเทียบฝั่งขวาของ `<-` กับของซ้ายก็พอ

เราจะเริ่มจากตัวอย่างง่าย ๆ ของ `with/1` แล้วค่อยลงลึกไปเรื่อย ๆ กัน

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

ในสถานการณ์ที่ expression ไม่ match มันจะคืนค่าที่ไม่ match ออกมา

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

คราวนี้มาดูตัวอย่างแบบที่ไม่ใช้ `with/1` แล้วมาดูซิว่าเราจะ refactor มันยังไงได้บ้าง

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(resource, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

เมื่อเอา with/1 มาใช้ ก็มักจะจบลงด้วย code ที่เข้าใจง่ายๆ และใช้เพียงไม่กี่บรรทัด

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token) do
  important_stuff(token, full_claims)
end
```

ใน Elixir 1.3 เจ้า `with/1` ก็รองรับ `else` ด้วย

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
       true <- is_even(number) do
    IO.puts("#{number} divided by 2 is #{div(number, 2)}")
    :even
  else
    :error ->
      IO.puts("We don't have this item in map")
      :error

    _ ->
      IO.puts("It is odd")
      :odd
  end
```

มันช่วยให้เรา handle error โดยมี สิ่งที่ทำงานคล้ายกับ pattern matching แบบใน `case` ให้ใช้งาน ค่าที่ส่งเข้ามาใน `else` คือ expression แรกที่ไม่ match
