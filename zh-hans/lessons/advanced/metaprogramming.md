---
version: 1.0.2
title: 元编程
---

元编程是指用代码来写代码的过程。在 Elixir 中，这说明我们可以扩展该语言，动态地修改该语言来满足我们的需求。我们会先看看 Elixir 底层是怎么实现的，然后讲怎么修改它，最后会使用刚学过的知识来扩展它。  

忠告：元编程不容易用好，只有在绝对需要的时候才去使用它。过度使用元编程会导致代码很复杂，不容易理解和调试。  

{% include toc.html %}

## Quote

学习元编程的第一步是理解表达式是怎么表示的。Elixir 的 AST（抽象语法树）是由元组构成的。这些元组包含了三个部分：函数名称，metadata，还有函数的参数。  

Elixir 提供了 `quote/2` 函数，可以让我们看到这些内部结构。也就是说，`quote/2` 能把 Elixir 代码转换成代码的底层表示形式。  

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

注意到前面三个并没有返回列表了吗？这五种字面量（literal）使用 quote 的返回值是它们自身：  

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

知道了如何获取代码的内部表示，那怎么修改它呢？我们依靠 `unquote/1` 来插入新的代码和值。当我们 unquote 一个表达式的时候，会把它运行的结果插入到 AST。我们来看个例子理解一下 `unquote/2` 的用法:  

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

在第一个的例子里，变量 `denominator` 在 quote 的时候会导致生成的 AST 包含了一个访问了这个变量的列表。而在使用 `unquote/1` 的例子里，生成的代码就直接包含了 `denominator` 的值。  

## 宏

理解了 `quote/2` 和 `unquote/1`，我们就可以开始深入学习宏了。要注意的是：宏和元编程一样，必须谨慎使用。  

简单来说，宏就是一个特别的函数：它返回的 quoted 的表达式，会被插入到应用的代码中。可以想象宏被 quoted 后的表达式替代，而不是像函数那样被调用。有了宏，我们就能够扩展 Elixir 和动态地为应用添加代码了。  

定义宏需要用 `defmacro/2`，这在 Elixir 中也是一个宏(花点时间慢慢领会)。在以下例子中，我们会实现 `unless` 这个宏。记住，宏需要返回 quoted 后的表达式：  

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

导入模块，测试一下我们刚定义的宏：  

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

因为宏会替换应用中的代码，所以我们能控制把代码替换成什么，也能控制在什么情况下进行替换。`Logger` 模块就是很好的例子，如果 logging 被禁止了，就不会有代码被插入，最终的代码也不会有调用 logging 的逻辑。和其他语言的区别在于：其他语言在 logging 被禁止的时候，还会有 logging 相关的代码存在，即使里面的实现是空的。  

我们写一个简单的 logger 来说明这一点。我们的 logger 可以通过环境变量来开启或禁止：  

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

当 logging 开启的时候，我们的 `test` 函数的代码会是下面的样子：  

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

如果我们禁止了 logging，最终的代码就变成了：  

```elixir
def test do
end
```

## 调试

好了，现在我们知道如何使用 `quote/2`, `unquote/1` 和编写宏了。但是，如果你面对的是一大段 quoted 的代码，并希望理解它怎么办？这种情况下，你可以使用 `Macro.to_string/2`。来看看下面的例子：  

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

当你想查看通过宏生成出来的代码，你可以结合 `Macro.expand/2` 和 `Macro.expand_once/2` 的使用，这些函数会把提供给宏的原来的 quoted 的代码展开出来。第一个函数可以展开多次，而后者只展开一次。比如，我们可以把 `unless` 这个例子从前面的方案修改如下：  

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

如果我们使用 `Macro.expand/2` 来运行同样的代码，最终的结果则相当有趣：  

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

或许你还记得，我们曾经提过，`if` 在 Elixir 里面也是一个宏。在这里，我们就可以看到它底下的 `case` 表达式被扩展出来了。  

### 私有宏

尽管不常使用，Elixir 还支持私有宏。私有宏通过 `defmacrop` 定义，只能在定义的模块中被调用。私有宏必须在调用它的代码之前定义。

### 宏清洁

宏清洁是指：宏和调用的上下文交互的过程。默认情况下，Elixir 中的宏是洁净的：也就是说，它不会和调用者的上下文冲突：

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

但是如果我们希望在宏里面修改 `val` 变量呢？使用 `var!/2` 可以让某个变量的操作变成对上下文变量的操作。在我们的例子中，添加另外一个使用 `var!/2` 的宏：

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

然后比较一下它们是怎么和代码的上下文交互的：

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

使用 `var!/2`，我们可以直接操作 `val` 变量而不需要它作为参数传递给宏。宏的这种使用方式应该尽少使用，引入 `var!/2` 会增加变量冲突的风险。

### 绑定

我们已经介绍过 `unquote/1` 的用法，但是还有另外一种方法可以在代码中插入值：绑定。使用变量绑定，我们能够在宏中多次使用变量，并且保证它们只会被计算一次，从而避免意外的重新计算。要使用绑定变量，我们必须传一个关键字列表 `bind_quoted` 作为 `quote/2` 的选项。

为了理解 `bind_quote` 的好处和重新计算的问题，我们来看个例子。创建一下把某个表达式的值打印两遍的宏：

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

我们把当前的系统时间传递过去，来测试一下刚定义的宏，期望是：它把当前时间打印两遍：

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

两次的时间居然不一样！什么鬼？对同一个表达式多次使用 `unquote/1` 会重新计算表达式的值，这会导致意想不到的错误。我们来更新一下例子，看看使用 `bind_quoted` 的结果：

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

使用 `bind_quoted` 和我们预期的结果是一致的：当前的时间被打印两次。

现在我们已经学完了 `quote/2`，`unquote/1` 和 `defmacro/2`，这些工具已经足够我们按照需要扩展 Elixir 了。
