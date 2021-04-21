%{
  version: "1.1.0",
  title: "Erlang 项式存储 (ETS)",
  excerpt: """
  Erlang 项式存储 (Erlang Term Storage，通常简称 ETS) 是 OTP 中内置的一个功能强大的存储引擎，我们在 Elixir 中也可以很方便地使用。本文将介绍如何使用 ETS 以及如何在我们的应用中使用它。
  """
}
---

## 概览

ETS 是一个针对 Elixir 和 Erlang 对象的健壮的内存 (in-memory) 存储，并且内置于 OTP 中。ETS 可以存储大量的数据，同时维持常数时间的数据访问。

ETS 中的「表」 (table) 是由单独的进程创建并拥有的。当这个进程退出时，这张表也就销毁了。

您可以创建任意数量的 ETS 表。唯一的限制是服务器内存。可以使用环境变量 `ERL_MAX_ETS_TABLES` 来指定限制。

## 建表

新的表由 `new/2` 创建，该函数接受一个表名以及一组选项作为参数，返回一个表标识符 (table identifier)，用之于接下来的操作。

我们创建一个通过昵称来存取用户的表来做例子：

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

类似 `GenServer`，我们也可以直接通过名字而不是标识符来访问 ETS 表。这需要我们添加 `:named_table` 选项。然后我们就可以用名字来访问这张表了：

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### 表的类型

ETS 提供了四种类型的表：

- `set` - 默认的表类型。每个键(key)对应一个值(value)。键是唯一的。
- `ordered_set` - 与 `set` 类似，但是按照 Erlang/Elixir 项式来排序。需要注意的是这里键的比较方式。键可以不同，只要｢相等｣即可，例如 1 和 1.0 就是｢相等｣的。
- `bag` - 每个键可以包括多个对象，但一个对象在一个键中只能有一个实例。
- `duplicate_bag` - 每个键可以包括多个对象，也允许对象重复。

### 访问控制

ETS 提供的访问控制机制跟模块差不多：

- `public` - 所有进程都可以读／写。
- `protected` - 所有进程都可读。只有拥有者可以写。这是默认的配置。
- `private` - 只有拥有者可以读／写。

## 资源竞争（Race Conditions）

如果多于一个进程写入数据到一个表 - 不管是通过 `:public` 访问，或者通过拥有者进程接收消息 - 资源竞争都是可能发生的。比如，两个进程每个都尝试读取一个值为 `0` 的计数器，自增，然后写入 `1`；最后的结果就只反映了一次自增。

对于计数器来说，[:ets.update_counter/3](http://erlang.org/doc/man/ets.html#update_counter-3) 提供了原子性的读和写操作。对于其它场景，拥有者进程可能还是必须根据收到的消息，自己实现原子性的操作，比如 “把当前值，添加到列表里面键为 `:results` 的位置”。

## 插入数据

ETS 没有模式 (Schema) 的概念。唯一的限制是数据需要以元组的形式存放，并且将第一个元素作为键。我们使用 `insert/2` 来添加新数据：

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

在 `set` 或 `ordered_set` 上直接执行 `insert/2` 会覆盖掉已经存在的数据。使用 `insert_new/2` 可以避免数据覆盖的情况，该函数会在键已经存在时返回 `false`：

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## 获取数据

ETS 提供了一些方便好用的方法来获取我们储存于其中的数据。我们来看看如何通过查询键和几种不同形式的形式匹配来获取数据。

最常用，效率也最高的方法是直接根据键来查询。匹配的方法虽然也有用，但这种方法要遍历整张表，在较大的数据集上使用时要特别谨慎。

### 查询键

使用 `lookup/2`，我们可以看到一个键对应的所有记录：

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### 简单的匹配

ETS 是为 Erlang 打造的，所以匹配的语法可能有"一点点"笨重.

我们使用原子 `:"$1"`、`:"$2"`、`:"$3"` 等等来表示匹配中所使用的变量。其中的数字只用来表示其在返回值中的位置，而非匹配时的位置。不想要的部分我们可以用 `:_` 来忽略掉。

匹配表达式里也可以直接写书面值，但只有变量表示的部分会作为结果返回。说起来太抽象了不如实际试试看：

```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

我们再看看变量如何影响结果的顺序：

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

假如我们想要获取的是本来的对象，而不是列表呢？那可以用 `match_object/2`，这个函数忽略那些变量而直接返回整个对象：

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### 高级的查询

看过了简单匹配的例子，有没有更高级的查询方法呢？比如像 SQL 查询那样的？确实还有一套更强大的语法可以用。我们可以构建一个三元组然后使用 `select/2` 来做更高级的查询。这个三元组中的元素分别表示我们的匹配模式，一些「卫兵」语句 (guard)，以及返回结果的格式。

我们可以使用简单匹配中讲到的变量形式在加上 `:"$$"` 以及 `:"$_"` 来构建返回值的格式。前者将结果变成列表形式返回，后者直接返回原始数据的格式。

我们把前面用 `match/2` 的例子换成 `select/2` 看看：

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
{"3100", "", ["Elixir", "Ruby", "JavaScript"]}]
```

虽然 `select/2` 可以让我们更细微地控制如何匹配，以及返回的格式，但是这个语法实在是很不友好，而且表达能力也有限。其实 ETS 还为我们提供了 `fun2ms/1`，可以直接将一个函数转换成查询时需要用的｢匹配规范｣ (`match_spec`)。`fun2ms/1` 让我们可以用更熟悉的函数写法来构建具体的查询逻辑。

我们试试用 `fun2ms/1` 和 `select/2` 来找出所有会两种以上语言的用户：

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

想更深入地了解匹配规范请参考 Erlang 有关 [`match_spec` 的官方文档](http://www.erlang.org/doc/apps/erts/match_spec.html)。

## 删除数据

### 删除记录

跟 `insert/2` 和 `lookup/2` 差不多，我们用 `delete/2` 来删除某个键对应的记录。这个函数会同时删除键和值：

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### 删除表

只要拥有者没有退出，ETS 表就不会被垃圾回收。有时我们需要在保留拥有者进程的同时删除整张表。这个操作要用到 `delete/1`：

```elixir
iex> :ets.delete(:user_lookup)
true
```

## ETS 的用例

讲了这么多，我们接下来把学到的东西组合起来做一个简单的缓存试试。我们要实现一个 `get/4` 的函数，接受模块、函数、参数以及（针对缓存的）选项。目前我们只实现 `:ttl` 这一个选项。

这个例子假定 ETS 表已经由其他的进程（例如一个监督者）启动好了：

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

我们用一个返回系统时间的函数来演示这个缓存，TTL 设定为10秒。你可以看到我们在缓存过期之前拿到的都是 ETS 中保存的结果：

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

过了10秒后我们就可以拿到新的结果了：

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

综上所述，我们可以不引入任何依赖就实现一个可扩展的高速缓存，而且这只是 ETS 的诸多应用场景之一。

## 基于磁盘的 ETS (DETS)

我们现在了解了 ETS 这个内存存储，那有没有基于磁盘的存储呢？没错，我们有「基于磁盘的项式存储」 (Disk Based Term Storage)，简称 DETS。ETS 和 DETS 的 API 基本上是通用的，只有创建表的方式有些许不同。DETS 使用 `open_file/2` 而且不需要 `:named_table` 选项：

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

现在退出 `iex` 你就能看到当前目录生成了一个新的文件 `disk_storage`：

```shell
$ ls | grep -c disk_storage
1
```

最后要注意的一点，DETS 不支持 `ordered_set`，只支持 `set`、`bag` 和 `duplicate_bag`。
