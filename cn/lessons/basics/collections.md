---
layout: page
title: 集合
category: basics
order: 2
lang: cn
---

列表、元组、关键字列表（keywords）、图（maps）、字典和函数组合子（combinators）

{% include toc.html %}

## 列表

列表是值的简单集合，可以包含不同的数据类型，而且可能包含相同的值。

```elixir
iex> [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
```

Elixir 内部用链表实现列表，这表明获取列表长度是 `O(n)` 的操作。同样的原因，在头部插入比在尾部插入要快。

```elixir
iex> list = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> ["π"] ++ list
["π", 3.41, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.41, :pie, "Apple", "Cherry"]
```


### 列表拼接

列表拼接使用 `++/2` 操作符：

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### 列表减法

`--/2` 操作符支持列表的减法，而且减去不存在的值也是安全的。

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

### 头/尾

使用列表的时候，经常要和头部和尾部打交道：列表的头部是列表的第一个元素；尾部是除去第一个元素剩下的列表。
Elixir 提供了两个函数 `hd` 和 `tl` 来获取这两个部分。

```elixir
iex> hd [3.41, :pie, "Apple"]
3.41
iex> tl [3.41, :pie, "Apple"]
[:pie, "Apple"]
```

除了上面的提到的函数，你还可以使用 `|` 操作符，我们在后面的教程中还会看到这种用法。

```elixir
iex> [h|t] = [3.41, :pie, "Apple"]
[3.41, :pie, "Apple"]
iex> h
3.41
iex> t
[:pie, "Apple"]
```

## 元组
元组和列表很像，但是元组在内存中是连续存放的。这样的话，获取元组的长度很快，但是修改元组的操作很昂贵：新的元组必须重新在内存中拷贝一份。
定义元组要用花括号：

```elixir
iex> {3.41, :pie, "Apple"}
{3.41, :pie, "Apple"}
```

元组一个很常见的用法是作为函数的返回值，来返回额外的信息。当介绍到模式匹配的时候，这种用法的好处就显而易见了。

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## 关键字列表

关键字列表（keywords）和图（maps）是 Elixir 中两个相关的集合：它们都实现了 `Dict` 模块。Elixir 的关键字列表是一种特殊的列表：列表里的内容是二元元组，并且二元组的第一个元素必须是原子。它和列表的行为完全一致。

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

关键字列表非常重要，它有以下的特性：

+ 键（key）都是原子
+ 键（key）是有序的（定义后，顺序不会改变）
+ 键（key）是唯一的

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

## 字典

在 Elixir 中，关键字列表和图都实现了 `Dict` 模块，因此它们也被统称为字典。如果你需要创建自己的键值数据结构，自己实现 `Dict` 模块是不错的选择。

[`Dict` 模块](http://elixir-lang.org/docs/stable/elixir/#!Dict.html) 提供了一些有用的函数交互和操作这些字典（关键字列表和图）。

```elixir
# keyword lists
iex> Dict.put([foo: "bar"], :hello, "world")
[hello: "world", foo: "bar"]

# maps
iex> Dict.put(%{:foo => "bar"}, "hello", "world")
%{:foo => "bar", "hello" => "world"}

iex> Dict.has_key?(%{:foo => "bar"}, :foo)
true
```
