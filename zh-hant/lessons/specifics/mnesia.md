---
version: 1.2.0
title: Mnesia
---

Mnesia 是一個重型即時分佈式資料庫管理系統。

{% include toc.html %}

## 概要

Mnesia 是一個資料庫管理系統 (DBMS) 與 Erlang Runtime 系統一起提供，因此能自然地與 Elixir 使用。
Mnesia 的 *關聯和物件混合資料模式* 使其適用於開發任何規模的分佈式應用程式。

## 何時該使用

尋求何時該應用一項技術的特定部份往往是令人困惑的。
如果對以下任何問題都回答「是」，那麼這是使用 Mnesia 而不是 ETS 或 DETS 的良好指示。

  - 需要回復交易嗎 (roll back transactions)？
  - 是否需要易用的語法來讀取和寫入資料？
  - 應該跨多節點而不是單一節點儲存資料嗎？
  - 是否需要選擇儲存資訊的位置（RAM或磁碟）？

## Schema

由於 Mnesia 是 Erlang 核心的一部分，而不是 Elixir，因此必須使用冒號語法存取它 (參考課程：[Erlang 互用性](../../advanced/erlang/))：

```elixir

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

本課程中，將在使用 Mnesia API 時採用後一種方法。
`Mnesia.create_schema/1` 初始化一個新的 schema 並傳入一個 Node List。
在這個例子中，傳入與 IEx 會話關聯的節點​​。

## Nodes

一旦通過 IEx 執行 `Mnesia.create_schema([node()])` 指令，應該看到一個名為 **Mnesia.nonode@nohost** 的資料夾。
你可能想知道 **nonode@nohost** 的含義是什麼，因為以前沒有遇到過。
現在來看一下。

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

當從命令列向 IEx 輸入 `--help` 選項，會看到所有可用選項。
可以看到有一個 `--name` 和 `--sname` 選項用於為節點配上資訊。
節點只是一個正在執行的 Erlang 虛擬機器，它處理自己的通訊、垃圾收集，排程處理程序，記憶體管理等等。
預設情況下，該節點被命名為**nonode@nohost**。

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

現在可以看到，正在執行的節點是一個名為 `:"learner@elixirschool.com"` 的 atom。
如果再次執行 `Mnesia.create_schema([node()])`，將看到它建立了另一個名為 **Mnesia.learner@elixirschool.com** 的資料夾。
它的目的很簡單。
Erlang 中的節點用於連接到其他節點以共享(分送)資訊和資源。
這不必局限於同一台機器，且可以通過區域網路、廣域網路等進行通訊。

## 啟動 Mnesia

現在已經掌握了背景知識並設定了資料庫，我們已經就定位可以使用 ```Mnesia.start/0``` 指令啟動 Mnesia DBMS。

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```
函數 `Mnesia.start/0` 是非同步的。它啟動現有表格的初始化設定並回傳 `:ok` atom。如果要在啟動 Mnesia 之後立即對現有表格執行某些動作，需要呼用 `Mnesia.wait_for_tables/2` 函數。它會暫停呼用者，直到表格被初始化完成。請參考 [資料初始化和遷移](#data-initialization-and-migration) 一章的範例。 

在執行具有兩個或更多節點的分佈式系統時，請留心記得，必須在所有參與節點上執行函數 `Mnesia.start/1`。

## 建立 Tables

函數 `Mnesia.create_table/2` 用於在資料庫中建立表格。
下面建立一個名為 `Person`的表格，加上一個定義表格資料結構的關鍵字列表。

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

使用 atoms `:id`、`:name` 和 `:job` 定義行 (column)。
第一個 atom（在本例中為 `:id` ）是主鍵。
且至少需要一個額外屬性。

當執行 `Mnesia.create_table/2` 時，它將回傳以下任一結果：

 - `{:atomic, :ok}` 如果函數執行成功
 - `{:aborted, Reason}` 如果函數執行失敗

特別的是，如果表格已經存在，格式將為 `{:already_exists, table}`，所以如果第二次嘗試建立這個表格，將得到：

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## Dirty 的方法

首先，將看一下讀取和寫入 Mnesia 表格的骯髒方式。
通常應該避免這種情況，因為無法保證成功，但它應該有助於學習並輕鬆地使用 Mnesia
現在在 **Person** 表格中加入一些條目。

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...檢索條目可以使用 `Mnesia.dirty_read/1`：

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

如果嘗試查詢不存在的記錄，Mnesia 將回應空列表。

## 交易 (Transactions)

傳統上，使用 **transactions** 來封裝 (encapsulate) 對資料庫的讀寫操作。
Transactions 是設計容錯、高度分佈式系統的重要部分。
一個 Mnesia *transaction 是一種機制，通過該機制，一系列的資料庫操作可以作為一個函數區塊* 執行。
首先，建立一個匿名函數，在本例中為 `data_to_write`，然後將其傳進 `Mnesia.transaction`。

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
基於此 transaction 訊息，可以安心地假設已將資料寫入 `Person` 表格。
現在使用 transaction 從資料庫中讀取來確定。
將使用 `Mnesia.read/1` 從資料庫中讀取，再次的，從匿名函數中讀取。

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

注意到，如果要更新資料，只需使用與現存記錄相同的鍵呼用 `Mnesia.write/1` 即可。
因此，要為 Hans 更新記錄，可以這樣做：

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## 使用索引

Mnesia 支援非鍵欄位 (non-key columns) 的索引建立，然後可以根據這些索引查詢資料。
所以可以在 `Person` 表格的 `:job` 欄位中加入一個索引：

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

結果與 `Mnesia.create_table/2` 回傳的類似：

 - `{:atomic, :ok}` 如果函數執行成功
 - `{:aborted, Reason}` 如果函數執行失敗

特別的是，如果索引已經存在，錯誤訊息將以 `{:already_exists, table, attribute_index}` 格式顯示，所以如果第二次嘗試加入這個索引，將得到：

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

成功建立索引後，可以讀取它並檢索所有主體的列表：

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Match 和 select

Mnesia 支援複雜查詢，以配對和臨時 (ad-hoc) 的選擇函數形式從表格中檢索資料。

`Mnesia.match_object/1` 函數回傳與給定模式相配的所有記錄。
如果表格中的任何欄位具有索引，則可以使用它們來提高查詢效率。
使用特殊 atom `:_` 來標記不參與配對的欄位(column)。

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

`Mnesia.select/2` 函數允許使用 Elixir 語言 (或Erlang) 中的任何運算符或函數指定一個自定查詢。
現在來看一個範例，選擇具有大於 3 的鍵的所有記錄：

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

現在來看這個範例。
第一個屬性是表格 `Person`，第二個屬性是 `{match, [guard], [result]}`: 形式的 triple：

- `match` 與您傳遞給 `Mnesia.match_object/1` 函數的內容相同; 但是，請注意特殊的 atoms `:"$n"` 它指定查詢其餘部分所使用的位置參數。
- the `guard` 列表是一個 tuples 列表，它指定要用的監視函數，本範例中是 `:>` (大於) 的第一個位置參數 `:"$1"` 和常數 `3` 作為屬性的內建函數 with the first positional parameter `:"$1"` and the constant `3` as attributes
- the `result` 列表是查詢後回傳的欄位列表。以特殊的 atom `:"$$"` 的位置參數的形式引用所有欄位，因此可以使用 `[:"$1", :"$2"]` 回傳前兩個欄位或用 `[:"$$"]` 回傳所有欄位。 

有關更多詳細資訊，請參閱 [select/2 的 Erlang Mnesia 文件](http://erlang.org/doc/man/mnesia.html#select-2)。

## 資料初始化和遷移

對於每個軟體使用，都有需要升級軟體並遷移儲存在資料庫中資料的時候。
例如，可能想在 app 的 v2 中的 `Person` 表格加入一個 `:age` 欄位。
我們無法在建立 `Person` 表格後再次建立，但可以對其進行轉換。
為此，需要知道何時進行轉換，可以在建立表格時執行此動作。
要如此做，可以使用 `Mnesia.table_info/2` 函數來檢索表格當前結構，並使用 `Mnesia.transform_table/3` 函數將其轉換為新結構。

下面的程式碼通過實現以下邏輯來實做：

* 使用 v2 屬性建立表格： `[:id, :name, :job, :age]`
* 處理建立結果:
    * `{:atomic, :ok}`: 通過在 `:job` 和 `:age` 上建立索引來初始化表格。
    * `{:aborted, {:already_exists, Person}}`: 檢查目前表格中的屬性並採取相應措施：
        * 如果它是v1列表 (`[:id, :name, :job]`)，轉換表格並給每個人 21 歲並在 `:age` 加入一個新索引。
        * 如果它是 v2 列表，一切正常，什麼都不做。
        * 如果它是其他的情況，bail out

如果在使用 `Mnesia.start/0` 啟動 Mnesia 之後立即對現有表格執行任何動作，那麼這些表格可能無法被初始化和存取。在這種情況下，應該使用 [`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2) 函數。它將暫停當前處理程序，直到表格初始化完成或到達等候逾時。

`Mnesia.transform_table/3` 函數將表格的名稱作為屬性，該函數將記錄從舊格式轉換為新格式和新屬性列表。

```elixir
case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
  {:atomic, :ok} ->
    Mnesia.add_table_index(Person, :job)
    Mnesia.add_table_index(Person, :age)
  {:aborted, {:already_exists, Person}} ->
    case Mnesia.table_info(Person, :attributes) do
      [:id, :name, :job] ->
        Mnesia.wait_for_tables([Person], 5000)
        Mnesia.transform_table(
          Person,
          fn ({Person, id, name, job}) ->
            {Person, id, name, job, 21}
          end,
          [:id, :name, :job, :age]
          )
        Mnesia.add_table_index(Person, :age)
      [:id, :name, :job, :age] ->
        :ok
      other ->
        {:error, other}
    end
end
```
