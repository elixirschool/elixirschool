---
version: 1.0.2
title: IEx 辅助函数
---

{% include toc.html %}

## 概述

当你开始使用Elixir时, IEx是你最好的朋友.
IEx不仅仅是一个REPL程序, 它还拥有很多高级功能让浏览或者开发代码变得更简单.
我们将在这节课学习部分内建的辅助函数.

### 自动补全

当在shell中工作时, 经常会遇到不熟悉的模块.
为了了解模块如何使用, 自动补全的功能就显得非常有用.
只需要在输入模块名和`.`后, 按下 `Tab`:

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

这样我们就知道模块中有那些函数了!

### `.iex.exs`

每当 IEx 启动时都会读取叫 `.iex.exs` 的配置文件. 这个文件不在当前目录时, 会使用用户家目录的文件 (`~/.iex.exs`) 作为代替.

IEx shell启动后, 这个文件中定义的配置项和代码可以被我们使用. 比如想在 IEx 中使用一些我们创建的辅助函数, 就可以打开 `.iex.exs` 进行一些更改.

让我们开始创建一些辅助函数吧:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```
现在当我们启动 IEx 的时候就可以使用 IExHelpers 模块了. 启动 IEx 试一下我们的辅助函数:

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

如我们所见, 并不需要特别的 `require` 或 `import`, IEx 已经帮我们处理好了.

### `h`

`h` 是 Elixir shell 中最有用的工具了.
多亏了这门语言对文档的支持一级棒, 我们可以用这个辅助函数查看任意代码的文档.
我们看一下使用的例子:

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

甚至可以在 shell 中与补全功能组合在一起使用.
假想一下这是我们第一次使用 Map:

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

如我们所见, 不仅可以看到模块中有什么函数还能看到每个单独函数的文档, 而且它们大多都有使用示例.

### `i`

让我们用刚才学到的 `h` 来 了解一下 `i` 辅助函数:

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

现在我们得到了一堆关于 `Map` 的信息, 包括源文件路径和涉及到的其他模块. 无论浏览自定义还是外来的数据类型或函数时都很有帮助.

单独的每段文字看着都很多, 但总的来说我们可以获取这些有意义的信息:

- 这是一个 atom 数据类型
- 源代码所在位置
- 版本和编译选项
- 基本描述
- 原始表示形式
- 涉及到的其它模块

这给了我们很多可供参考的信息, 终于可以不用抓瞎了.

### `r`

如果想要重新编译一个具体的模块我们可以使用 `r` 辅助函数. 比如改变了一点代码想要运行新加的函数, 可以保存变更后使用 `r` 来重新编译:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

`t` 辅助函数告诉我们在模块中都有那些定义的类型:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

现在我们知道了在 `Map` 的实现中定义了 `key` 和 `value` 类型.
对应的在 `Map` 的源文件中:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

这个简单的例子, 说明在每个实现中 `key` 和 `value` 可以是任意类型的， 知道这些是有帮助的.

通过使用这些内建的辅助函数我们能更轻松地浏览代码并且更多地了解其中的运行机制. IEx 是一个强大且健壮的工具. 工具箱中有了这些工具, 浏览代码, 写程序可以变的更加有趣!
