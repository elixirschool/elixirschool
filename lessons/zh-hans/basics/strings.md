---
version: 1.2.0
title: 字符串
---

字符串、字符列表、字素(Graphemes) 和字码点（Codepoints）。

{% include toc.html %}

## 字符串

Elixir 字符串就是字节序列，我们来看一个例子：

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

我们可以看到，当在 `string` 后面添加一个字节 `0` 之后，IEx 将 `string` 显示为二进制，因为它已经不再是一个合法的字符串了。这个小技巧可以让我们看到所有字符串底层的字节。

>NOTE: 使用 `<< >>` 是告诉编译器这个符号里面的内容是字节。

## 字符列表

在 Elixir 内部，字符串是字节序列表示的，而不是字符数组。Elixir 也有一个字符列表的类型：字符串是双引号括起来的，而字符列表是单引号括起来的。

这两者有什么区别呢？字符列表的每个值都是字符的 UTF-8 的码点（Codepoint）, 而字符串里面的值是字符的二进制字节。我们来深入了解一下：


```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` 是 ł 的 UTF-8 码点，但是它在 UTF-8 中被编码为两个字节： `197` 和 `130`。

你可以通过 `?` 来获得一个字符的码点：

```elixir
iex> ?Z
90
```

通过 `?Z` 你可以直接取得 Z 的码点而不是 Z 这个字符。

在使用 Elixir 编程的时候，通常会使用字符串，而不是字符列表。字符列表之所以存在，是因为有些 Erlang 模块要用到它。

更多的信息请参考官方文档 [`Getting Started Guide`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## 字素和字码点

码点（Codepoint）就是一个或者多个字节表示的 Unicode 字符（根据 UTF-8 编码方式，每个字码点会有长度不同）。ASCII 码之外的字符一般都会由多个字节表示，比如带有波浪线或者声调的拉丁字符 (`á, ñ, è`) 一般都是两个字节表示的。而亚洲语言的字符一般都是三个或者四个字节。字素（Graphemes）就是一个字符的表示，通常由多个字码点组成。

`String` 模块已经提供了两个方法来获取这两种方式的值：`graphemes/1` 和 `codepoints/1`。我们来看一下：

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## 字符串函数

这个部分我们看一下 `String` 模块最常用的一些函数。本课程只会介绍其中的一部分，如果要了解所有的函数，请参考[官方 `String` 文档](https://hexdocs.pm/elixir/String.html)。

### `length/1`

返回字符串中的字素的数量：

```elixir
iex> String.length("Hello")
5
```

### `replace/3`

返回一个新的字符串，它的值是把原来某些模式替换成新的字符串得到的：

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

返回重复了 n 遍的字符串：

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

返回把原字符串按照某个模式分隔后的字符串列表：

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## 练习

我们来做个小的练习，证明已经掌握了字符串的知识。

### 重组字符串

A 和 B 如果能通过重组变得和对方一样，就认为两者是重组字符串。比如：

+ A = super
+ B = perus

如果我们重组 A 字符串中的元素就可以得到 B，反之亦然。

那么，怎么才能用 Elixir 判断两个字符串是否为重组字符串呢？最简单的办法就是对两个字符串的字符进行排序，然后比较排序后的结果是否相等。我们来试试这个方法：

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

先看一下 `anagrams?/2`，首先我们会检查接受的参数是否为 binaries，这是 Elixir 检查参数是否为字符串的方法。
然后，我们会调用把字符串按照字母表排序的函数，这个函数首先把所有字符转换成小写，然后调用 `String.graphemes` 得到字符串中字素的列表。思路很清晰，对吧？

我们来通过 iex 看一下输出结果：

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

正如上面展示的，最后一次调用 `anagrams?` 返回了 `FunctionClauseError`，这个错误就是告诉我们模块中没有接受两个非字符串的函数。这正是我们期望的结果：只接受字符串作为参数，其他都不允许。
