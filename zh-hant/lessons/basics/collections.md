---
version: 1.3.1
title: 集合
---

串列、元組、關鍵字串列和映射。

{% include toc.html %}

## 串列 (Lists)

串列是可以包含多種型別的簡單集合；串列裡可以包含相同的值：

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir 的串列是用單向連結串列實作的。
這意味著取得串列長度會是一個線性時間 `O(n)` 的運算。
由於同樣的原因，通常把新元素插入串列的頭部 (prepend) 會比插入串列的尾部 (append) 更快：

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Prepending (fast)
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Appending (slow)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### 串列結合 (List Concatenation)

串列結合是用 `++/2` 運算子：

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

關於上述 (`++/2`) 這個表示法的說明：在 Elixir (以及 Erlang 這個語言，Elixir 是用它打造的。) 裡，每個函式或是運算子的全名可分為兩個部份，你取的名稱 (這裡是 `++`) 以及它的參數個數 (arity)。當我們在討論 Elixir (以及 Erlang ) 時，參數個數是很重要的部份。而它就只是當你要呼叫某個函式時，需要傳入參數的數量 (在這個例子裡就是 2 )。函式的全名則是用正斜線來組合名稱及參數個數。我們之後會針對這個主題有更多的說明，而目前只要看得懂這個表示法就夠了。

### 串列減法 (List Subtraction)

兩個串列可以用 `--/2` 來相減取得它們的差集；就算減去不存在的值也是安全的：

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

要注意串列裡重複的值。對於右邊集合中的每個元素，會移除掉左邊集合中第一個相同的元素：

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**註：** 串列減法使用 [嚴格比較 (strict comparison)](../basics/#comparison) 來比對值。例如：

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### 頭 / 尾 (Head / Tail)

使用串列時，常常會需要用到串列的頭和尾。
頭是串列的第一個元素，而尾是剩餘元素的串列。
Elixir 提供了兩個有用的函式 `hd` 和 `tl` 來操作串列：

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

除了上面兩個函式外，您還可以使用 [模式比對 (pattern matching)](../pattern-matching/) 和 cons 運算子 `|` 來將串列分成頭和尾。這些在之後的課程會有更多的說明：

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## 元組 (Tuples)

元組跟串列很類似，但它們會連續的存放記憶體中。這讓我們能很快的取得它的長度，但也意味著修改它們是很昂貴的；新的元組得要完整的複製一份到記憶體的其它位置。我們用大括號來定義元組：

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

元組常用作為讓函式回傳附加訊息的手法；這在當我們學到 [pattern matching](../pattern-matching/) 後會更能理解它的好用之處：

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## 關鍵字串列 (Keyword lists)

關鍵字串列和映射是 Elixir 的關聯類集合。
在 Elixir 中，關鍵字串列是一個特殊的二元組 (兩個元素的元組) 串列，每個元組中的第一個元素是一個 atom；關鍵字串列的效能特性跟一般的串列是相同的：

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

關鍵字串列有以下三個重要的特徵：

+ 鍵 (Keys) 為 atoms。
+ 鍵 (Keys) 為有序。
+ 鍵 (Keys) 不必為唯一。

由於這些特徵，關鍵字串列最常作用於將不固定長度的選項傳遞給函數時。

## 映射 (Maps)

在 Elixir 中，映射是需要鍵值對時最常用的選擇。
與關鍵字串列不同，它允許任何資料型別做為鍵，而且它是無序的。你可以用 `%{}` 語法來定義一個映射：

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

從 Elixir 1.2 版開始，你也可以用變數來當做映射的鍵：

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

如果有重複的鍵出現或加入時，新成員的值將會替換掉原有的值：

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

對於所有的鍵都是 atom 的映射，有一個特別的簡寫語法。這個在上一段的輸入就能觀察到。

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

除此之外，還有一個取得 atom 鍵所對應的值的特殊語法：

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

映射還有一個有趣的特性在於它本身附帶一個更新成員用的特殊語法 (註：這會創造一個全新的映射)：

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**註**：此語法僅能更新映射中已存在的鍵！如果鍵不存在，將會拋出一個 `KeyError` 錯誤。

要加入新的鍵，你要用 [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3)

```elixir
iex> map = %{hello: "world"}
%{hello: "world"}
iex> %{map | foo: "baz"}
** (KeyError) key :foo not found in: %{hello: "world"}
    (stdlib) :maps.update(:foo, "baz", %{hello: "world"})
    (stdlib) erl_eval.erl:259: anonymous fn/2 in :erl_eval.expr/5
    (stdlib) lists.erl:1263: :lists.foldl/3
iex> Map.put(map, :foo, "baz")
%{foo: "baz", hello: "world"}
```
