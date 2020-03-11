---
version: 0.9.1
title: Các dự án ô
---

Đôi khi một dự án có thể trở nên rất lớn. Công cụ Mix cho phép chúng ta có thể chia nhỏ code thành nhiều ứng dụng, nó giúp cho các dự án Elixir của chúng ta có thể dễ dàng quản lý khi mà chúng phát triển.

{% include toc.html %}

## Giới thiệu

Để tạo ra một umberella project (tạm dịch là "Dự án ô"), chúng ta bắt đầu một dự án như là chúng một dự án Mix bình thường, nhưng truyền vào tham số `--umbrella`. Để ví dụ, chúng ta sẽ tạo ra một bộ công cụ cho học máy (machine learning). Tại sao lại là một bộ công cụ học máy? Tại sao không? Nó sẽ được tạo ra bởi rất nhiều thuật toán, và các hàm hỗ trợ.

```shell
$ mix new machine_learning_toolkit --umbrella

* creating .gitignore
* creating README.md
* creating mix.exs
* creating apps
* creating config
* creating config/config.exs

Your umbrella project was created successfully.
Inside your project, you will find an apps/ directory
where you can create and host many apps:

    cd machine_learning_toolkit
    cd apps
    mix new my_app

Commands like "mix compile" and "mix test" when executed
in the umbrella project root will automatically run
for each application in the apps/ directory.
```

Như bạn thấy từ shell command ở trên, Mix tạo ra một dự án khung cho chúng ta với 2 thư mục:

  - `apps/` - nơi chứa các dự án con
  - `config/` - nơi chứa các file cấu hình cho dự án ô


## Các dự án con

Hãy cùng chuyển vào thư mục `machine_learning_toolkit/apps` và tạo 3 ứng dụng thông thường với Mix như sau:

```shell
$ mix new utilities

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/utilities.ex
* creating test
* creating test/test_helper.exs
* creating test/utilities_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd utilities
    mix test

Run "mix help" for more commands.


$ mix new datasets

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/datasets.ex
* creating test
* creating test/test_helper.exs
* creating test/datasets_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd datasets
    mix test

Run "mix help" for more commands.

$ mix new svm

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/svm.ex
* creating test
* creating test/test_helper.exs
* creating test/svm_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd svm
    mix test

Run "mix help" for more commands.
```

Giờ chúng ta sẽ có cây dự án như sau:

```shell
$ tree
.
├── README.md
├── apps
│   ├── datasets
│   │   ├── README.md
│   │   ├── config
│   │   │   └── config.exs
│   │   ├── lib
│   │   │   └── datasets.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── datasets_test.exs
│   │       └── test_helper.exs
│   ├── svm
│   │   ├── README.md
│   │   ├── config
│   │   │   └── config.exs
│   │   ├── lib
│   │   │   └── svm.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── svm_test.exs
│   │       └── test_helper.exs
│   └── utilities
│       ├── README.md
│       ├── config
│       │   └── config.exs
│       ├── lib
│       │   └── utilities.ex
│       ├── mix.exs
│       └── test
│           ├── test_helper.exs
│           └── utilities_test.exs
├── config
│   └── config.exs
└── mix.exs
```

Nếu chúng ta quay trở về thư mục gốc của dự án ô, chúng ta có thể gọi tất cả các lệnh thông thường của Mix, ví dụ như `mix compile`. Vì các dự án con cũng là các ứng dụng bình thường, bạn có thể đi vào từng thư mục, và làm tất cả những việc mà Mix cho phép bạn làm.

```bash
$ mix compile

==> svm
Compiled lib/svm.ex
Generated svm app

==> datasets
Compiled lib/datasets.ex
Generated datasets app

==> utilities
Compiled lib/utilities.ex
Generated utilities app

Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
```

## IEx

Bạn có thể nghĩ rằng tương tác với các ứng dụng có thể hơi khác khi làm việc trong một dự án ô. Dù tin hay không, thì giả thiết này là không chính xác. Nếu chúng ta quay trở về thư mục gốc của dự án, và khởi động IEx bằng cách `iex -S mix`, chúng ta có thể tương tác với tất cả các dự án bình thường. Hãy cùng thay đổi nội dụng của `apps/datasets/lib/datasets.ex` cho ví dụ đơn giản sau:


```elixir
defmodule Datasets do
  def hello do
    IO.puts("Hello, I'm the datasets")
  end
end
```

```shell
$ iex -S mix
Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

==> datasets
Compiled lib/datasets.ex
Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)

iex> Datasets.hello
:world
```
