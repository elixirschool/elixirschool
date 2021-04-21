%{
  version: "0.9.1",
  title: "Cấu trúc điều khiển",
  excerpt: """
  Trong bài này ta sẽ xem qua các loại cấu trúc điều khiểu có sẵn trong Elixir.
  """
}
---

## if và unless

Hẳn là bạn đã từng biết đến `if/2` trước đây, và nếu bạn từng sử dụng Ruby hẳn bạn cũng chẳng lạ gì `unless/2`. Trong Elixir chúng vẫn được xử lý như thế nhưng khác ở chỗ chúng được định nghĩa như là marco, không phải cấu trúc ngôn ngữ. Bạn có thể xem cách cài đặt chúng tại [Kernel module](https://hexdocs.pm/elixir/Kernel.html).

Chú ý là trong Elixir, giá trị mang tính phủ định là `nil` và boolean `false`.

```elixir
iex> if String.valid?("Xin chào!") do
...>   "Chuỗi hợp lệ!"
...> else
...>   "Chuỗi không hợp lệ."
...> end
"Chuỗi hợp lệ!"

iex> if "một giá trị chuỗi" do
...>   "Chuẩn quá!"
...> end
"Chuẩn quá!"
```

`unless/2` cũng được dùng giống như `if/2`, chỉ khác là nó xử lý ngược lại:

```elixir
iex> unless is_integer("xin chào") do
...>   "Không phải Int"
...> end
"Không phải Int"
```

## case

Nếu cần thiết phải so trùng (match) nhiều mẫu (pattern) ta có thể dùng case:

```elixir
iex> case {:ok, "Xin chào!"} do
...>   {:ok, result} -> result
...>   {:error} -> "Úi chà!"
...>   _ -> "Cân hết."
...> end
"Xin chào"
```

Việc bao gồm biến `_` là một phần quan trọng trong mệnh đề `case`. Không có nó Elixir sẽ văng lỗi nếu không tìm thấy mẫu trùng khớp:

```elixir
iex> case :cam do
...>   :chanh -> "Chanh"
...> end
** (CaseClauseError) no case clause matching: :cam

iex> case :cam do
...>   :chanh -> "Chanh"
...>   _ -> "Không phải chanh"
...> end
"Không phải chanh"
```

Có thể xem `_` như là `else`, nó sẽ khớp với mọi trường hợp ngoại lệ.
Vì `case` phụ thuộc vào pattern matching nên nó cũng có tất cả những luật và hạn chế tương tự. Nếu bạn muốn so trùng một biến đã tồn tại bạn phải dùng toán tử pin `^`:

```elixir
iex> sauce = "nước tương"
"nước tương"
iex> case "mắm tôm" do
...>   ^sauce -> "Không ngon lắm"
...>   sauce -> "#{sauce} ngon tuyệt"
...> end
"mắm tôm ngon tuyệt"
```

Một tính năng hay của `case` là nó hỗ trợ mệnh đề guard (guard clause):

_Ví dụ này được dẫn trực tiếp từ trang chủ của Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) guide._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Trùng"
...>   _ ->
...>     "Không trùng"
...> end
"Trùng"
```

Xem tài liệu tại trang chủ về [Biểu thức hợp lệ trong mệnh đề guard](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).


## cond

Khi chúng ta cần so trùng điều kiện mà không phải giá trị, chúng ta chuyển sang dùng `cond`. Nó giống với `else if` hay `elsif` của các ngôn ngữ khác:

_Ví dụ này được dẫn trực tiếp từ trang chủ của Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) guide._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "Điều này không bao giờ đúng"
...>   2 * 2 == 3 ->
...>     "Điều này cũng không"
...>   1 + 1 == 2 ->
...>     "Nhưng điều này thì chuẩn không cần chỉnh"
...> end
"Nhưng điều này thì chuẩn không cần chỉnh"
```

Giống như `case`, `cond` cũng sẽ văng lỗi nếu không có mẫu trùng khớp. Để xử lý chuyện này, chúng ta định nghĩa ra một điều kiện là `true`

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Không đúng"
...>   true -> "Luôn đúng"
...> end
"Luôn đúng"
```

## with

`with` được dùng khi bạn muốn sử dụng một mệnh đề `case` lồng ghép hay những trường hợp không thể kết nối lại một cách trơn tru được. Biểu thức `with` là sự kết hợp của từ khóa, generators và cuối cùng là một biểu thức.

Chúng ta sẽ xem thêm về generators ở bài List Comprehensions nhưng bây giờ ta chỉ cần biết là chúng dùng pattern matching để so sánh biểu thức bên phải với biểu thức bên trái (cách nhau bởi dấu `<-`)

Chúng ta sẽ bắt đầu mới một ví dụ về `with`, sau đó xem qua các thứ khác:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Trường hợp mà một biểu thức không thể match được, giá trị không match được sẽ được trả về.

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Chúng ta xem qua về một ví dụ không dùng `with` và sau đó là cách refactor nó:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Khi chúng ta dùng `with`, code sẽ dễ đọc hơn và có ít dòng hơn:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token, claims),
     do: important_stuff(jwt, full_claims)
```

Với Elixir 1.3, biểu thức `with` bắt đầu hỗ trợ `else`:

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, res} <- Map.fetch(m, :a),
       true <- is_even(res) do
    IO.puts("Divided by 2 it is #{div(res, 2)}")
  else
    :error -> IO.puts("We don't have this item in map")
    _ -> IO.puts("It's not odd")
  end
```

Nó giúp việc xử lý lỗi dễ hơn bằng cách dùng pattern matching kiểu `case`. Giá trị truyền vào sẽ là biểu thức không match đầu tiên.
