%{
  version: "1.2.0",
  title: "字串",
  excerpt: """
  字串 (Strings)、字元列表 (Char Lists)、字位 (Graphemes) 和碼位 (Codepoints)。
  """
}
---

## 字串 (Strings)

Elixir 的字串就是位元組序列，現在來看一個例子：

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

通過將字串與位元組 `0` 連接，IEx 會將該字串顯示為二進位，因為它不再是有效的字串。這個技巧可以幫助我們查看任何字串的底層位元組。

>註： 當使用 << >> 語法時，是對編譯器說符號內的元素為位元組。

## 字元列表 (Charlists)

在 Elixir 內部， 字串用位元組 (bytes) 序列而不是字元 (characters) 陣列表示。Elixir 也有一個字元列表型別（character list)。雙引號括起來的是 Elixir 字串，字元列表 (char lists) 則以單引號括起來。

這兩者有什麼不同？ 字元列表中的每個值都是字元的二進位 Unicode 碼位，而這些碼位以 UTF-8 格式編碼。

現在來深入了解一下：

```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` 是  ł 的 Unicode 碼位，但以 UTF-8 格式分別編碼為 `197` 和 `130` 兩個位元組。

藉由使用 `?` 可以得到字元的碼位。

```elixir
iex> ?Z  
90
```
這允許你使用 `?Z` 而不是 'Z' 作為表示符號。

在 Elixir 中撰寫程式時，通常使用字串 (strings)，而不是字元列表 (charlists)。不過 Elixir 也包括對字元列表的支援，因為一些 Erlang 模組需要它。

欲了解更多資訊，請參閱官方 [`Getting Started Guide`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## 字位和碼位 (Graphemes and Codepoints)

碼位只是簡單的 Unicode 字元，由一個或多個位元組表示，具體取決於 UTF-8 編碼。US ASCII 字元集外的字元始終編碼為多個位元組。例如，帶有波浪或重音的拉丁符號 (`á, ñ, è`) 通常編碼為兩個位元組。
亞洲語言的字元則通常被編碼為三個或四個位元組。而字位 (Graphemes) 由多個碼位組成，並以單個字元呈現。

字串模組提供了兩個函數來獲取它們：`graphemes/1` 和 `codepoints/1`。現在來看一個例子：

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## 字串函數 (String Functions)

讓我們回顧一下字串模組中一些最重要和最有用的函數。本課程只介紹可用函數中的一個子集。要完整瀏覽整套函數集請造訪官方 [`String`](https://hexdocs.pm/elixir/String.html) 文件。

### `length/1`

回傳字串中的字位數目。

```elixir
iex> String.length "Hello"
5
```

### `replace/3`

回傳一個以新取代字串替換目前字串 pattern 的新字串。

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

回傳重複原本字串 n 次的新字串。

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

回傳由一個 pattern 分割的字串列表。

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## 練習 (Exercises)

現在通過一個簡單的練習來展示，我們已經準備好使用字串！

### 回文構詞字串 (Anagrams)

如果有辦法重新排列 A 或 B 而使它們相等，A 和 B 將被認為是一種回文構詞字串 (anagrams)。例如：

+ A = super
+ B = perus

如果重新安排字串 A 上的字元，可以得到字串 B，反之亦然。

那麼，怎麼能檢查兩個字串是不是 Elixir 中的回文構詞字串呢？最簡單的解決方法是按字母順序排序每個字串的字位，然後檢查兩個列表是否相等。現在來試試看：

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

首先來看 `anagrams?/2`。我們正在查驗接收到的參數 (parameters) 是否為二進位。這是檢查參數在 Elixir 中是否為字串的方式。

之後，我們呼用一個依字母順序排序字串的函數。它首先將字串轉換為小寫字母，然後使用 `String.graphemes/1` 來獲取字串中的字位列表。最後，將它列入 `Enum.sort/1`。非常直白，對吧？

現在來檢驗一下 iex 上的輸出結果：

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

正如所看到的，最後一次呼用 `anagrams?` 時觸發了一個 FunctionClauseError。這個錯誤訊息告訴我們，在目前模組中沒有函數符合所接收的兩個非二進制參數 (non-binary arguments) 的 pattern。但對這兩個所接收的字串，這正是我們不偏不倚想要的結果。