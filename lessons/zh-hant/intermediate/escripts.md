%{
  version: "1.0.1",
  title: "可執行檔案",
  excerpt: """
  要在 Elixir 中建立可執行檔案，需使用 escript。Escript 將生成一個可以在任何安裝了 Erlang 的系統上運作的可執行檔案。
  """
}
---

## 入門

要用 escript 建立一個可執行檔案，只需要做一些動作：實現一個 `main/1` 函數並更新 Mixfile。

從建立一個模組作為我們可執行檔案的入口 (entry point) 開始。這是將執行 `main/1` 的地方：

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Do stuff
  end
end
```

接下來，需要更新 Mixfile 以包含專案所需的 `:escript` 選項，同時指定 `:main_module`：

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

## 解析引數 (Parsing Args)

隨著應用程式設定，可以接著解析命令列引數。為此，將使用 Elixir 的 `OptionParser.parse/2` 伴隨 `:switches` 選項來表示旗標 (flag) 是布林 (boolean)： 

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

## 建立

一旦完成應用程式使用 escript 的環境設置，以 Mix 建立可執行檔案是不費吹灰之力的：

```elixir
$ mix escript.build
```

現在來試試看：

```elixir
$ ./example_app --upcase Hello
HELLO

$ ./example_app Hi
Hi
```

就這樣。我們已經使用 escript 在 Elixir 中建立了第一個可執行檔案。 