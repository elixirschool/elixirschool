%{
  version: "1.0.2",
  title: "可执行文件",
  excerpt: """
  要想在 Elixir 中生成可执行文件，我们要用 `escript`。`escript` 会生成的可执行文件，可以运行在任何安装了 Erlang 的平台。
  """
}
---

## 开始

用 `escript` 创建可执行文件要做的事很少：实现一个 `main/1` 函数，和更新一下 Mixfile。  

我们要先创建一个模块作为可执行文件的入口，也就是我们实现 `main/1` 函数的地方：  

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

接下来，我们要在 Mixfile 文件中添加 `:escript` 选项，并指定 `:main_module` 的位置：  

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## 解析命令行参数

应用配置好之后，我们就要解析命令行参数了。我们要使用 Elixir 提供的 `OptionParser.parse/2` 函数和 `:switches` 选项标明我们的参数是布尔值：  

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> response
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## 构建

一旦我们在应用中配置好了 escript，使用 Mix 构建可执行文件就易如反掌了：  

```bash
$ mix escript.build
```

来看一下最后的运行情况：  

```bash
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

就这样，我们在 Elixir 用 escript 生成了自己的第一个可执行文件。  
