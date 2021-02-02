%{
  version: "1.0.1",
  title: "保護傘專案",
  excerpt: """
  有時候一個專案實際上可能變得很大，是真的很大的那種。Mix 構建工具允許將程式碼分割成多個應用程式，使得 Elixir 專案在成長時更易於管理。
  """
}
---

## 入門

為了建立一個保護傘專案 (umbrella project)，我們開啟一個專案，就如同要開始一個一般的 Mix 專案一樣，但多傳遞 `--umbrella` 旗標進去。

在這個範例中，將製作一個機器學習工具包的 *the shell* 。為什麼是機器學習工具包？因為沒什麼不好，它由多種學習演算法和實用函數組成。

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

正如你可以從 shell 指令中看到的，Mix 建立了一個帶有兩個目錄的小型框架專案：

  - `apps/` - 子 (child) 專案駐在目錄
  - `config/` - 保護傘專案的配置設定存放目錄


## 子專案

現在到專案 `machine_learning_toolkit/apps` 目錄下並使用 Mix 建立 3 個一般的應用程式，如下所示：

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

現在應該有一個像下面的專案樹：

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

如果回到保護傘專案根目錄，可以看到我們能夠呼用所有典型指令，如編譯。由於子專案也只是一般的應用程式，因此可以切換到子專案目錄並以往常相同方式執行那些 Mix 本來就允許的操作。

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

你可能認為在保護傘專案中要與應用程式互動會有所不同。不過信不信由你，你可能猜錯了！
如果將目錄切換到頂層目錄，並以 `iex -S mix` 啟動 IEx，我們能夠正常地與所有專案進行互動。
可以藉由修改 `apps/datasets/lib/datasets.ex` 內容，來表示這個簡單範例：

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
