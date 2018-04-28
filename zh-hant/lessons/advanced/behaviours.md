---
version: 1.0.1
title: 行為
---

在前一課中了解了 Typespecs，現在將學習如何請求一個模組來實現這些規範 (specifications)。
在 Elixir 中，這個功能被稱為行為 (behaviours)。

{% include toc.html %}

## 用途

有時候你想讓模組共享一個公用 API，Elixir 的解決方案就是行為 (behaviours)。行為扮演兩個主要角色：

+ 定義一組必定被實現的函數
+ 檢查該函數組是否被實際執行

Elixir 內含多種行為，例如 `GenServer`，但在本課程中，將專注於建立自己的行為。

## 定義一個行為 (behaviour)

為了更好地理解行為，現在為一個工作模組實現一個行為。這些工作模組需要實現兩個函數：`init/1` 和 `perform/2`。

而為了做到這一點，將使用 `@callback` 指令，其語法類似於 `@spec`。這定義了 __required__ 函數；而對於巨集，則可以使用 `@macrocallback`。現在替工作模組指定 `init/1` 和 `perform/2` 函數：

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

在這裡定義 `init / 1` 做為接受任何值並回傳一個 tuple 不論 `{:ok, state}` 或 `{:error, reason}`，這是一個非常標準的初始化。`perform/2` 函數將會隨著初始化狀態收到一些工作模組的引數，將預期 `perform/2` 非常像 GenServers 回傳 `{:ok, result, state}` 或 `{:error, reason, state}`。

## 開始使用行為 (behaviours)

現在已經定義了行為，可以使用它來建立各種共享相同公用 API 的模組。
通過 `@behaviour` 屬性可以輕鬆地將行為加入到模組中。

現在使用新行為建立一個模組，其 task 將是下載遠端檔案並儲存到本地端：

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

那處理一系列檔案壓縮的工作模組又如何？這也是有可能做到的：

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

雖然執行的工作不同，但面向的公用 API 則不會，所以利用這些模組的任何程式碼都可以與它們進行互動，並且知道會按預期做出回應。這使我們能夠建立任意數量的工作模組，且都執行不同的 tasks，但符合相同的公用 API。

如果碰巧加入了一個行為但未能實現所有請求的函數，則編譯時會觸發警告。為了在編譯時看到這個事件，通過刪除 `init/1` 函數來修改 `Example.Compressor` 程式碼：

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

現在當編譯程式碼時，應該會看到一個警告：

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

就這樣！現在已經準備好建立和與其他人共享行為 (behaviours)。
