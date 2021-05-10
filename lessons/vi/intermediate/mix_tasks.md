%{
  version: "0.9.1",
  title: "Tác vụ Mix tùy biến",
  excerpt: """
  Tạo ra một tác vụ tùy biến cho dự án Elixir của bạn.
  """
}
---

## Giới thiệu

Sẽ không có gì là lạ nếu bạn muốn mở rộng ứng dụng Elixir bằng cách thêm một số tác vụ Mix. Trước khi học cách tạo ra một tác vụ Mix cụ thể, ta hãy xem qua những tác vụ có sẵn:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Như ở trên, Phoenix Framework cung cấp một tác vụ Mix để sinh dự án mới. Ồ vậy thì chúng ta có thể tự tạo cái gì đó tương tự cho dự án của chúng ta không nhỉ? Vâng câu trả lời là được, mà còn dễ như bỡn nữa là đằng khác.

## Setup

Chúng ta hãy dựng một ứng dụng Mix đơn giản.

```shell
$ mix new hello

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Bây giờ trong file **lib/hello.ex** mà Mix sinh ra cho chúng ta, hãy viết một hàm đơn giản để xuất ra "Hello, World!".

```elixir
defmodule Hello do

  @doc """
  Output's `Hello, World!` everytime.
  """
  def say do
    IO.puts "Hello, World!"
  end
end
```

## Tác vụ Mix tùy biến

Giờ thì ta tiến hành tạo tác vụ Mix của chính chúng ta nào. Hãy tạo mới một thư mục và file **hello/lib/mix/tasks/hello.ex**. Trong file này, hãy thêm vào 7 dòng code Elixir.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply runs the Hello.say/0 command."
  def run(_) do
    # calling our Hello.say() function from earlier
    Hello.say()
  end
end
```

Chú ý rằng defmodule bắt đầu với `Mix.Tasks` và tên mà chúng ta muốn gọi từ command line. Ở dòng thử hai, `use Mix.Task` sẽ cho chúng ta các tính năng của `Mix.Task`. Sau đó khai báo một hàm run mà ta tạm thời bỏ qua các tham số. Trong hàm này, ta gọi module `Hello` cùng với hàm `say`.

## Chạy tác vụ Mix

Ta hãy thử kiểm tra mix task vừa được tạo. Nó sẽ chạy ngon lành chỉ cần ta đứng trong thư mục. Từ command line, chạy lệnh `mix hello`, và ta sẽ thấy kết quả như sau:

```shell
$ mix hello
Hello, World!
```

Mix khá là thân thiện. Nó biết rằng ai thì cũng sẽ có lúc viết sai chính tả, nên nó dùng một kĩ thuật gọi là fuzzy string matching (tạm dịch: so trùng các chuỗi gần nhau) để gợi ý.

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Bạn có để ý là chúng ta vừa giới thiệu một thuộc tính module mới là `@shortdoc`? Nó sẽ có ích khi ta đưa ứng dụng ra sử dụng, như khi user chạy lệnh `mix help` từ terminal.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```
