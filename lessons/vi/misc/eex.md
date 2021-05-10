---
version: 0.9.1
title: Embedded Elixir (EEx)
---

Như ERB của Ruby hay JSPs của Java, Elixir cũng có EEx hãy Embedded Elixir (tạm dịch: Elixir nhúng). Với EEx ta có thể nhúng hay thực thi lệnh Elixir trong string.

{% include toc.html %}

## API

API của EEx hỗ trợ làm việc trực tiếp với string hay tập tin. API này được chia ra thành ba phần chính: Tính toán đơn giản, định nghĩa hàm và biên dịch thành cây AST.

### Tính toán

Dùng hàm `eval_string/3` hay `eval_file/2` ta có thể thực hiện một lệnh tính toán trong một string hay nội dụng của file. Đây là API đơn giản nhất nhưng chậm nhất bởi code được tính toán mà không thông qua biên dịch.

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### Định nghĩa

Nhanh nhất và được khuyến khích sử dụng, cách dùng EEx này là nhúng một template (tạm dịch: bản mẫu) vào trong một module nên nó được biên dịch. Với EEx ta sẽ cần có template tại thời điểm biên dịch, cùng với các hàm `function_from_string/5` và `function_from_file/5`.

Ta hãy đưa hàm xuất lời chào sang một tập tin khác và sinh một hàm cho template của chúng ta:

```elixir
# greeting.eex
Hi, <%= name %>

defmodule Example do
  require EEx
  EEx.function_from_file(:def, :greeting, "greeting.eex", [:name])
end

iex> Example.greeting("Sean")
"Hi, Sean"
```

### Biên dịch

Cuối cùng, EEx cho chúng ta một cách để sinh cây AST của Elixir từ một string hoặc file dùng `compile_string/2` hay `compile_file/2`. API này chủ yếu được dùng bởi các API đã đề cập trước đó nhưng chỉ khi bạn muốn cài đặt cách nhúng Elixir của riêng bạn.

## Tags

Mặc định có bốn tag được hỗ trợ trong EEx:

```elixir
<% Biểu thức Elixir - nhưng sẽ không xuất kết quả gì %>
<%= Biểu thức Elixir - sẽ xuất kết quả %>
<%% Trích dẫn code Elixir - xuất nội dung bên trong tag %>
<%# Comment - sẽ bị bỏ qua trong code %>
```

Mọi biểu thực mà bạn muốn xuất quả quả __đều phải__ dùng kí hiệu bằng (`=`). Chú ý rằng các ngôn ngữ template khác có thể có một cách xử lý riêng với `if` nhưng EEx thì không. Không có `=` sẽ **không có gì** được xuất ra:

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## Engine (Bộ máy)

Mặc định Elixir sử dụng `EEx.SmartEngine`, cùng với việc hỗ trợ phép gán (như `@name`):

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

Phép gán của bộ `EEx.SmartEngine` rất có ích bởi vì các giá trị gán có thể được thay đổi mà không cần biên dịch lại.

Bạn muốn tự viết một engine của riêng bạn? Xem qua behaviour [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) để xem các thứ cần thiết.
