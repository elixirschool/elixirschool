%{
  version: "1.0.0",
  title: "Mnesia",
  excerpt: """
  Mnesia เป็นระบบจัดการ distributed database ที่ทำงานแบบ real-time
  """
}
---

## ภาพรวม

Mnesia เป็น database management system (DBMS) ที่มาพร้อมกับ Erland runtime system ซึ่งเราก็สามารถใช้มันได้กับ Elixir ทันที *relational and object hybrid data model* เป็นสิ่งที่ทำให้ Mnesia เหมาะกับการสร้างแอพแบบ distributed ในทุกระดับ

## เมื่อไหร่ที่ควรใช้

เมื่อไหร่ที่ควรเลืิอกใช้ส่วนต่างๆ ของเทคโนโลยี เป็นสิ่งที่ทำให้เราสับสนมาตลอด ถ้าคุณตอบว่า "ใช่" สำหรับคำถามต่อไปนี้ นั่นแหละเป็นตัววัดที่ดีว่าควรจะใช้ Mnesia แทน ETS หรือ DETS

  - คุณต้องการ roll back transaction ไหม?
  - คุณต้องการ syntax ที่ใช้ง่ายสำหรับการอ่านและเขียนข้อมูลไหม?
  - คุณต้องการจะเก็บข้อมูลระหว่าง node หรือมากกว่า 1 node ไหม?
  - คุณต้องการตัวเลือกว่าจะเก็บข้อมูลไว้ที่ไหนไหม (RAM หรือ disk)?

## Schema

เนื่องจาก Mnesia เป็นส่วนหนึ่งของ Erlang core มากกว่า Elixir เราจึงสามารถเข้าใช้งานมันด้วย colon syntax (ดูบท [Erlang Interoperability](../../advanced/erlang/)):

```elixir

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

สำหรับบทนี้ เราจะมาดูกันต่อเกี่ยวกับการใช้งาน Mnesia API `Mnesia.create_schema/1` จะสร้าง schema ว่างๆ ขึ้นมาใหม่ แล้วส่งไปให้ Node List ณ จุดนี้ เราจะส่งระหว่าง node ที่อยู่ใน IEx session ของเรา

## Nodes

หลังจากที่เรา run คำสั่ง `Mnesia.create_schema([node()])` ผ่าน IEx คุณควรจะเห็น folder ชื่อ **Mnesia.nonode@nohost** หรืออะไรที่คล้ายๆ กัน ใน directory ที่คุณใช้งานอยู่ คุณอาจจะสงสัยว่า **nonode@nohost**  คืออะไร เพราะเราไม่เคยเห็นมันมาก่อน ดังนั้น มาดูสักหน่อย

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

เมื่อเราส่งค่า `--help` option เข้าไปใน IEx ผ่าน command line เราก็จะเห็น option ทั้งหมดที่เราใช้งานได้ เราจะเห็น option `--name` และ `--sname` สำหรับการกำหนดข้อมูลให้กับ node node คือ Erlang virtual machine ที่ทำการดูแลการสื่อสาร, garbage collection, process scheduling, memory และอีกมากมาย โดย node จะมีชื่อ **nonode@nohost** ง่ายๆ โดย default

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

อย่างที่เราได้เห็นกัน node ที่เรากำลัง run คือ atom ชื่อ `:"learner@elixirschool.com"` ถ้าเราสั่ง run `Mnesia.create_schema([node()])` อีกครั้ง เราจะเห็นว่ามันจะสร้าง folder ใหม่ขึ้นมาชื่อ **Mnesia.learner@elixirschool.com** จุดประสงค์ของมันง่ายนิดเดียว นั่นคือ node ใน Erlang จะเชื่อมต่อกับ node  อื่นๆ เพื่อ share (distribute) ข้อมูลและ resources กันและกัน. และมันไม่ได้จำกัดอยู่แค่ภายในเครื่องเดียวกัน มันสามารถสื่อสารกันผ่าน LAN หรือ internet

## Starting Mnesia

ตอนนี้เรามีพื้นฐานเกี่ยวกับการ set up database แล้ว เราพร้อมแล้วที่จะใช้งาน Mnesia DBMS ด้วยคำสั่ง ```Mnesia.start/0```

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

มันคุ้มค่าถ้าจะจดจำไว้ว่าเมื่อสั่งให้มัน run บน distrubuted system ที่มี node มากกว่า 2 node ขึ้นไป, function `Mnesia.start/1` จะต้องรันในทุก node ที่เกี่ยวข้อง

## Creating Tables

function `Mnesia.create_table/2` ใช้สำหรับสร้างตารางภายใน database ของเรา คำสั่งด้านล่างนี้เราได้ทำการสร้างตารางชื่อ `Person` และส่ง ketword list ที่ใช้กำหนด schema ของตารางเข้าไป

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

เราได้กำหนด column โดยใช้ atom `:id`, `:name`, และ `:job` เมื่อเรารัน `Mnesia.create_table/2` มันจะคืนค่าใดค่าหนึ่งต่อไปนี้ออกมา

 - `{:atomic, :ok}` ถ้า function ทำงานสำเร็จ
 - `{:aborted, Reason}` ถ้า function ทำงานล้มเหลว

โดยปกติแล้ว ถ้าตารางได้ถูกสร้างไว้แล้ว Reason จะเป็น `{:already_exists, table}` ดังนั้นถ้าเราพยายามจะสร้างตารางขึ้นมาเป็นครั้งที่สอง เราจะได้ค่า 

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## The Dirty Way

อันดับแรก เราจะมาดู dirty way ของการอ่านและเขียนตาราง Mnesia กัน สิ่งเหล่านี้ควรจะหลีกเลี่ยงเนื่องจากผลลัพธ์อาจจะไม่สำเร็จ แต่มันจะช่วยให้เราได้เรียนรู้และรู้สึกคุ้นเคยกับการทำงานของ Mnesia มากขึ้น เริ่มจากลองเพิ่ม entry เข้าไปในตาราง **Person**

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...และ เอาค่าออกมาจาก entry ด้วย `Mnesia.dirty_read/1`:

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

ถ้าเราพยายามจะดึงค่า record ที่ไม่เคยมี Mnesia จะคืน empty list ออกมาให้

## Transactions

ปกติแล้วเราจะใช้ **transaction** เพื่อ encapsulate การเขียนหรืออ่านกับ database ของเรา Transaction เป็นส่วนสำคัญของการออกแบบ fault-tolerant, highly distributed systems *Transaction ของ Mnesia มีกลไกที่ทำให้ database operation ทำงานตามลำดับแบบ functional block* เริ่มจากสร้าง anonymous function ในที่นี้คือ `data_to_write` และส่งเข้าไปใน `Mnesia.transaction`

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
จากข้อความ transaction ที่ได้ เราสามารถสมมติได้ว่าเราได้ทำการเขียนข้อมูลลงในตาราง `Person` แล้ว คราวนี้ลองใช้ transaction ในการอ่านค่าจาก database เพื่อให้แน่ใจว่ามีเขียนแล้ว โดยเราจะใช้ `Mnesia.read/1` เพื่ออ่านค่าจาก database แต่จะใช้ในรูปของ anonymous function

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

จำไว้ว่าถ้าคุณต้องการจะ update ข้อมูล คุณจะต้องเรียกใช้ `Mnesia.write/1` ด้วย key เดียวกันกับ record ที่มีอยู่ ดังนั้นถ้าจะ update record สำหรับ Hans คุณก็แค่

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## Using indices

Mnesia รองรับการทำงานกับ index สำหรับ columnที่ไม่มี key และข้อมูลจะถูก query ตาม index นั้นๆ ดังนั้นเราสามารถเพิ่ม index ให้กับ column `:job` ในตาราง `Person` ได้

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

ผลลัพธ์ที่ได้จะคล้ายกันกับค่าที่คืนมาจาก `Mnesia.create_table/2`:

 - `{:atomic, :ok}` ถ้า function ทำงานสำเร็จ
 - `{:aborted, Reason}` ถ้า function ทำงานล้มเหลว

โดยปกติแล้ว ถ้ามี index อยู่แล้ว Reason จะเป็น `{:already_exists, table, attribute_index}` ดังนั้นถ้าเราพยายามจะสร้าง index เป็นครั้งที่สอง เราจะได้ว่า

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

เมื่อได้สร้าง index แล้ว เราสามารถอ่านและเอา list ออกมาได้

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Match and select

Mnesia รองรับการ query แบบซับซ้อน เพื่อที่จะดึงข้อมูลออกมาจากตารางในรูปของ matching และ function การเลือกแบบเฉพาะเจาะจง

function `Mnesia.match_object/1` จะคืนค่า record ทั้งหมดที่ match กับ pattern ที่กำหนดให้ ถ้ามี columnไหนในตารางมี index มันก็จะใช้ index เพื่อทำให้การ query มีประสิทธิภาพมากขึ้น ใช้ atom แบบพิเศษ `:_` เพื่อระบุ columnที่ไม่ต้องการใช้ในการ match

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

function `Mnesia.select/2` อนุญาตให้ระบุ custom query โดยใช้ operator หรือ function ใดๆ ใน Elixir (หรือ Erlang ที่ใช้ได้) ลองดูตัวอย่างของการเอา row ทั้งหมดที่มี key มากกว่า 3:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

มาแกะดูกันดีกว่า attribute แรกคือชื่อตาราง `Person` attribute ที่สองคือ 3 ค่าในรูปแบบของ `{match, [guard], [result]}`:

- `match` คือสิ่งเดียวกับที่เราส่งผ่าน function `Mnesia.match_object/1`; อย่างไรก็ตามจงจำไว้ว่า atom แบบพิเศษ​ `:"$n"` ใช้สำหรับระบุตำแหน่งของ parameter ที่จะใช้ในส่วนที่เหลือของการ query
- `guard` list คือ list ของ tuple ที่ใช้ในการระบุ function guard ที่จะใช้ในการ query, ในที่นี้คือ `:>` (มากกว่า) function แบบ built in ตามมาด้วย parameter สำหรับบอกตำแหน่ง column `:"$1"` และค่าคงที่ `3` เป็น attribute
- `result` list คือ list ของ field ที่จะให้คืนออกมาจากการ query ในรูปแบบของตำแหน่ง parameter, atom แบบพิเศษ `:"$$"` ใช้สำหรับอ้างถึงทุก field ดังนั้นคุณอาจจะใช้ `[:"$1", :"$2"]` เพื่อเอาค่าของ 2 ตัวแรกใน field หรือ `[:"$$"]` เพื่อเอาทุกค่าก็ได้

รายละเอียดเพิ่มเติม ดูที่ [the Erlang Mnesia documentation for select/2](http://erlang.org/doc/man/mnesia.html#select-2).

## Data initialization and migration

ในทุกๆ solution ของ software จะต้องมีช่วงเวลาที่จะต้อง upgrade หรือ migrate ข้อมูลที่อยู่ใน database ของคุณ ยกตัวอย่างเช่น เราอาจจะอยากเพิ่ม column `:age` เข้าไปในตาราง `Person` ใน v2 ของแอพ เราไม่สามารถสร้างตาราง `Person` อีกครั้งได้ แต่เราสามารถเปลี่ยนมันได้ สำหรับการเปลี่ยนรูปแบบตารางเราจะต้องรู้ว่าตอนไหนควรจะเปลี่ยน โดยเราสามารถทำได้ตอนที่เราสร้างตารางแล้ว นั่นคือการใช้ function `Mnesia.table_info/2` เพื่อดูโครงสร้างปัจจุบันของตารางและใช้ function `Mnesia.transform_table/3` เพื่อแปลงให้เป็นโครงสร้างใหม่

code ด้านล่างจะทำสิ่งนี้ด้วยการใช้ logic ต่อไปนี้

* สร้างตารางสำหรับ attribute ใน v2: `[:id, :name, :job, :age]`
* Handle ผลลัพธ์ของการสร้างตาราง
    * `{:atomic, :ok}`: สร้างตารางเริ่มต้นโดยสร้าง index  ให้กับ `:job` และ `:age`
    * `{:aborted, {:already_exists, Person}}`: ตรวจสอบดู attribute ของตารางปัจจุบัน และทำตามตามนี้
        * ถ้าเป็น v1 list (`[:id, :name, :job]`), แปลงตารางโดยให้ทุกคนมี age ที่ 21 และสร้าง index ให้ `:age`
        * ถ้าเป็น v2 list ไม่ต้องทำอะไร
        * ถ้าเป็นอย่างอื่น โยนทิ้งไป

function `Mnesia.transform_table/3` เอา attribute ชื่อของตาราง, function ที่ใช้ในการแปลงตารางจากอันเก่าเป็นอันใหม่ และ list ของ attribute ใหม่

```elixir
iex> case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
...>   {:atomic, :ok} ->
...>     Mnesia.add_table_index(Person, :job)
...>     Mnesia.add_table_index(Person, :age)
...>   {:aborted, {:already_exists, Person}} ->
...>     case Mnesia.table_info(Person, :attributes) do
...>       [:id, :name, :job] ->
...>         Mnesia.transform_table(
...>           Person,
...>           fn ({Person, id, name, job}) ->
...>             {Person, id, name, job, 21}
...>           end,
...>           [:id, :name, :job, :age]
...>           )
...>         Mnesia.add_table_index(Person, :age)
...>       [:id, :name, :job, :age] ->
...>         :ok
...>       other ->
...>         {:error, other}
...>     end
...> end
```
