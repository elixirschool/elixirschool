---
version: 0.9.1
title: Documentation
---

Viết tài liệu cho code Elixir

{% include toc.html %}

## Annotation

Chúng ta nên comment nhiều ra sao, và điều gì làm nên các tài liệu chất lượng là một vấn đề gây tranh cãi trong thế giới lập trình. Tuy nhiên, tất cả chúng ta có thể đồng ý là tài liệu rất quan trọng với chúng ta và những người cùng làm việc trên code base do chúng ta viết.

Elixir coi tài liệu là *công dân hạng nhất*, và đưa ra rất nhiều chức năng để có thể truy cập và sinh ra tài liệu cho các dự án. Elixir core cung cấp cho chúng ta nhiều thuộc tính khác nhau để có thể đánh dấu vào trong trong code. Hãy cùng xem xét 3 cách dưới đây:

  - `#` - Viết tài liệu inline (ở mức từng dòng code)
  - `@moduledoc` - Viết tài liệu ở mức module.
  - `@doc` - Viết tài liệu ở mức function/macro.

### Inline Documentation

Có lẽ cách đơn giản nhất để comment code là dùng inline comment. Giống như Python hoặc Ruby, inline comment trong Elixir được bắt đầu với một ký tự `#`, thường được gọi là một *pound*, hoặc một *hash* phụ thuộc vào nơi bạn sống.

Ví dụ:

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Elixir khi chạy đoạn script trên sẽ bỏ qua tất cả những đoạn code trong dòng bắt đầu từ `#`, coi chúng như là những dữ liệu được bỏ đi. Inline comment không thêm bất cứ giá trị nào vào hoạt động và tốc độ của đoạn script, tuy nhiên khi mà đoạn code bạn viết không thể hiện rõ những gì nó chạy, lập trình viên có thể biết thông qua việc đọc comment của bạn. Tuy nhiên, không nên lạm dụng inline comment. Comment bừa bãi có thể khiến codebase trở thành ác mộng. Nó nên được sử dụng tốt nhất trong chừng mực.


### Documenting Modules

`@moduledoc` được dùng để có thể tài liệu hoá ở mức module. Nó thường nằm ngay dưới dòng định nghĩa module `defmodule` ở đầu file. Ví dụ dưới đây mô tả comment một dòng trong `@moduledoc`.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Chúng ta (hoặc những người khác) có thể truy cập vào tài liệu của module sử dụng hàm `h` trong IEx.

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

### Documenting Functions

Elixir ngoài việc cho chúng ta khả năng viết tài liệu ở mức module, còn cho phép chúng ta viết tài liệu ở mức hàm. `@doc` được sử dụng để mô tả tài liệu cho từng hàm hoặc macro. `@doc` thường nằm ngay trên hàm mà nó muốn mô tả.


```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Nếu chúng ta vào IEx lần nữa, và sử dụng lệnh `h` trên một hàm trong module, chúng ta có thể thấy:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

`hello/1` prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Chú ý cách bạn có thể sử dụng markup trong tài liệu, và cách mà terminal hiển thị nó. Bên cách việc trở nên rất xịn và hữu dụng trong hệ sinh thái của Elixir, nó càng hấp dẫn hơn khi chúng ta xem xét các mà ExDoc sinh ra tài liệu HTML.

## ExDoc

ExDoc là một dự án của Elixir để **cung cấp HTML (HyperText Markup Language) và các tài liệu trực tuyến cho các dự án Elixir**, bạn có thể xem xét mã nguồn của ExDoc ở [GitHub](https://github.com/elixir-lang/ex_doc). Hãy cùng tạo một Mix project cho dự án của chúng ta:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Giờ copy và paste đoạn code từ các `@doc` annotator vào một file gọi là `lib/greeter.ex` và hãy đảm bảo là một thứ vẫn làm việc từ dòng lệnh. Bây giờ, chúng ta đang làm việc trong một Mix project, chúng ta cần khởi động IEx bằng lệnh `iex -S mix`:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Installing

Giả sử rằng tất cả mọi việc đều tốt đẹp, chúng ta sẽ thấy output như trên thông báo rằng chúng ta đã sẵn sàng để cài đặt ExDoc. Trong file `mix.exs`, chúng ta thêm 2 phụ thuộc khác để bắt đầu: `:earmark` và `:ex_doc`.

```elixir
def deps do
  [{:earmark, "~> 0.1", only: :dev}, {:ex_doc, "~> 0.11", only: :dev}]
end
```

Chúng ta xác định `only: :dev` vì chúng ta không muốn phải tải và biên dịch những phụ thuộc này trên môi trường production. Nhưng Earmakr là cái gì? Earmark là một một bộ parser Markdown cho ngôn ngữ Elixir mà ExDoc sử dụng để biến tài liệu trong `@moduledoc` và `@doc` thành những HTML đẹp đẽ.

Cần chú ý ở điểm này, bạn không bắt buộc phải sử dụng Earmark. Bạn có thể thay đổi công cụ markup với các tool khác như Pandoc, Hoedown, hoặc là Cmark, tuy nhiên bạn sẽ phải cấu hình thêm một số thứ khác, có thể đọc thêm về điều này ở [đây](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool). Trong bài viết này, chúng ta vẫn sẽ chỉ sử dụng Earmark.


### Generating Documentation

Chạy tiếp từ dòng lệnh 2 lệnh sau:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

Hy vọng rằng, mọi thứ vẫn như kế hoạch, bạn có thể thấy những nội dung tương tự như ví dụ ở trên. Hãy cùng xem xét ở bên trong dự án Mix của chúng ta, và chúng ta sẽ thấy một thư mục được tạo ở gọi là **doc/**. Trong thư mục này chính là các tài liệu được sinh ra. Nếu chúng ta mở trang index bằng trình duyệt, chúng ta có thể thấy:

![ExDoc Screenshot 1]({% asset documentation_1.png @path %})

Chúng ta thấy Earmark đã hiển thị markdown, và ExDoc dưới định khác tốt hơn.

![ExDoc Screenshot 2]({% asset documentation_2.png @path %})

Giờ đây chúng ta có thể triển khai dự án này lên Github, hoặc phổ biến hơn là [HexDocs](https://hexdocs.pm/).

## Best Practice

Việc thêm tài liệu nên được nằm trong hướng dẫn về Best practices của một ngôn ngữ. Từ việc Elixir là một ngôn ngữ còn khá non trẻ, rất nhiều chuẩn còn đang được khai phá, cũng như hệ sinh thái đang phát triển. Tuy nhiên, công đồng đã nỗ lực để có thể tạo ra những Best Practice. Để đọc thêm về những Best Practice, có thể xem [The Elixir Style Guide](https://github.com/niftyn8/elixir_style_guide).

  - Luôn luôn viết tài liệu cho một module

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Nếu bạn không muốn viết tài liệu cho một module, đừng để trông nó, lúc đó, có thể sử dụng `false` như sau:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Khi muốn trỏ tới một hàm trong module, có thể sử dụng dấu `\`` như sau:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Phân tách tất cả các code một dòng trong `@moduledoc` như sau:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Sử dụng markdown trong các tài liệu sẽ làm nó dễ đọc hơn qua IEx và ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Cố gắng thêm một vài code ví dụ vào trong tài liệu của bạn, nó cũng cho phép bạn có thể sinh ra các test tự động từ code ví dụ tìm thấy trong module, hàm hoặc là macro với [ExUnit.DocTest][]. Để làm điều đó, bạn sẽ cần phải gọi tới `doctest/1` macro trong file test, và viết các ví dụ tuân theo một vài hướng dẫn, chi tiết được mô tả trong [tài liệu chuẩn][ExUnit.DocTest]

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
