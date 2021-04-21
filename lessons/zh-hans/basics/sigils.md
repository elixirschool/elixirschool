%{
  version: "1.0.2",
  title: "魔符(Sigil)",
  excerpt: """
  使用和定义魔符。
  """
}
---

## 魔符(Sigil) 概述

Elixir提供了一种叫做魔符(Sigil)的语法糖来表示和处理字面量。一个魔符以`~`开头然后接上一个字符。Elixir已经提供了一些内置的魔符。当然，如果你有需要的话，也可以创造自己的魔符。

下面是一些可以直接使用的魔符(对着下面的例子看更好):

  - `~C` 创建一个**不处理**插值和转义字符的字符列表
  - `~c` 创建一个**处理**插值和转义字符的字符列表
  - `~R` 创建一个**不处理**插值和转义字符的正则表达式
  - `~r` 创建一个**处理**插值和转义字符的正则表达式
  - `~S` 创建一个**不处理**插值和转义字符的字符串
  - `~s` 创建一个**处理**插值和转义字符的字符串
  - `~W` 创建一个**不处理**插值和转义字符的单词列表
  - `~w` 创建一个**处理**插值和转义字符的单词列表
  - `~N` 创建一个 `NaiveDateTime` 格式的数据结构
  - `~U` 创建一个 `DateTime` 格式的数据结构 (Elixir 1.9.0 开始支持)

可用的分隔符如下:

  - `<...>` 尖括号
  - `{...}` 大括号
  - `[...]` 中括号
  - `(...)` 小括号
  - `|...|` 两条直线(反斜杠上面那个)
  - `/.../` 斜杠
  - `"..."` 双引号
  - `'...'` 单引号

### 字符列表

 `~c` 和 `~C` 会分别创建不同的字符列表. 比如:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

可以看到，`~c`小写c对应的魔符处理了字符列表中的插入值，然而`~C`大写C对应的魔符没有处理。在内置的魔符中，这种大小写代表相反的场景的例子很常见。

### 正则表达式

 `~r` 和 `~R`这两个魔符用来表示正则表达式。可以用这两个魔符来声明一个正则表达式或者通过`Regex`函数来使用它们。举个例子:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```


在第一个例子中，"Elixir"并不与`re`的值相等。 这是因为正则表达式是大小写敏感的。由于Elixir支持 Perl Compatible Regular Expressions (PCRE), 因此可以在魔符的末尾加`i`来关闭大小写敏感。

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

除此之外, Elixir还提供基于Erlang正则表达式库的 [Regex](https://hexdocs.pm/elixir/Regex.html) API。 让我们用正则表达式的魔符来实现`Regex.split/2` :

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

如上所示, 字符串 `"100_000_000"` 根据正则表达式`~r/_/` (代表匹配下划线)被切分了。函数 `Regex.split` 返回一个列表。

### 字符串

 `~s` 和 `~S` 这两个魔符用来创建字符串。举个例子:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

这两个魔符创建的字符串有不同吗? 它们的不同和前面提到的创建字符列表的两个魔符的不同很像。 答案就是是否处理插值和转义字符。 举个更明显的例子:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```
### 单词列表

这个魔符可以在处理表示句子的字符串的时候省下很多精力。 它可以降低代码复杂度、节省时间、按键次数。因为它能够将一个字符串自动分割并返回一个列表。举个简单的例子 :

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

可以看到，分隔符内的输入都被按空格分割并返回一个列表。但是两个魔符的结果似乎没什么区别。区别还是一样的，还是是否处理插值与转义字符。再看下面的例子:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### 真·时间日期

当需要创建**不带**时区的时间格式的数据结构时，魔符 [真·时间日期](https://hexdocs.pm/elixir/NaiveDateTime.html) 将很有用。

在大部分情况下，应该避免直接使用这个魔符创建时间格式的数据。但是，这个魔符在模式匹配的时候很有用。 举个例子:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

### DateTime

[DateTime](https://hexdocs.pm/elixir/DateTime.html) 对于快速创建一个表示带有 UTC 时区的 "DateTime" 的结构很有用。 由于它带有 UTC 时区所以您的字符串可能表示不同的时区，所以返回的第三个值表示偏移量(以秒为单位)

例如:

```elixir
iex> DateTime.from_iso8601("2015-01-23 23:50:07Z") == {:ok, ~U[2015-01-23 23:50:07Z], 0}
iex> DateTime.from_iso8601("2015-01-23 23:50:07-0600") == {:ok, ~U[2015-01-24 05:50:07Z], -21600}
```

## 定义你自己的魔符

Elixir这门语言有一个目的就是让Elixir成为一门可扩展的语言。因此你能够定义或者是创建自己的魔符并不是什么奇怪的事情。 在下面这个例子中，我们将定义一个魔符，它能够将小写字符串转化为大写字符串。尽管已经有一个函数 (`String.upcase/1`)实现了这个功能，我们仍将对那个函数进行包装，让它变成一个语法糖。

```elixir

iex> defmodule MySigils do
...>   def sigil_p(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~p/elixir school/
ELIXIR SCHOOL
```

首先我们创建了一个模块 `MySigils` ，然后定义了一个函数 `sigil_p`。因为没有一个已经存在的魔符是 `~p` 这个格式的，所以这个魔符的形式就是它。函数名后面的 `_p` 表示我们想要用 `p` 作为这个魔符的标识。这个函数接受两个参数，一个输入和一个列表。
