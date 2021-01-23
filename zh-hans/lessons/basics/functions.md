---
version: 1.2.0
title: 函数
---

Elixir 和其他函数式语言一样，函数都是一等公民。我们将学习 Elixir 中不同类型的函数，它们与众不同的地方，以及如何使用它们。

{% include toc.html %}

## 匿名函数

就像名字中说明的那样，匿名函数没有名字。我们在 `Enum` 课程中看到过，它们经常被用来传递给其他函数。
要定义匿名函数，我们需要 `fn` 和 `end` 关键字，在这两者之间，我们可以定义任意数量的参数和函数体，它们用 `->` 分隔开。

我们来看一个简单的例子：

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

###  & 操作符

因为在 Elixir 中使用匿名函数非常常见，所以有一个快捷方式来做这件事：

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

你可能也猜到了，在这种简写的模式下，函数的参数可以通过 `&1`，`&2`，`&3` 等来获取。

## 模式匹配

在 Elixir 中模式匹配不仅限于变量，也可以用在函数签名上，我们在后面章节会看到这个功能。
Elixir 使用模式匹配来找到第一个匹配参数的模式，然后执行它后面的函数体。

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## 命名函数

我们也可以定义有名字的函数，这样在后面可以直接用名字来使用它。命名函数通过 `def` 关键字定义在某个模块中，关于模块，我们会在后面的课程中详细学习，
现在我们只关心命名函数。

定义在模块内部的函数可以被其他模块使用，这在 Elixir 中构建代码块非常有用：

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

如果我们的函数体只有一行，我们可以缩写成 `do:`：

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
end
```

学到了那么多模式匹配的知识，现在我们用命名函数实现递归：

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### 函数名字和元数

我们之前提到过，函数名称方式由名字和元数组成，这也表明你可以这么做：

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

我们在上面代码注释中列出了函数的全称。第一个函数不接受任何参数，因此是 `hello/0`；第二个函数接受一个参数，因此是 `hello/1`，以此类推。不同于其他语言的函数重载，这些函数被认为是不同的。（刚刚提到过的模式匹配，只有当函数名字和接受的参数个数都匹配的时候才成立。）

### 函数和模式匹配

函数调用的背后，其实使用了叫模式匹配的方式来处理传入的参数。

比如说，我们的一个方法接收一个 map 作为参数。但是，我们只对其中的某一个键值感兴趣。那么，我们可以这样来模式匹配函数调用时需要的键值：

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

假设我们现在有一个字典，里面包含了一个人的名字，Fred：

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"  
...> }
```

下面就是我们调用 `Greeter1.hello/1` 并传入字典 `fred` 后得到的结果：

```elixir
# 传入整个字典
...> Greeter1.hello(fred)
"Hello, Fred"
```

那如果我们调用函数的时候，字典里面 _没有_ 包含 `:name` 这个键呢？

```elixir
# 传入一个不包含相应键值的字典后，会产生如下错误
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter3.hello/1    

    The following arguments were given to Greeter3.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter3.hello/1

```

这个表现行为，是由于 Elixir 在处理函数调用的时候，需要模式匹配相应的参数。

当 `Greeter1.hello/1` 被调用时，它的数据应该是这样的：

```Elixir
# 传入的字典
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"  
...> }
```

`Greeter1.hello/1` 期望的参数则是：

```elixir
%{name: person_name}
```

在函数 `Greeter1.hello/1` 里, 我们传入的字典（`fred`）就会和定义的参数（`%{name: person_name}`）进行匹配：

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

当它在传入的字典中找到相应的键 `:name` 时，这个匹配就成立了。匹配成功的结果就是，右边字典中 `:name` 键对应的值（在 `fred` 字典中），就赋予到左边的变量（`person_name`）上。

那么，如果我们除了希望把 Fred 的姓名赋值到 `person_name` 外，我们还希望保留整个人物信息的字典，要怎么做呢？比如说我们希望在和他打招呼后运行 `IO.inspect(fred)`。上面的做法，因为我们只是模式匹配了 `:name` 这个键值，也因此只是把它的值赋予了一个变量，函数本身并不知道 Fred 其它的信息。

为了保存所有的数据，我们需要把整个字典，赋予一个它专属的变量。

我们来定义一个新的函数：

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

由于 Elixir 会模式匹配传入的参数，所以，在这种情况下，两边都会匹配传入的参数，来绑定任何能匹配上的部分。首先，我们来看看右边的部分：

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

也就是说，`person` 被绑定并赋值为整个 fred 字典上。而下一个模式匹配就会是这样：

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

这就和最开始的 `Greeter1` 函数，传入整个字典，但是只匹配保留 Fred 的名字情况是一样的。这样我们就定义了两个变量，而不是一个了：

1. `person`，指向 `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name`，指向 `"Fred"`

所以，当我们调用 `Greeter2.hello/1` 时，我们就可以使用上 Fred 的所有数据了：

```elixir
# 传入整个人的资料
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}

# 传入只是包含了 name 键值的字典
...> Greeter4.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}

# 传入不包含 name 键值的字典
...> Greeter4.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1    

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

所以，Elixir 的模式匹配能按传入的数据，独立匹配每一个参数。

如果我们改变 `%{name: person_name}` 和 `person` 的顺序，结果还是一样的。比如：

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

然后和调用 `Greeter2.hello/1` 一样传入同样的数据：

```elixir
# 还是传入 fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

记住，虽然看起来 `%{name: person_name} = person}` 这个表达式是把 `%{name: person_name}` 模式匹配到 `person` 这个变量上，其实是它们 _各自_ 匹配到传入的参数上。

**总结:** 函数按传入的数据，各自独立匹配相应的参数。我们可以在函数内绑定多个独立的变量。

### 私有函数

如果我们不想其他模块使用某个函数，我们可以使用私有函数，也就是只能被它所在模块调用的函数。在 Elixir 中，我们可以用 `defp` 来定义私有函数：

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### 哨兵子句（Guard）

我们在[控制语句](../control-structures)那一个提过哨兵子句，现在我们就来看看怎么在命名函数中使用它们。当 Elixir 匹配某个函数之后，后面的哨兵子句都会被检测。

在下面的例子中，我们定义了两个有相同签名的函数，而依赖判断参数类型的哨兵子句来确定调用哪个函数：

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
```

### 默认参数

如果想给参数设置默认值，我们可以用 `argument \\ value` 语法：

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "es")
"Hola, Sean"
```

当我们同时使用卫兵和默认参数值的时候，会遇到问题，先看一下程序会报什么错：

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Elixir 在处理多个匹配函数的时候，不喜欢默认参数这种模式，因为它很容易让人混淆。要处理这种情况，我们可以添加一个设置了默认参数值的函数头部：

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "es"
"Hola, Sean, Steve"
```
