%{
  version: "1.1.0",
  title: "Erlang 項式儲存 (ETS)",
  excerpt: """
  Erlang 項式儲存 (Erlang Term Storage) 通常被稱為 ETS，它是內建於 OTP 中的強大儲存引擎，可用於 Elixir。在本課程中，將介紹如何與 ETS 連接以及如何在應用程式中使用它。
  """
}
---

## 概述

ETS 是包含 Elixir 和 Erlang 物件的強大內部記憶體 (in-memory ) 儲存。ETS 能夠儲存大量資料並提供常數時間 (constant time) 資料存取。

ETS 中的表格 (Tables) 由各個處理程序建立並擁有。當擁有者處理程序終止時，其表格也被銷毀。
預設情況下，ETS 限制為每個節點 1400 個表格。

## 建立表格

使用 `new/2` 建立表格，它接受一個表格名稱 (name) 和一組選項 (options)，並回傳一個可以在後續操作中使用的表格識別碼 (identifier)。

在範例中，將建立一個表格來儲存和查詢使用者暱稱：

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

就像 GenServers 一樣，有一種通過名稱 (name) 而不是識別碼 (identifier) 存取 ETS 表格的方法。
為此，需要包含 `:named_table` 選項。然後就可以直接通過名稱存取表格：

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### 表格類型

ETS 中有四種類型的表格：

+ `set` — 這是預設的表格類型。每個鍵一個值。鍵是唯一的。
+ `ordered_set` — 與 `set` 類似，但是由 Erlang/Elixir term 排序。需要注意的是， `ordered_set` 中的鍵值比較 (key comparison) 是不同的。只要比對相同，鍵就不需要比對。1 和 1.0 被認為是相等的。
+ `bag` — 每個鍵有許多物件 (objects)，但每個鍵的任一物件只有一個實例 (instance)。
+ `duplicate_bag` — 每個鍵有許多物件，允許重複。

### 存取控制

ETS 中的存取控制與模組內的存取控制類似：

+ `public` — 所有處理程序皆可讀取/寫入。
+ `protected` — 所有處理程序皆可讀取，但只能由擁有者處理程序寫入，這是預設值。
+ `private` — 限制由擁有者處理程序讀取/寫入。

## 競爭條件 (Race Conditions)

如果一個以上的處理程序可以寫入一個表格內 - 無論是通過 `:public` 存取還是通過向擁有者處理程序發送訊息 - 競爭條件 (race conditions) 都是可能的。例如，兩個處理程程序皆讀取一個值為 `0` 的計數器，遞增它並寫入 `1`；最終只會反映一個單一的遞增。

特別是對於計數器， [:ets.update_counter/3](http://erlang.org/doc/man/ets.html#update_counter-3) 提供了 atomic 的更新與讀取。對於其他情況，擁有者處理程序可能需要執行自定的 atomic 操作來回應訊息，例如 "add this value to the list at key `:results`"：

## 插入資料

ETS 沒有結構描述(schema)。唯一的限制是，資料必須以 tuple 儲存，tuple 的第一個元素為資料的鍵(key)。為了加入新的資料，可以使用 `insert/2`：

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

當和 `set` 或 `ordered_set` 一起使用 `insert/2` 時，現有的資料將被替換。
為了避免這種情況，當鍵存在時 `insert_new/2` 回傳 `false` ：

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## 資料檢索

ETS 提供了一些方便而靈活的方式來檢索 (retrieve) 儲存的資料。接著看看如何通過鍵和通過不同形式的模式比對來檢索資料。

最有效、最理想的檢索方法是鍵 (key) 查找。很有用，但比對會疊代整個表格，特別是在非常大的資料集上，應保守的使用。

### 查找特定鍵

給定一個鍵，可以使用 `lookup/2` 來檢索具有該鍵的所有記錄：

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### 簡易比對

ETS 是為 Erlang 構建的，所以要注意的是比對變數可能會讓人覺得 _有一點_ 笨重。

要在比對中指定一個變數，使用 atoms `:"$1"`、`:"$2"` 和 `:"$3"` 等等。變數數字反映結果位置而不是比對位置。對於不感興趣的值，使用 `:_` 變數。

值也可用於比對，但只有變數將作為結果的一部分回傳。現在全部都放在一起，看看它是如何運作的：

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

現在來看另一個範例，看看變數如何影響結果列表次序：

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

如果想要原始物件，而不是列表呢？可以使用 `match_object/2` ，它不管變數而是回傳整個物件：

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### 進階查詢

現在了解了簡易比對的情況，但是如果想要更類似於 SQL 查詢的東西呢？值得慶幸的是，我們有著更強大的語法。
要用 `select/2` 查找資料，需要建立一個有引數 3 (arity 3) 的 tuple 列表。
這些 tuples 表示我們的模式 (pattern)、零 (zero) 或更多的監視 (guard) 和一個回傳值格式。

可以使用比對變數和兩個新變數 `:"$$"` 與 `:"$_"` 來建立回傳值。
這些新變數是到結果格式的捷徑; `:"$$"` 得到列表的結果； `:"$_"` 得到原始資料物件。

現在來看一個以前的 `match/2` 範例，並將它變成一個 `select/2`：

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"spork", 30, ["ruby", "elixir"]}]
```

雖然 `select/2` 允許更好地控制檢索記錄的方式和內容，但是語法非常不友善，而且只會變得更加如此。
為了處理這個問題，ETS 模組包含 `fun2ms/1`，將函數轉換為 match_specs。經由 `fun2ms/1` ，就可以使用熟悉的函數語法建立查詢。

現在使用 `fun2ms/1` 和 `select/2` 來查找所有有超過 2 種語言的使用者名稱：

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

想要了解有關比對規範的更多資訊？請查看 [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html) 的 Erlang 官方文件。

## 刪除資料

### 移除記錄

刪除語法與 `insert/2` 和 `lookup/2` 一樣簡單。使用 `delete/2` ，只需要表格欄位和鍵。
這會刪除鍵及其值：

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### 移除表格

除非父母 (parent) 被終止，否則 ETS 表格不會被垃圾回收 (garbage collection)。
有時可能需要在不終止擁有者處理程序下刪除整個表格。為此可以使用 `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## ETS 使用範例

鑑於我們上面學到的，現在把所有東西放在一起，為代價高的操作建立一個簡單的快取 (cache)。
將實現一個 `get/4` 函數來獲取模組、函數、引數和選項。現在唯一擔心的是選項是 `:ttl`。

對於這個範例，假定 ETS 表格已經被建立為另一個處理程序的一部分，比如 supervisor：

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

為了展示快取，將使用一個回傳系統時間和 TTL 10 秒的函數。正如將在下面範例中看到的，我們得到快取的結果，直到值過期：

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

如果 10 秒後再試一次，應該得到一個新的結果：

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

正如所看到的，無需任何外部耦合關係即能夠實現可擴展 (scalable) 和快取 (fast cache)，而這只是 ETS 的眾多用途之一。

## 磁碟式 ETS

現在知道 ETS 是用於內部記憶體中的項式儲存，但是如果需要基於磁碟 (disk-based) 的儲存呢？
為此，有基於磁碟的項式儲存 (簡稱 DETS)。
除了建立表格之外，ETS 和 DETS 的 API 是可互換的。DETS 依賴 `open_file/2` 並且不需要 `:named_table` 選項：

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

如果退出 `iex` 並查看本地資料夾，會看到一個新的檔案 `disk_storage`：

```shell
$ ls | grep -c disk_storage
1
```

最後要注意的是 DETS 不像 ETS 那樣支援 `ordered_set`，只支援 `set`、`bag` 和 `duplicate_bag`。