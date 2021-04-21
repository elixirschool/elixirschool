%{
  version: "1.0.2",
  title: "符咒 (Sigils)",
  excerpt: """
  使用和創設符咒 (sigils)。
  """
}
---

## 符咒概述

Elixir 提供了用於表示和使用文字的替代語法。
一個符咒 (sigil) 將以波浪符號 `~` 開頭。
Elixir 核心已經提供一些內建的符咒，不過當我們需要時，也可以自行創造所需的符咒。。

可用符咒清單如下：

  - `~C` 生成一個 **不運算** 轉義 (escaping) 或內插 (interpolation) 的符號列表 (character list)
  - `~c` 生成一個 **運算** 轉義或內插的符號列表
  - `~R` 生成一個 **不運算** 轉義或內插的正規表達式 (regular expression)
  - `~r` 生成一個 **運算** 轉義或內插的正規表達式
  - `~S` 生成一個 **不運算** 轉義或內插的字串 (string)
  - `~s` 生成一個 **運算** 轉義或內插的字串
  - `~W` 生成一個 **不運算** 轉義或內插的字串列表 (word list)
  - `~w` 生成一個 **運算** 轉義或內插的字串列表
  - `~N` 生成一個 `NaiveDateTime` 結構體

分隔符號清單如下：

  - `<...>` 尖括號 (pointy brackets)
  - `{...}` 大括號 (curly brackets)
  - `[...]` 中括號 (square brackets)
  - `(...)` 小括號 (parentheses)
  - `|...|` 管線符號 (pipes)
  - `/.../` 斜線 (forward slashes)
  - `"..."` 雙引號 (double quotes)
  - `'...'` 單引號 (single quotes)

### 符號列表 (Char List)

符咒 `~c` 和 `~C` 分別生成不同的符號列表 (character lists)。
例如：

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

可以看到小寫字母的 `~c` 內插了計算結果，而大寫字母的 `~C` 則沒有。
我們將發現，字母大寫/小寫系列是整個內建符咒的常見樣式。

### 正規表達式 (Regular Expressions)

符咒 `~r` 和 `~R` 用來表示正規表達式。
我們能在動態情況創設或在 `Regex` 函數中使用。
例如：

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

我們可以看到，在第一個等式查驗中，`Elixir` 與正規表達式沒有相配。
這是因為它使用大寫字母。
由於 Elixir 支援相容 Perl 正規表達式（Perl Compatible Regular Expressions, PCRE），所以我們可以在符咒末尾加上 `i` 來關閉大小寫字母敏感。

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

此外，Elixir 提供構建在 Erlang 正規表達式函式庫之上的 [Regex](https://hexdocs.pm/elixir/Regex.html) API。
現在使用正規表達式符咒 (regex sigil) 來實現 `Regex.split/2` ：

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

感謝我們的符咒 `~r/_/`。正如我們所看到的，字串 `"100_000_000"` 藉由下底線 (underscore) 被分割。
函數 `Regex.split` 回傳了一個列表。

### 字串 (String)

符咒 `~s` 和 `~S` 被用來產生字串資料。
例如：

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

兩者有什麼不同？
答案是內插和轉義序列 (escape sequences) 的用法，其差別與我們所看到的符號列表符咒相似。
如果我們再舉一個例子：

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### 字串列表 (Word List)

字串列表符咒 (word list sigil) 時不時的會派上用場。
它可以節省敲擊鍵盤的次數與時間，同時減少程式庫的複雜性。
來看看這個簡單的例子：

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

我們可以看到在分隔符號之間鍵入的內容被空格分隔成一個列表。
實際上，這兩個例子沒有什麼區別。
而再一次，它們的差異來自內插和轉義序列。
現在來看下面的例子：

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### 真日期時間 (NaiveDateTime)

一個 [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) 可以快速創設一個結構體 (struct) 來表示 **不帶** 時區的 `DateTime` 。

在大多數情況下，我們應該避免直接創設一個 `NaiveDateTime` 結構體。
不過，在模式比對下非常有用。
例如：

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

## 自訂符咒 (Creating Sigils)

Elixir 的目標之一是成為一種可擴展 (extendable) 的程式語言。
因此您應該不會對於可以輕鬆自訂你自己的客製化符咒感到驚訝。
在這個例子中，我們將自訂一個符咒將字串轉換為大寫字母。
儘管在 Elixir 核心函式庫中存在這個 (`String.upcase/1`) 函數來實現，不過我們依然將圍繞著這個函數來自訂我們的符咒。

```elixir

iex> defmodule MySigils do
...>   def sigil_u(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~u/elixir school/
ELIXIR SCHOOL
```

首先我們定義一個名為 `MySigils` 的模組，並在該模組中創設一個名為 `sigil_u` 的函數。
由於現存的符咒空間 (sigil space) 中並不存在 `~u` 符咒，所以我們使用這個名字。
這個 `_u` 表示我們希望使用 `u` 作為波浪符號 (tilde) 之後的符號 (character)。
在這個函數的定義中，函數本身必須有兩個參數 (arguments)，一個輸入和一個列表。
