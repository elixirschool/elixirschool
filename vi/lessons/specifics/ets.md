---
version: 0.9.1
title: Erlang Term Storage (ETS)
---

Erlang Term Storage, thường được biết như ETS, là hệ thống lưu trữ mạnh mẽ được xây dựng dựa trên OTP và sử dụng được trong Elixir. Trong bài này chúng ta sẽ tìm hiểu làm thế nào để kết nối tới ETS và sử dụng trong ứng dụng của bạn.

{% include toc.html %}

## Tổng quan

ETS là một kiểu lưu trữ trong bộ nhớ mạnh mẽ cho những objects trong Elixir và Erlang. ETS có khả năng lưu trữ một lượng lớn dữ liệu và hỗ trợ truy cập với thời gian hằng số.

Mỗi một bảng ETS được tạo và sở hữu bởi một process riêng biệt. Khi một process kết thúc, những bảng của nó sẽ bị xoá. Mặc định ETS giới hạn 1400 bảng cho mỗi node.

## Tạo bảng

Bảng được tạo với `new/2`, với tên bảng, các tuỳ chỉnh và trả về một nhận diện để bạn có thể thực hiện các thao tác sau đó.

Ví dụ chúng ta tạo bảng để lưu trữ và tìm những users thông qua nickname của họ:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

Giống như GenServers, có một cách để truy cập bảng trong ETS bằng tên thay vì nhận diện. Để làm vậy chúng ta cần thêm vào `:named_table`. Sau đó chúng ta có thể truy cập trực tiếp thông qua tên:


```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### Các loại bảng

Có 4 loại bảng trong ETS:

+ `set` — Đây là kiểu mặc định. Mỗi giá trị ứng với mỗi khoá. Các khoá là duy nhất.
+ `ordered_set` — Giống với `set` nhưng được sắp xếp bởi Erlang/Elixir term. Quan trọng là so sánh khoá sẽ khác trong `ordered_set`. Khoá không cần phải giống miễn là chúng bằng nhau. 1 và 1.0 được xem như là bằng nhau.
+ `bag` — Nhiều objects tương ứng với mỗi khoá, nhưng chỉ duy nhất một thể hiện của object cho mỗi khoá.
+ `duplicate_bag` — Nhiều object cho mỗi khoá, và cho phép trùng nhau.

### Quản lý truy cập

Quản lý truy cập trong Elixir khá tương tự với những modules khác:

+ `public` — Đọc/Ghi cho mọi processes.
+ `protected` — Đọc cho mọi processes. Nhưng chỉ process sở hữu ETS mới có quyền ghi. Đây là mặc định.
+ `private` — Đọc/Ghi giới hạn cho process sở hữu ETS.

## Thêm dữ liệu

ETS không có schema. Giới hạn duy nhất là dữ liệu phải được lưu trữ như tuple với thành phần đầu tiên là khoá. Để thêm dữ liệu chúng ta sử dụng `insert/2`:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

Khi sử dụng `insert/2` cho `set` hay `ordered_set` dữ liệu có sẵn sẽ bị thay thế. Để tránh tình trạng này, câu lệnh `insert_new/2` trả về `false` cho những khoá đã tồn tại:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## Lấy dữ liệu

ETS hỗ trợ ta một vài phương pháp để lấy dữ liệu đã được lưu trữ. Chúng ta sẽ tìm hiểu làm thế nào để lấy dữ liệu thông qua khoá và pattern matching.

Cách hiệu quả, lý tưởng là tìm kiếm qua khoá. Matching cũng tương đối hữu dụng cho bảng khi sử dụng cho một tập dữ liệu lớn.

### Tìm kiếm khoá

Với một khoá, chúng ta có thể sử dụng `lookup/2` để lấy tất cả các record tương ứng với khoá đó.

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Match đơn giản

ETS được xây dựng trên Erlang, vì vậy cẩn thận với match những tham số khá là _kì lạ_.

Để chỉ ra biến trong việc match, chúng ta sử dụng atoms `:"$1"`, `:"$2"`, `:"$3"` và tương tự vậy. Biến số phản ánh kết quả không phải là vị trí. Với những giá trị mà chúng ta không quan tâm, chúng ta sử dụng `:_`.

Những giá trị có thể được sử dụng trong matching, nhưng chỉ duy nhất biến sẽ được trả về như là một phần của kết quả. Đặt nó lại với nhau và xem cách nó hoạt động:

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

Cùng tìm hiểu một ví dụ khác để xem những biến này sẽ ảnh hưởng thứ tự trả về như thế nào:

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

Nếu chúng ta muốn lấy ra object gốc mà không phải một list thì sao? Chúng ta có thể sử dụng `match_object/2`, mặc dù những biến này trả về toàn bộ object.

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Tìm kiếm nâng cao

Chúng ta đã học về cách match những trường hợp đơn giản, nhưng nếu chúng ta muốn thứ gì đó giống với SQL query? Rất may có một syntax mạnh mẽ hơn cho chúng ta. Để tìm kiếm dữ liệu với `select/2` chúng ta cần phải tạo một danh sách các tuple với 3 tham số. Những tuple đại diện cho pattern của chúng ta, dữ liệu rỗng hay nâng cao hơn và trả về kiểu giá trị. 

`:"$$"` và `:"$"` có thể được sử dụng để tạo nên giá trị trả về. Những biến mới này là những shortcut cho kiểu giá trị; `:"$$"` lấy kết quả như là một dánh sách và `:"$"` lấy dữ liệu gốc.  

Lấy lại ví dụ trước `match/2` và chuyển nó thành `select/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"spork", 30, ["ruby", "elixir"]}]
```

Mặc dù `select/2` cho phép điều khiển sâu hơn cách mà chúng ta lấy những kết quả, syntax này không thân thiện và chỉ càng phức tạp hơn. Để xử lý vấn đề này ETS thêm vào `fun2ms/1`, biến functions thành match_specs. Với `fun2ms/1` chúng ta có thể tạo queries với những syntax cho function quen thuộc.

Hãy sử dụng `fun2ms/1` và `select/2` để tìm tất cả usernames với nhiều hơn 2 ngôn ngữ:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

Muốn tìm hiểu thêm về các định nghĩa match, đọc qua về tài liệu chính thức của Erlang về [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html).

## Xoá dữ liệu

### Xoá records

Xoá terms khá rã ràng với `insert/2` và `lookup/2`. Với `delete/2` chúng ta cần bảng và khoá. Điều này xoá cả khoá và giá trị của nó:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### Xoá bảng

Bảng trong ETS không được dọn trừ khi parent của nó bị xoá. Thỉnh thoảng nó có thể cần thiết khi xoá toàn bộ một bảng mà không xoá process chứa nó. Để làm vậy chúng ta sử dụng `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Ví dụ về cách sử dụng ETS

Tổng kết lại những gì chúng ta đã học ở trên, kết hợp mọi thứ lại và tạo một cache đơn giản cho những tính toán phức tạp. Chúng ta sẽ cài đặt `get/4` với tham số là module, function, arguments và options. Từ đây chúng ta chỉ quan tâm về `:ttl`

Với ví dụ này chúng ta giả sử bảng ETS đã được tạo như một phần của process như là supervisor:

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

Để minh hoạ cache chúng ta sẽ sử dụng function cái mà trả về giờ hệ thống và TTL của 10 giây. Bạn sẽ thấy ở ví dụ dưới, chúng ta sẽ lưu lại kết quả cho đến khi giá trị hết hiệu lực:

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

Sau 10 giây nếu chúng ta thử lại chúng ta sẽ nhận một kết quả khác:

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

Như bạn thấy chúng ta có thể cài đặt một hệ thống cache nhanh và có khả năng nhân rộng mà không phụ thuộc bất kì gì ở bên ngoài và đây là một trong nhiều tính năng của ETS.

## Disk-based ETS

Chúng ta biết ETS là lưu trữ trong bộ nhớ nhưng nếu chúng ta cần lưu trữ trên disk thì sao? Vì vậy chúng ta có Disk Based Term Storage, hay ngắn gọn DETS. ETS và DETS là như nhau chỉ với khác biệt là cách mà bảng được tạo. DETS dựa vào `open_file/2` và không cần `:named_table`: 

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

Nếu bạn thoát `iex` và nhìn vào cây thư mục hiện tại, bạn sẽ thấy file mới `disk_storage`:

```shell
$ ls | grep -c disk_storage
1
```

Điều cuối cùng cần lưu ý là DETS không support `ordered_set` giống như ETS, chỉ có `set`, `bag` và `duplicated_bag`.