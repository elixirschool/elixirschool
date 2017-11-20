---
version: 0.9.1
title: Testing
---

Testing là một phần quan trọng của phát triển phần mềm. Trong bài này, chúng ta sẽ học cách để test code Elixir với ExUnit và một vài best practice để làm chuyện này.

{% include toc.html %}

## ExUnit

Thư viện test được đính kèm với Elixir là ExUnit, và nó cũng bao gồm tất cả mọi thứ mà chúng ta cần để test code. Trước khi đi tiếp, cần đặc biệt chú ý là các file test được cài đặt như là một Elixir scripts, vì thế chúng ta cần đặt tên các file này với phần mở rộng là `.exs`. Để có thể chạy các test, chúng ta cần khởi động ExUnit bằng cách gọi `ExUnit.start()`, thông thường chúng ta để việc khởi động này trong file `test/test_helper.exs`.

Khi chúng ta sinh ra dự án mẫu trong bài học trước, mix đã tự động tạo các test đơn giản, chúng ta có thể thấy nó trong `test/example_test.exs`:


```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Chúng ta có thể chạy toàn bộ test bằng lệnh `mix test`. Nếu chúng ta làm vậy, chúng ta sẽ thấy output như dưới đây:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Nếu bạn muốn viết các test thì trước hết bạn cần làm quen với `assert`, trong một vài frameworks `should` hoặc là `expect` sẽ đóng vai trò của `assert`.

Chúng ta sử dụng `assert` macro để test tính đúng đắn của một biểu thức. Nếu biểu thức là không đúng, một lỗi sẽ được văng ra, và bộ test sẽ thất bại. Hãy cùng sửa ví dụ của chúng ta để bộ test thất bại:


```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Giờ nếu chạy `mix test`, chúng ta có thể thấy output tương tự như sau:

```shell
  1) test the truth (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnit sẽ nói cho chúng ta biết chính xác test sai ở đâu, giá trị mong muốn là gì, và giá trị thực tế là gì.

### refute

`refute` đối với `assert` giống như `unless` với `if`.  Dùng `refute` khi bạn muốn đảm bảo một lệnh là luôn luôn sai.


### assert_raise

Đôi khi, chúng ta cần assert rằng một lỗi sẽ bị văng ra, chúng ta có thể làm điều đó với `assert_raise`. Hãy cùng xem ví dụ với `assert_raise` trong bài học tới về Plug.

### assert_receive

Trong ứng dụng Elixir chứa các actors/processes mà chúng gửi thông điệp tới nhau, bạn thường muốn test xem message nào được gửi đi. Từ việc ExUnit được chạy trong chính một process, nó có thể nhận message như bất cứ process nào khác, do vậy bạn có thể assert bằng cách dùng macro `assert_received`:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` không đợi các thông điệp, với `assert_receive` bạn có thể xác định một khoảng thời gian chờ.

### capture_io and capture_log

Có thể lấy ra output của một ứng dụng với `ExUnit.CaptureIO` mà không cần thay đổi ứng dụng. Đơn giản chỉ cần truyền hàm để sinh output vào:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` là tương đương, nhưng để lấy ra output của `Logger`.

## Cấu hình Test

Trong một số trường hợp, chúng ta sẽ cần phải thực hiện việc cấu hình trước khi test. Để làm điểu này, chúng ta sử dụng `setup` và `setup_all` macro. `setup` sẽ trả được chạy trước mọi test và `setup_all` sẽ chỉ chạy duy nhất một lần cho cả bộ test. Các hàm này mong muốn trả về một tuple `{:ok, state}`, trong đó state sẽ được sử dụng cho các test của chúng ta.

Để lấy ví dụ, chúng ta sử lại code như sau:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

## Mocking

Câu trả lời đơn giản với mocking trong Elixir là: đừng sử dụng nó. Bạn có thể muốn tìm tới mock một cách tự nhiên, nhưng cộng đồng Elixir không khuyến khích bạn làm chuyện đó.

Bạn có thể đọc chi tiết hơn trong [bài viết rất hay này](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/). Tóm lại, thay vì mock một phụ thuộc để test (mock như một *động từ*), có rất nhiều lợi ích nếu định nghĩa một giao diện cụ thể cho các code ở bên ngoài ứng dụng của chúng ta, và sử dụng Mock (như là *danh từ*) để cài đặt test.

Để thay đổi các cài đặt trong ứng dụng, cách được đưa ra là truyền module như là một tham số, và sử dụng một giá trị mặc định. Nếu điều này không khả thi, hãy sử dụng cơ chế cấu hình mặc định. Để tạo ra các cài đặt mock, bạn không cần thiết phải sử dụng một thư viện mock đặc biệt, chỉ cần sử dụng behaviour và callback là đủ.
