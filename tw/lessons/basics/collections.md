---
version: 1.2.1
title: 群集
redirect_from:
  - /lessons/basics/collections/
---

列表、元組、關鍵字列表和映射。

{% include toc.html %}

## 列表

列表是可以包含多種型別的簡單值群集​​；列表還可能包含相同的值：

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir 以串列實現群集列表。這意味著存取列表長度是一個 `O(n)` 運算。  因此，通常前置插入比後綴置入更快：

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### 列表串接

列表串接使用 `++/2` 運算子：

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

關於上述使用 (`++/2`) 格式的註釋： 在 Elixir (同時 Erlang，Elixir 是構建在這上面)， 一個函數或運算子名稱有兩個元件：你給它的名字 (這裡是 `++`) 和它的 _arity_。 Arity 是在說明 Elixir (和 Erlang) 程式碼的核心部份。它指所給定函數的引數數量 (2，在這個例子中)。Arity和所給定的名稱以斜線合併。我們之後會再多談論；上述知識將幫助您了解目前的符號。

### 列表減法

通過提供 `--/2` 運算子支援減法;即使減去不存在的值也是安全的：

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

注意重複的值。對於右邊的每個元素，左邊中第一個出現將被移除：

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**注意：** 列表減法使用 [strict comparison](../basics/#comparison) 來匹配它的值。

### 頭 / 尾

使用列表時，常常操作列表的頭和尾。頭是列表的第一個元素，而尾是包含剩餘元素的列表。在這個部份的操作中 Elixir 提供了兩個有用的函式 `hd` 和 `tl` ：

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

除了上述函式外，您還可以使用 [pattern matching](../pattern-matching/)  cons 運算子 `|` 
將列表分成頭和尾。我們將在之後的課程中學習更多這種用法：

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## 元組

元組與列表相似，但以連續的方式儲存在內部記憶體中。這能快速存取它的長度，但當需要修改時則付出昂貴代價；新的元組必須完整複製到內部記體中。元組使用大括號定義：

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

元組常見於作為從函數返回額外信息的機制；當我們使用 [pattern matching](../pattern-matching/) 這個用處會更加明顯：

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## 關鍵字列表

關鍵詞列表和映射是 Elixir 的關聯群集。在 Elixir 中，關鍵字列表是一個特殊的2元素元組列表，列表中第一個元素是一個 atom；它們與列表共享效能：

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

關鍵字列表的三個特點彰顯了它們的重要性：

+ 鍵 (Keys) 為 atoms。
+ 鍵 (Keys) 為有序。
+ 鍵 (Keys) 可不是唯一。

由於這些原因，關鍵字列表最常用於將選項傳遞給函數。

## 映射

Elixir 中，映射是 "go-to" key-value store。與關鍵字列表不同，它允許任何資料型別做為鍵並且不需排序。你可以用 `%{}` 語法，來定義一個映射：

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

從 Elixir 1.2 開始，變數被允許作為映射鍵值：

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

如果將一個重複的鍵值添加到映射中，它將替換以前的值：

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

從上面的輸出中可以看到，對於只包含一個 atom 鍵值的映射，有一個特殊的語法：

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

另外，還有一個存取 atom 鍵的特殊語法：

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

映射的另一個有趣的特性是它提供了自身的更新語法：

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```
