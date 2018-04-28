---
version: 1.2.1
title: 集合
---

列表、元组、关键字列表（keywords）、图（maps）、字典和函数组合子（combinators）

{% include toc.html %}

## 列表

列表是值的简单集合，可以包含不同的数据类型，而且可能包含相同的值。

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir 内部用链表实现列表，这表明获取列表长度是 `O(n)` 的操作。同样的原因，在头部插入比在尾部插入要快。

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### 列表拼接

列表拼接使用 `++/2` 操作符：

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

关于上面使用到的 `++/2` 格式的说明：在 Elixir 中（以及 Elixir 的基础语言 Erlang），函数和操作符的名字由两部分组成：名字（比如这里的 `++`）和元数(arity)。元数是 Elixir 和 Erlang 代码非常核心的部分，它代表了给定函数接受的参数个数（比如这里的 2），元数和名字之间通过斜线分割。我们后面会讲到更多这方面的内容，知道这些已经能帮你理解它的含义了。

### 列表减法

`--/2` 操作符支持列表的减法，而且减去不存在的值也是安全的。

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

要注意重复值的处理：对于左边列表中	的每个值，右边只有首次出现的这个值会被删除：

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**注意：**这里比较是否相同使用的是[严格比较(strict comparison)](../basics/#comparison)。


### 头/尾

使用列表的时候，经常要和头部和尾部打交道：列表的头部是列表的第一个元素；尾部是除去第一个元素剩下的列表。
Elixir 提供了两个函数 `hd` 和 `tl` 来获取这两个部分。

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

除了上面的提到的函数，你还可以使用[模式匹配(pattern matching)](../pattern-matching/) 和 `|` 操作符来把一个列表分成头尾两部分；我们在后面的教程中还会看到这种用法。

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## 元组
元组和列表很像，但是元组在内存中是连续存放的。这样的话，获取元组的长度很快，但是修改元组的操作很昂贵：新的元组必须重新在内存中拷贝一份。
定义元组要用花括号：

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

元组一个很常见的用法是作为函数的返回值，来返回额外的信息。当介绍到模式匹配的时候，这种用法的好处就显而易见了。

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## 关键字列表

关键字列表（keywords）和图（maps）是 Elixir 中两个相关的集合。Elixir 的关键字列表是一种特殊的列表：列表里的内容是二元元组，并且二元组的第一个元素必须是原子。它和列表的行为完全一致。

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

关键字列表非常重要，它有以下的特性：

+ 键（key）都是原子
+ 键（key）是有序的（定义后，顺序不会改变）
+ 键（key）不是唯一的

因为这些原因，关键字列表最常见的用法是作为参数传递给函数。

## 图

Elixir 的图（maps）是键值对结构的第一选择，和关键字列表（keywords）不同，图允许任意类型的数据作为键，而且数据并不严格排序。你可以使用 `%{}` 来定义图：

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Elixir 1.2 版本中，也可以把变量作为图的键（key）：

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

如果重复的键添加到图中，后面的值会覆盖之前的值：

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

从上面的运行结果中，你或许发现了一些不同：存储键只有原子的图，可以不用 `=>`，直接使用关键字列表的语法：

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

图另一个有趣的特性是：它们提供了自己更新和获取原子键（key）的语法：

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
