---
layout: page
title: Testing
category: basics
order: 12
lang: vi
---

Testing là một phần quan trọng của phát triển phần mềm. Trong bài này, chúng ta sẽ học các để test code Elixir với ExUnit và một vài best practices để làm chuyện đó.

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

Nếu bạn muốn viết các test thì trước hệt bạn cần làm quen với `assert`, trong một vài frameworks `should` hoặc là `expect` sẽ đóng vai trò của `assert`.

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

ExUnit sẽ nói cho chúng ta biết chính xác test sai ở đâu, giá trí mong muốn là gì, và giá trị thực tế là gì.

### refute

`refute` đối với `assert` giống như `unless` với `if`.  Dùng `refute` khi bạn muốn đảm bảo một lệnh là luôn luôn sai.


### assert_raise

Đôi khi, chúng ta cần assert rằng một lỗi sẽ bị văng ra, chúng ta có thể làm điều đó với `assert_raise`. Hãy cùng xem ví dụ với `assert_raise` trong bài học tới về Plug.

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

Câu trả lời đơn giản với mocking trong Elixir là: đừng sử dụng nó. Bạn có thể muốn tìm tới mock một cách tự nhiên, nhưng trong Elixir cộng đồng không khuyến khích bạn làm chuyện đó. Nếu bạn tuân thủ theo những nguyên tắc thiết kế chuẩn, thì code của bạn có thể dễ dàng test như là các thành phần độc lập.
