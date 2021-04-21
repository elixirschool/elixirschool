%{
  version: "1.1.1",
  title: "控制語句",
  excerpt: """
  在本課中，我們將專注在 Elixir 中可用的控制語句 (Control Structures)。
  """
}
---

## if 和 unless

可能你之前使用過 `if/2`，而如果你使用過 Ruby，那麼你應該很熟悉 `unless/2`。 在 Elixir 中，它們的工作方式大致相同，但它們被定義為巨集 (macros) 而不是語言結構。你可以在 [Kernel module](https://hexdocs.pm/elixir/Kernel.html) 中找到它們的實現 (implementation)。

應該小心的是，在 Elixir 中，唯一的 falsey 值是 `nil` 與布林的 `false`。

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

`unless/2` 使用方法和 `if/2` 一樣，只在 negative 時才會執行：

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## case

如果有必要比對多種樣式，我們可以使用 `case/2`：

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

`_` 變數是 `case/2` 語句中的重要內涵。 缺少 `_` 比對時將失敗，進而引發一個錯誤訊息：

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

想像 `_` 做為 `else` 將會比對 "所有一切"。


由於 `case/2` 依賴於模式比對，因此相同的規則和限制都適用。如果你打算比對已存在變數，你必須使用 pin `^/1` 運算子：

```elixir
iex> pie = 3.14
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

另一個 `case/2` 很酷的特點是它支援監視 (guard) 子句：

_以下例子直接來自官方 Elixir [Getting Started](https://elixir-lang.org/getting-started/case-cond-and-if.html#case) 指南。_

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

查看官方文件來獲得 [Expressions allowed in guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions) 資訊。

## cond

當我們需要比對的是條件 (conditions) 而不是值 (values) 時，我們可以轉為用 `cond/1`；這與其他語言的 `else if` 或 `elsif` 類似：

_以下例子直接來自官方 [Getting Started](https://elixir-lang.org/getting-started/case-cond-and-if.html#cond) 指南。_

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

像 `case/2` 一樣，如果比對沒有結果， `cond/1` 將會產生一個錯誤訊息。為了處理這個問題，我們可以定義並設置一個為 `true`的條件：

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

當你可能使用一個巢狀但無法清楚互相傳遞 (piped) 的 `case/2` 陳述語句或情況時，特殊形式的 `with/1` 是非常有用的。`with/1` 表達式由關鍵字、生成器 (generators) 以及表達式構成。

我們將在 [list comprehensions lesson](../comprehensions/) 中更廣泛地探討生成器，但是現在我們只需要知道它使用 [pattern matching](../pattern-matching/) 以 `<-` 的右側來與左邊做比對。

我們將以 `with/1` 的一個簡單例子開始，然後再看看更多的東西：

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

在表達式比對結果失敗的情況下，將回傳無法比對的值：

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

現在我們來看一個較複雜且沒有使用 `with/1` 的例子，看看我們是如何重構它的：

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

當我們引用 `with/1` 時，我們將得到更少行數並且很容易理解的程式碼：

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```


從 Elixir 1.3 開始， `with/1` 陳述句支援 `else` 語法：

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
    true <- is_even(number) do
      IO.puts "#{number} divided by 2 is #{div(number, 2)}"
      :even
  else
    :error ->
      IO.puts("We don't have this item in map")
      :error

    _ ->
      IO.puts("It is odd")
      :odd
  end
```

藉由在 `case` 中提供類似模式比對來協助處理錯誤。第一個不相配的表達式將是被傳遞的值。