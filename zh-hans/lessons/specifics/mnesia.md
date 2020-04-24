---
version: 1.2.0
title: Mnesia 数据库
---

Mnesia 是一个强大的分布式实时数据库管理系统。

{% include toc.html %}

## 概要

Mnesia 是 Erlang 运行时中自带的一个数据库管理系统（DBMS），也可以在 Elixir 中很自然地使用。Mnesia 的数据库模型可以混合了关系型和对象型数据模型的特征，让它可以用来开发任何规模的分布式应用程序。

## 应用场景

何时该使用何种技术常常是一个令人困惑的事情。如果下面这些问题中任意一个的答案是 yes 的话，则是一个很好的迹象告诉我们在这个情况下用 Mnesia 比用 ETS 或者 DETS 要适合。

  - 我是否需要回滚事务？
  - 我是否需要用一个简单的语法来读写数据？
  - 我是否需要在多于一个以上的节点存储数据？
  - 我是否需要选择数据存储的位置（内存还是硬盘）？

## Schema

因为 Mnesia 属于 Erlang 核心的一部分，但是 Elixir 还没有包含它 ，所以我们要用 `:mnesia` 这种方式去引用 Mnesia （参考[和 Erlang 互操作](../../advanced/erlang/)）。

```elixir

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

在本课中，我们会使用后一种方式来使用 Mnesia 的 API。`Mnesia.create_schema/1` 会初始化一个空的 Schema 并且传递给一个节点列表。 在本例中，我们传入的是当前 IEx 会话所在的节点。

## 节点（Node）

一旦我们在 IEx 中执行了 `Mnesia.create_schema([node()])` 命令后，我们就可以在当前目录下看到一个叫 **Mnesia.nonode@nohost** 或者类似名字的文件夹。你也许会好奇到底 **nonode@nohost** 代表着什么，因为在之前的课程中它没有出现过。所以我们接下来就来一探究竟：

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

当你给 IEx 传递 `--help` 选项的时候，IEx 会列出所有可用的选项。我们可以看到有 `--name` 和 `--sname` 两个选项可以给节点起名。
一个节点（Node）就是一个运行中的 Erlang 虚拟机，它独自管理着自己的通信，垃圾回收，进程调度以及内存等等。这个节点默认情况下被简单的称为 **nonode@nohost** 。

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

我们可以看到，当我给节点起名后，我们当前的节点名字已经叫做 `:"learner@elixirschool.com"`。如果我们再运行 `Mnesia.create_schema([node()])` 的话，我们会看到另外一个叫做 **Mnesia.learner@elixirschool.com** 的文件夹。这样设计的目的很简单。Erlang 中的节点只是用来连接其他节点用以分享（分发）信息和资源，它们并不一定要在同一台机器上，也可以通过局域网或者互联网等方式通信。

## 启动 Mnesia

我们已经了解了如何设置 Mnesia 数据库，现在我们就可以通过 `Mnesia.start/0` 来启动它了。

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

函数 `Mnesia.start/0` 是异步的。 它会初始化现有的表并返回原子 `:ok` 如果我们需要在启动 Mnesia 之后立即对现有表执行某些操作，我们需要调用`Mnesia.wait_for_tables/2` 函数。 它会挂起调用者，直到表被初始化。 具体请参阅[数据初始化和迁移一节中的示例](#数据初始化和迁移)

需要注意的是，如果是在一个有多个节点的分布式系统中运行 Mnesia，必须要在每一个参与的节点上面运行 `Mnesia.start/1`。

## 创建表

我们可以用 `Mnesia.create_table/2` 在数据库中创建表。下面的例子中，我们创建了一个名为 `Person` 的表，并且通过一个关键字列表来定义结构。

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

我们使用原子 `:id`, `:name` 和 `:job` 定义了表的字段。第一个原子作为主键(也就是 `:id`)，并且至少需要一个附加属性。
当我们执行 `Mnesia.create_table/2` 可能返回下面两种结果中的任意一种：

 - `{:atomic, :ok}` 代表执行成功
 - `{:aborted, Reason}` 代表执行失败

如果数据库中已经存在同名的表，返回结果中的 `Reason` 为 `{:already_exists, table}`。所以当我们再执行一次上面的命令是，我们会得到下面的结果：

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## 脏操作

首先我们来学习对 Mnesia 表读写的脏操作方式。一般情况下，我们都不会使用脏操作，因为脏操作并不一定保证成功，但是它可以帮助我们学习和适应 Mnesia 的使用方式。下面让我们往 **Person** 表中添加一些记录。

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

...然后我们可以通过 `Mnesia.dirty_read/1` 来读取数据：

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

如果我们查询的记录不存在时，Mnesia 会返回一个空的列表。

## 事务（Transaction）

我们一般会把我们对数据库的读写包在一个数据库事务里面。对事务的支持对设计容错系统和分布式系统非常重要。Mnesia 的事务是通过对数据库的多个操作包含到一个函数体中来实现。首先我们创建一个匿名函数，如此例中的 `data_to_write`，然后把这个函数传给 `Mnesia.transaction`。

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```

从 IEx 中打印的消息来看，我们可以安全地假设数据已经被成功地写进了 `Person` 表。我们来验证一下使用事务从数据库里面读出刚刚写入的数据。我们可以用 `Mnesia.read/1` 来从数据库里面读取数据，同样的，我们也需要使用一个匿名函数。

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

如果你想要更新数据，你还是调用 `Mnesia.write/1`，只要记录里面的 key 和现有记录的 key 相同即可。要更新 Hans 那条记录的话，可以这样做：

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## 使用索引

Mnesia 也支持在非主键字段上添加索引，然后通过这个索引来查询数据。我们来试下在 `Person` 表的 `:job` 字段上添加索引：

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

结果跟 `Mnesia.create_table/2` 返回的相同：

 - `{:atomic, :ok}` 表示执行成功
 - `{:aborted, Reason}` 表示执行失败


类似的，如果索引已经存在，返回结果中的 `Reason` 为 `{:already_exists, table, attribute_index}`。所以当我们再执行一次上面的命令是，我们会得到下面的结果：

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

创建索引成功后，我们可以通过索引来获取数据。下面的例子中使用 `Mnesia.index_read/2` 来获取工作是 `Principal` 的记录：

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## 匹配和选择

Mnesia支持复杂查询，以匹配和临时选择函数的形式从表中检索数据。

`Mnesia.match_object/1` 函数可以通过模式匹配取回所有匹配的记录。如果有为任何一个字段添加索引的话，查询的效率会更高。不想某个字段参与匹配的话，可以用一个特殊的原子 `:_` 来替代。

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

`Mnesia.select/2` 函数允许我们通过一个查询函数来查询数据。下面的例子是选择所有 key 大于 3 的记录：

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

让我们来仔细看上面的例子。第一个参数是表名，`Person`，第二个参数是 `{match, [guard], [result]}`这样的形式：

- `match` 跟你传给 `Mnesia.match_object/1` 函数的那个参数一样；但是请注意那个特别的原子`:"$n"`是用来指定后面部分的参数位置。
- `guard` 列表里面包含了你想要应用的过滤函数和这个函数的参数的元组。在本例中， 是由内置函数 `:>` , 位置参数 `:$1`以及常数 `3` 组成。
- `result` 列表是你希望查询返回的结果的字段的列表。`:"$$"` 用来表示返回所有字段，你也可以用 `[:"$1", :"$2"]` 来返回头两个字段。

更多的信息请参考 Erlang 的[官方文档](http://erlang.org/doc/man/mnesia.html#select-2).

## 数据初始化和迁移

不管是什么软件解决方案，都会碰到需要更新你的系统并且迁移你数据库里的数据的时候。比方说，你在你的系统的第二版中需要往 `Person` 表中添加一个 `:age` 字段。我们不能再重新创建一个 `Person` 表了，但是我们可以改造这张表，我们还需要知道什么时候需要更改表。要实现这个，我们可以用 `Mnesia.table_info/2` 函数获取现在的表结构，以及通过 `Mnesia.transform_table/3` 函数来改变表结构。

在下面的代码中，我们要实现这些逻辑：

* 创建 v2 的表结构，包括这些属性： `[:id, :name, :job, :age]`
* 根据建表函数的返回结果分别处理：
    * `{:atomic, :ok}`: 为 `Person` 表的 `:job` 和 `:age` 字段添加索引
    * `{:aborted, {:already_exists, Person}}`: 检查现有的字段并且做相应的处理：
        * 如果是 v1 的字段列表 (`[:id, :name, :job]`)，改造表结构，给所有人的年龄设为 21 并且在 `:age` 上添加索引
        * 如果已经是我们想要的 v2 的字段列表，则无需做任何处理
        * 如果是其他情况，则返回错误

如果我们在用 `Mnesia.start/0` 启动 Mnesia 后马上对现有的表进行任何操作的话，那些表可能还没有初始化，并且无法访问。在这样的情况下，我们应该使用 [`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2) 函数。它会挂起当前的进程，直到数据库表初始化完毕，或者超时。

`Mnesia.transform_table/3` 函数接受的参数列表为，表名和一个把旧的数据格式转换为新的数据格式的函数。

```elixir
case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
  {:atomic, :ok} ->
    Mnesia.add_table_index(Person, :job)
    Mnesia.add_table_index(Person, :age)
  {:aborted, {:already_exists, Person}} ->
    case Mnesia.table_info(Person, :attributes) do
      [:id, :name, :job] ->
        Mnesia.wait_for_tables([Person], 5000)
        Mnesia.transform_table(
          Person,
          fn ({Person, id, name, job}) ->
            {Person, id, name, job, 21}
          end,
          [:id, :name, :job, :age]
          )
        Mnesia.add_table_index(Person, :age)
      [:id, :name, :job, :age] ->
        :ok
      other ->
        {:error, other}
    end
end
```
