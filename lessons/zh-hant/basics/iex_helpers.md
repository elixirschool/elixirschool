%{
  version: "1.0.1",
  title: "IEx Helpers",
  excerpt: """
  
  """
}
---

## 概觀

當你開始在 Elixir 工作時，IEx 是你最好的朋友。這是一個 REPL，不過它有許多先進的功能，讓你在探索新程式碼或開發自己的程式時更輕鬆。我們將在本課程中介紹一些內建的 helpers。

### 自動完成 (Autocomplete)

在 shell 中工作時，經常會發現自己使用了一個不熟悉的新模組。當要了解那一些是可用時，這個自動完成功能是非常棒的。
只需輸入一個模組名稱，後接 `.` 然後按 `Tab` ：

```elixir
iex> Map. # press Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

現在我們知道能用的函數和其引數個數了！

### `.iex.exs`

每次 IEx 啟動，它都會尋找一個 `.iex.exs` 的設罝檔案。如果它不在當前目錄中，則使用者的主目錄 (`~/.iex.exs`) 將被做為回退 (fallback) 使用。

在 IEx shell 初始時，我們即可使用檔案中定義的設置選項和程式碼定義。例如，想在 IEx 中使一些 helper 函數為可用，可以打開 `.iex.exs` 並做一些修改。

讓我們從新增一組有多個 helper 函數的模組開始：

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

現在，當執行 IEx 時，將從初始時即提供 IExHelpers 模組。即刻啟動 IEx，來試試我們的新 helpers：

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

正如所看到的，不需要執行任何特殊的事件來請求或導入 helpers，IEx 會幫我們處理好。

### `h`

`h` 是 Elixir shell 付與我們最有用的工具之一。由於 Elixir 語言對文件 (documentation) 的一流支援，任何程式碼的文件都可以使用這個 helper 來實現。

要看它是如何被使用是很簡單的：

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

甚至可以將它與 shell 的自動完成 (autocomplete) 功能結合起來。
想像一下，我們正在首次探索 Map：

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

正如所看到的，不僅能夠找到是那一個函數能作為模組的一部分，而且還能夠存取各別函數的文件，其中許多文件都包含了範例和用法。

### `i`

先讓我們利用一些新發現的 `h` 知識來學習更多 `i` helper：

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

現在我們有一大堆關於 `Map` 的資訊，包括它的原始碼儲存位置和所引用模組。這在探索自訂設定 (custom)、外部資料型別 (foreign data types) 和新函數時非常有用。

只單看個別標題 (headings) 可能會難以理解，但在往內一層我們即可得到相關資訊：

- 它是一個 atom 資料型別
- 原始碼的儲存位置
- 版本和編譯選項 (compile options)
- 一般描述
- 如何存取
- 所引用的其它模組

這給了我們很多比盲目去試更好的有用資訊。

### `r`

如果想重新編譯一個特定的模組，可以使用 `r` helper。比方說，我們已經改變了一些程式碼，並希望執行新加入的函數。
要做到這一點，需要儲存修改並重新以 r 編譯：

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

 `t` helper 告訴我們關於所給定模組中的可用型別：

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

現在知道 `Map` 在它的實現中定義了鍵 (key) 和值 (value) 的型別。而如果去看 `Map` 的來源：

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

這個簡單例子，說明每個實現的鍵和值可以是任何型別，知道它是有幫助的。

通過利用這些內建的細緻工具，可以輕鬆地探索程式碼並學習更多關於程式的運作方式。IEx 是一個授予給開發人員非常強大和完備的工具。有了這些工具在我們的工具箱，探索和建造程式碼可以變得更有趣！
