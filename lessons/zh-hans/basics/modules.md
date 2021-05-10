%{
  version: "1.4.2",
  title: "模块（Module）",
  excerpt: """
  根据以往的经验，我们知道把所有的函数都放到同一个文件是不可控的。这节课我们就讲一下如何给函数分组，以及如何定义一种叫结构体的特殊映射来有效地组织代码。
  """
}
---

## 模块

模块可以让我们把函数组织到不同命名空间。除了能为函数分组，它还允许我们定义命名函数和私有函数，这个已经在[前面](../functions/)讲过。

我们来看一个简单的例子：

``` elixir
defmodule Example do
  def greeting(name) do
    "Hello #{name}."
  end
end

iex> Example.greeting "Sean"
"Hello Sean."
```

Elixir 也允许嵌套的模块，这让你可以轻松定义多层命名空间：

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Good morning #{name}."
  end

  def evening(name) do
    "Good night #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Good morning Sean."
```

### 模块属性

模块的属性通常被用作常量，来看一下简单的例子：

```elixir
defmodule Example do
  @greeting "Hello"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

需要注意有些属性是保留的，最常用到的三个为：

+ `moduledoc` — 当前模块的文档
+ `doc` — 函数和宏的文档
+ `behaviour` — 使用 OTP 或者用户定义的行为

## 结构体

结构体是字典的特殊形式，它们的键是预定义的，一般都有默认值。结构体必须定义在某个模块内部，因此也必须通过模块的命名空间来访问。
经常一个模块就为了定义一个结构体，其他什么也没有。

要定义一个结构体，我们使用 `defstruct` 关键字，后面跟着关键字列表和默认值：

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

我们来创建一些结构体：

```elixir
iex> %Example.User{}
%Example.User<name: "Sean", roles: [], ...>

iex> %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [], ...>

iex> %Example.User{name: "Steve", roles: [:manager]}
%Example.User<name: "Steve", roles: [:manager]>
```

我们也可以像更新映射（map）那样更新结构体：

```elixir
iex> steve = %Example.User{name: "Steve"}
%Example.User<name: "Steve", roles: [...], ...>
iex> sean = %{steve | name: "Sean"}
%Example.User<name: "Sean", roles: [...], ...>
```

更重要的是：结构体可以匹配映射（maps）：

```elixir
iex> %{name: "Sean"} = sean
%Example.User<name: "Sean", roles: [...], ...>
```

到了 Elixir 1.8，结构体允许包含自定义的检查方式。以下通过查看 `sean` 结构来理解这是如何实现的：

```elixir
iex> inspect(sean)
"%Example.User<name: \"Sean\", roles: [...], ...>"
```

在这里例子，结构体里面所有的字段都展示出来并没有问题。但是，如果我们想排除一些保护字段呢？新的 `@derive` 功能就能实现这点了。如下修改一下样例中的 `roles` 字段，它就不会包含在输出里面了：

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]}
  defstruct name: nil, roles: []
end
```

_备注_：我们也可以使用 `@derive {Inspect, except: [:roles]}`，效果是一样的。

让我们看看更新后的模块在 `iex` 中的表现：

```elixir
iex> sean = %Example.User{name: "Sean"}
%Example.User<name: "Sean", ...>
iex> inspect(sean)
"%Example.User<name: \"Sean\", ...>"
```

`roles` 字段排除在外了！

## 组合（Composition）

我们知道了如何创建模块和结构体之后，现在我们来学习如何通过组合的方式为模块中添加新的功能。
Elixir 提供了好几种让我们可以在模块中访问到其他模块的方式。

### alias

在 Elixir 中非常常见，可以让我们通过别名去访问模块：

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Hi, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Without alias

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

如果别名有冲突，或者我们想要给那个模块命一个不同的名字时，我们可以用 `:as` 参数：

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Elixir 也允许一次指定多个别名：

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### import

我们可以用 `import` 从另一个模块中导入函数：

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### 过滤

默认情况下，`import` 会导入模块中的所有函数和宏（Macro），我们可以通过 `:only` 和 `:except` 来过滤导入当前模块的函数和宏：

要导入指定的函数和宏是，我们需要提供函数名+函数的元数给 `:only` 和 `:except`。让我们只导入`last/1` 这个函数：

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

我们再试下导入除`last/1`之外的其他所有函数：

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

除了指定函数名之外，Elixir 还提供了两个特殊的原子，`:functions` 和 `:macros`，来让我们只导入函数或宏：

```elixir
import List, only: :functions
import List, only: :macros
```

### require

`require` 用来告诉 Elixir 我们要调用其他模块中的宏。跟 `import` 的区别是，`require` 对宏有效，而对函数无效：

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

如果我们调用了未被加载的宏，Elixir 会报错。

### use

`use` 用来修改我们当前的模块。当我们在当前模块中调用 `use` 时，Elixir 会执行指定模块中所定义的 `__using__` 回调。

`__using__` 回调执行的结果会成为当前模块定义的一部分。我们来看下面的例子以便更好地理解 `use` 的用法：

```elixir
defmodule Hello do
  defmacro __using__(_opts) do
    quote do
      def hello(name), do: "Hi, #{name}"
    end
  end
end
```

这里我们在 `Hello`模块中定义了 `__using__` 回调，回调中定义了一个名为`hello/1`的函数。
接着，我们创建一个新模块来使用上面的代码：

```elixir
defmodule Example do
  use Hello
end
```

在 IEx 中，我们可以看到 `hello/1` 这个函数是存在我们的 `Example` 模块中的：

```elixir
iex> Example.hello("Sean")
"Hi, Sean"
```

上面的例子展示了 `__using__/1` 回调的基本用法，将 `Hello` 模块中的`__using__/1`回调的执行结果添加到了 `Example` 模块中，成了`Example`模块定义的一部分。

现在我们来学习如何应用`__using__/1`回调中的参数。 让我们来为上面例子中的`__using_`回调添加一个 `greeting` 参数：

```elixir
defmodule Hello do
  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "Hi")

    quote do
      def hello(name), do: unquote(greeting) <> ", " <> name
    end
  end
end
```

然后我们在 `Example` 模块中使用新加的这个 `greeting` 参数：

```elixir
defmodule Example do
  use Hello, greeting: "Hola"
end
```

我们打开 IEx 来验证 `greeting` 的内容已经被改变了：

```
iex> Example.hello("Sean")
"Hola, Sean"
```

上面这些简单的例子展示了 `use` 的用法。`use` 是 Elixir 工具箱中非常强大的一个。在你学习 Elixir 的过程中，多留意一下， 你会看到很多使用 `use` 的地方，之前我们已经遇到过的一个例子就是 `use ExUnit.Case, async: true`。

**注意**: `quote`, `alias`, `use`, `require` 都是宏，我们会在[元编程](../../advanced/metaprogramming)一节学到更多有关宏的知识。
