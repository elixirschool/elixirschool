%{
  version: "0.9.0",
  title: "Mnesia",
  excerpt: """
  Mnesia là một hệ thống nặng kí trong việc quản trị cơ sở dữ liệu thời gian thực.
  """
}
---

## Tổng quan

Mnesia là hệ quản trị cơ sở dữ liệu (DBMS) được lấy từ Erlang Runtime System và có thể sử dụng thuần thục trong Elixir. Mnesia là _relational and object hybrid data model_ được phát triển để phù hợp với các ứng dụng phân tán dù lớn hay nhỏ.

## Khi nào thì sử dụng

Lựa chọn việc sử dụng một công nghệ nào thường khá là rối rắm. Nếu bạn có thể trả lời 'Yes' cho bất kì câu hỏi sau, thì đó là tín hiệu tốt cho việc sử dụng Mnesia mà không phải là ETS hay DETS.

  - Tôi có cần chuyển về các transactions cũ không?
  - Liệu tôi có muốn dễ dàng trong việc sử dụng cú pháp cho đọc và ghi?
  - Tôi có nên lưu trữ dữ liệu ở nhiều nodes, thay vì một?
  - Tôi có cần lựa chọn nơi nào để lưu trữ thông tin (RAM or disk)?

## Schema

Bởi vì Mnesia là một phần của Erlang, chứ không phải từ Elixir, chúng ta cần truy suất nó với cú pháp hai chấm (See Lesson: [Erlang Interoperability](../../advanced/erlang/)):

```elixir

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

Với ví dụ này, chúng ta sẽ chọn hướng tiếp cận sau khi làm việc với Mnesia API. `Mnesia.create_schema/1` khởi tạo một schema mới và rỗng sau đó truyền tới Node List. Trong trường hợp này, chúng ta truyền những node liên quan trong IEx session của ta:

## Nodes

Sau khi chạy `Mnesia.create_schema([node()])` câu lệnh thông qua IEx, bạn có thể thấy thư mục tên là **Mnesia.nonode@nohost** hoặc tương tự trong thư mục hiện hành của bạn. Bạn có thể thắc mắc tại sao ý nghĩa của **nonode@nohost** vì chúng ta chưa gặp nó trước đây. Hãy cùng xem nào.

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Xuất ra phiên bản
  -e "command"      Thực thi cậu lệnh được đưa (*)
  -r "file"         Yêu cầu files/pattern đưa vào (*)
  -S "script"       Tìm và thực thi script đưa vào
  -pr "file"        Yêu cầu files/patterns đưa vào ở chế động song song(*)
  -pa "path"        Chèn trước đường dẫn vào Erlang code path (*)
  -pz "path"        Chèn sau đường dẫn vào Erlang code path (*)
  --app "app"       Chạy với app được đưa vào và các phụ thuộc của nó (*)
  --erl "switches"  Chuyển đổi sẽ được truyền xuống Erlang (*)
  --name "name"     Tạo và gán tên cho một node phân tán
  --sname "name"    Tạo vào gán tên vắn tắt cho một node phân tán
  --cookie "cookie" Gán cookie cho một node phân tán
  --hidden          Tạo một node ẩn
  --werl            Sử dụng giao diện Erlang Window (chỉ cho Window)
  --detached        Chạy Erlang VM và tách biệt nó với console
  --remsh "name"    Kết nối tới node thông qua remote shell
  --dot-iex "path"  Ghi đè mặc định cho .iex.exs file và thay vào đó sử đường dẫn;
                    đường dẫn này có thể rỗng, khi đó không có file nào được load

** Tham số với dấu (*) có thể thêm vào nhiều
** Tham số theo sau .exs file hoặc -- được đưa xuống code thực thi
** Tham số có thể truyền xuống VM thông qua ELIXIR_ERL_OPTIONS hoặc --erl
```

Khi truyền tham số `--help` xuống IEx từ dòng lệnh chúng ta được xem tất cả các tham số. Chúng ta có tham số `--name` và `--sname` được gán thêm thông tin cho nodes. Node chỉ đơn giản là một Erlang Virtual Machine nơi xử lý các giao tiếp, garbage collection, process scheduling, memory và nhiều cái khác nữa. Node mặc định được đánh tên **nonode@nohost**

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Như bạn thấy, node mà chúng ta chạy là một atom gọi là `:"learned@elixirschool.com"`. Nếu bạn chạy `Mnesia.create_schema([node()])` một lần nữa, chúng ta sẽ thấy nó tạo một thư mục khác tên là **Mnesia.learner@elixirschool.com**. Mục đích của việc này khá là đơn giản. Node trong Erlang được sử dụng để kết nối với những nodes khác để share (phân tán) thông tin và tài nguyên. Điều này không hạn chế phải là cùng một máy và có thể giao tiếp qua LAN, internet ...

## Chạy Mnesia

Bây giờ chúng ta đã có kiến thức căn bản về cách thiết lập database, chúng ta đã sẵn sằng để chạy Mnesia DBMS với câu lệnh `Mnesia.start/0`.

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

Chú ý rằng khi chạy hệ thống phân tán với hai hay nhiều nodes tham gia vào, `Mnesia.start/1` phải được thực thi ở tất cả các nodes.

## Tạo bảng

`Mnesia.create_table/2` được sử dụng để tạo trong database của chúng ta. Ở dưới chúng ta tạo bảng với tên `Person` và truyền danh sách khoá cái mà định nghĩa schema của bảng.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Chúng ta định nghĩa các cột thông qua atoms `:id`, `:name` và `:job`. Khi chúng ta thực thi `Mnesia.create_table/2`, nó sẽ trả về một trong 2 loại sau đây:

 - `{:atomic, :ok}` Nếu thực thi thành công
 - `{:aborted, Reason}` Nếu thực thi thất bại

Thực tế, nếu bảng tồn tại, lý do sẽ nằm ở mẫu `{:already_exists, table}` vậy nên chúng ta thử tạo bảng lần thứ 2, chúng ta sẽ nhận được kết quả sau:

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## Phương pháp ngoài luồng

Trước hết chúng ta sẽ nhìn phương pháp ngoài luồng cho việc đọc và ghi và bảng của Mnesia. Điều này thường nên tránh vì thành công sẽ không được bảo đảm, nhưng nó sẽ giúp chúng ta học và trở nên quen thuộc khi làm việc với Mnesia. Cùng thêm vào một vào đối tượng cho bảng **Person** của chúng ta:

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...và lấy thông tin thông qua `Mnesia.dirty_read/1`:

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

Nếu bạn muốn truy vấn thông tin không tồn tại Mnesia sẽ trả về danh sách rỗng.

## Transactions

Thông thường chúng ta sử dụng **transactions** để đóng gói lại những truy vấn đọc và ghi tới database. Transactions là một phần quan trọng trong việc thiết kế chống chịu lỗi, đặc biệt trong hệ thống phân tán. Mnesia *transaction là một phương pháp mà cho phép một nhóm cách thao tác database có thể thực thi trong một function block*. Đầu tiên chúng ta tạo một function nặc danh, trong trường hợp này `data_to_write` và sau đó truyền nó vào `Mnesia.transaction`.

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
Dựa trên kết quả của transaction, chúng ta có thể yên tâm giả định là chúng ta ghi dữ liệu xuống bảng `Person`. Hãy sử dụng transaction để đọc từ database để đảm bảo việc này. Chúng ta sẽ sử dụng `Mnesia.read/1` để đọc từ database, nhưng là từ một function nặc danh một lần nữa.

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

Lưu ý rằng nếu bạn muốn cập nhật dữ liệu, bạn chỉ cần gọi `Mnesia.write/1` với khoá trùng với dữ liệu cần cập nhật. Vậy nên, để cập nhật dữ liệu cho Hans, bạn có thể làm như sau:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## Sử dụng chỉ mục

Mnesia hỗ trợ chỉ mục cho những cột không phải là khoá và dữ liệu sau đó có thể truy vấn thông qua những chỉ mục trên. Vì vậy, chúng ta có thể thêm chỉ mục ở cột `:job` của bảng `Person`:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

Kết quả tương tự với kết quả từ câu lệnh `Mnesia.create_table/2`:

 - `{:atomic, :ok}` nếu thực thi thành công
 - `{:aborted, Reason}` nếu thực thi thật bại

Thực tế, nếu chỉ mục đã tồn tại, lý do sẽ nằm ở mẫu `{:already_exists, table, attribute_index}` vậy nếu chúng thử thêm vào chỉ một một lần nữa, chúng ta sẽ nhận được kết quả sau:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

Một khi chỉ mục thành công, bạn có thể đọc từ đó và lấy danh sách các đối tượng:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## So khớp và lựa chọn

Mnesia hỗ trợ câu truy vấn phức tạp để lấy dữ liệu từ bảng trong kiểu so khớp và ad-hoc trọng việc lựa chọn functions:

`Mnesia.match_object/1` trả về tất cả các dữ liệu mà khớp với mẫu được đưa ra. Nếu bất kì cột nào trong bảng có chỉ mục, nó có thể tận dụng chúng để truy vấn hiệu quả hơn. Sử dụng một atom đặc biệt `:_` để nhận diện những cột nào không có trong so khớp:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

`Mnesia.select/2` cho phép bạn dùng một câu truy vấn có tuỳ chỉnh cái mà sử dụng bất kì thao tác hoặc function trong Elixir (hoặc Erlang). Cùng xem ví dụ sau để lấy tất cả các dữ liệu có khoá lớn hơn 3:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

Cùng khám phá nó. Thuộc tính đầu tiên là bảng, `Person`, thuộc tính thứ 2 là mẫu với 3 tham số `{match, [guard], [result]}`:

- `match` giống với những gì bạn truyền cho `Mnesia.match_object/1`; tuy nhiên, lưu ý atom đặc biệt `:"$n"` cái dùng để xác định vị trí tham số được sử đụng cho phần còn lại của câu truy vấn.
- danh sách `guard` là một danh sách các tuples dùng để xác định những guard function nào được áp dụng, trong trường hợp này là `:>` ( lớn hơn) được tạo sẵn trong function với tham số đầu tiên `:"$1"` và hằng số 3 như là giá trị.
- danh sách `result` là danh sách các trường mà được trả về bởi câu truy vấn, vị trí các tham số của atom đặc biệt `:"$$"` dùng để tham chiếu tới tất cả các trường mà bạn có thể dùng `[:"$1", :"$2"]` để trả về 2 trường đầu tiên hoặc `[:"$$"]` cho tất cả các trường.

Chi tiết hơn, tham khảo [the Erlang Mnesia documentation for select/2](http://erlang.org/doc/man/mnesia.html#select-2).

## Khởi tạo dữ liệu và chuyển đổi

Với bất kì giải pháp phần mềm nào, sẽ đến lúc bạn cần nâng cấp phần mềm và chuyển đổi dữ liệu lưu trữ trong database của bạn. Ví dụ, chúng ta muốn thêm cột `:age` vào bảng `Person` trong v2 của ứng dụng ta. Chúng ta không thể tạo bảng `Person` một lần nữa vì nó đã được tạo nhưng chúng ta có thể chuyển đổi chúng. Để làm vậy chúng ta cần biết khi nào cần chuyển, những gì cúng ta có thể làm khi tạo bảng. Để làm điều này, chúng ta có thể sử dụng `Mnesia.table_info/2` để lấy thông tin hiện tại về cấu trúc của bảng và `Mnesia.transform_table/3` để chuyển nó sang cấu trúc mới.

Cài đặt sau thực hiện chúng thông qua thực thi các cách sau:

* Tạo bảng thuộc tính v2: `[:id, :name, :job, :age]`
* Xử lý kết quả tạo bảng trả về:
    * `{:atomic, :ok}`: khởi tạo bảng bằng cách tạo chỉ mục trên `:job` và `:age`
    * `{:aborted, {:already_exists, Person}}`: kiểm tra những thuộc tính hiện tại trong bảng và thao tác như sau:
        * nếu nó nằm trong danh sách v1 (`[:id, :name, :job]`), chuyển đổi bảng gán mọi người với tuổi 21 và tạo chỉ mục trên `:age`
        * nếu nó nằm trên dánh sách v2, không làm gì cả, mọi thứ tốt
        * nếu khác nữa, kệ nó

`Mnesia.transform_table/3` function lấy bảng và các tham số, function mà chuyển đổi dữ liệu từ cũ sang kiểu mới và danh sách các thuộc tính mới.

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
