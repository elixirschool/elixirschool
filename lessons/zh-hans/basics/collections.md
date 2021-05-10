%{
  version: "1.3.1",
  title: "集合",
  excerpt: """
  列表（list）、元组（tuple）、关键字列表（keyword list）、映射（map）。
  """
}
---

## 列表（List）

列表是值的简单集合，可以包含不同的数据类型，而且也可能包含相同的值。

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir 内部用链表实现列表，获取列表长度是 `O(n)` 的操作。这也代表着，在列表的头部插入比在尾部插入要快。

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π" | list]
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

关于上面使用到的 `++/2` 格式的说明：
在 Elixir 中（以及 Elixir 的基础语言 Erlang），函数和操作符的名字由两部分组成：名字（比如这里的 `++`）和元数(arity)。
元数是 Elixir 和 Erlang 代码非常核心的部分，它代表了给定函数接受的参数个数（比如这里的 2），元数和名字之间通过斜线分割。
我们后面会讲到更多这方面的内容，知道这些已经能帮你理解它的含义了。

### 列表减法

`--/2` 操作符支持列表的减法，而且减去不存在的值也是安全的。

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

值得注意的是，如果列表中有重复的值，对于右边列表中的出现的每一个值，只会从左边列表（被减列表）中移除一个与之相等的值，即第一个出现的值：

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**注意：**这里比较是否相同使用的是[严格比较(strict comparison)](../basics/#comparison)，请参考下面的例子：

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### 头/尾（head / tail）

使用列表的时候，经常要和列表的头（head）和尾（tail）打交道：列表的头部是列表的第一个元素；尾部是除去第一个元素剩下的列表。 Elixir 提供了两个函数 `hd` 和 `tl` 来获取这两个部分。

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

## 元组（Tuple）

元组和列表很像，但是元组在内存中是连续存放的。
这样的话，获取元组的长度很快，但是修改元组的操作很昂贵：新的元组必须重新在内存中拷贝一份。
定义元组要用花括号：

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

元组一个很常见的用法是作为函数的返回值，来返回额外的信息。当介绍到[模式匹配](../pattern-matching/)的时候，这种用法的好处就显而易见了。

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## 关键字列表（Keyword list）

关键字列表（keyword list）和映射（maps）是 Elixir 中两个相关的集合。Elixir 的关键字列表是一种特殊的列表：列表里的内容是二元元组，并且二元组的第一个元素必须是原子。它和列表的行为完全一致。

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

关键字列表非常重要，它有以下的特性：

+ 键（key）都是原子（atom）
+ 键（key）是有序的（定义后，顺序不会改变）
+ 键（key）不必是唯一的

因为这些原因，关键字列表最常见的用法是作为参数传递给函数。

## 映射（Map）

Elixir 的映射（maps）是键值对结构的第一选择，和关键字列表（keywords）不同，映射允许任意类型的数据作为键，而且数据并不严格排序。
你可以使用 `%{}` 来定义映射：

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

从 Elixir 1.2 版本开始，变量也可以作为映射的键（key）：

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

如果重复的键添加到映射中，后面的值会覆盖之前的值：

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

从上面的运行结果中，你或许发现了一些不同：存储键只有原子的映射，可以不用 `=>`，直接使用关键字列表的语法：

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

映射另一个有趣的特性是：它们提供了自己更新和获取原子键（key）的语法：

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```

**注意**: 这种语法只在更新一个已经存在于映射的键才有效！如果键不存在，则会抛出 `KeyError` 错误。

要创建一个新的键值对，则应当使用 [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3)

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
