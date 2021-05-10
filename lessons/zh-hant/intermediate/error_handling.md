%{
  version: "1.1.0",
  title: "錯誤處理",
  excerpt: """
  儘管常見到回傳 `{:error, reason}` tuple，但 Elixir 也支援異常 (exceptions)，在本課程中，將看看如何處理錯誤和我們可用的不同機制。

一般來說，Elixir 中的慣例 (convention) 是建立一個函數 (`example/1`) 回傳 `{:ok, result}` 和 `{:error, reason}`。而一個單獨的函數 (`example!/1`) 回傳無包圍的 (unwrapped) `result` 或觸發一個錯誤。

本課程將著重於與後者互動。
  """
}
---

## 一般慣例

目前，Elixir 社群已就回傳錯誤達成了一些約定：

* 對於屬於函數正常操作的錯誤（例如，使用者輸入了錯誤的日期類型），函數會相對地回傳 `{:ok, result}` 和 `{:error, reason}`。
* 對於不屬於正常操作的錯誤（例如，無法解析配置資料），將抛出異常。

我們慣於通過 [模式比對](../basics/pattern-matching/) 處理標準流程錯誤，但是在本課程中，將重點討論第二種情況 - 異常情況。

通常，在公用 API 中，也可以找到函數帶有 !（example!/1）回傳已展開結果或抛出錯誤的第二版本。

## 錯誤處理 (Error Handling)

在處理錯誤之前，需要建立它們，而最簡單的方法是使用 `raise/1` ：

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

如果要指定型別和訊息，需要使用 `raise/2`：

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

當知道錯誤可能發生時，可以使用 `try/rescue` 和模式比對來處理它：

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

在一個單獨的 rescue 中是可能配對多個錯誤：

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

有時可能需要在 `try/rescue` 之後執行一些操作，而忽略錯誤訊息。為此可以使用 `try/after` 。如果熟悉 Ruby，則類似於 `begin/rescue/ensure` 或 Java 中的 `try/catch/finally`：

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

最常用在應該關閉的檔案或連結 (connections)：

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## New Errors

雖然 Elixir 包含許多類似於 `RuntimeError` 的內建錯誤型別，但是如果需要特定的東西，仍然可以建立自己的錯誤型別。使用 `defexception/1` 巨集且用 `:message` 選項設定一個預設的錯誤訊息就能很容易產生一個新的錯誤訊息： 

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

現在來看看新的錯誤訊息：

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

在 Elixir 中處理錯誤的另一個機制是 `throw` 和 `catch`。在實踐中，這些錯誤在新的 Elixir 程式碼很少發生，但知道並理解它們仍是重要的。

 `throw/1` 函數使我們能夠用一個能 `catch` 並使用的特定值來退出 (exit) 執行：

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

如前所述， `throw/catch` 是非常不常見的，當函數庫無法提供足夠的 API 時，通常會以暫時的形式存在。

## Exiting

Elixir 提供的最後一個錯誤機制是 `exit`。Exit 信號發生在一個程序死亡時，這是 Elixir 故障容錯 (fault tolerance) 的重要組成部分。

要明確地 exit，可以使用 `exit/1`：

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

儘管可以用 `try/catch` 來 catch 一個 exit，但這樣做是 _極端_ 罕見的。因為在幾乎所有情況下，讓 supervisor 處理 exit 程序是有利的：

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
