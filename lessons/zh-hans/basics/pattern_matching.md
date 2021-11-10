%{
  version: "1.0.2",
  title: "模式匹配",
  excerpt: """
  模式匹配是 Elixir 很强大的特性，它允许我们匹配简单值、数据结构、甚至函数。这篇课程，我们介绍如何使用模式匹配。
  """
}
---

匹配操作符
----------

做好心理准备了吗？ Elixir 中，`=` 操作符就是我们的匹配操作符，跟代数里面的等号类似。在 Elixir 当中，用 `=` 来使得左右两边的值相等。如果匹配成功，即左右值相等后，返回这个等式的值。如果两边的值无法匹配，Elixir 则会抛出错误。 我们来看几个例子：

```elixir
iex> x = 1
1
```

现在，试一些简单的匹配：

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

然后试一些刚学过的集合类型：

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2|_] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Tuples
iex> {:ok, value} = {:ok, "Successful!"}
{:ok, "Successful!"}
iex> value
"Successful!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

Pin 操作符
----------

我们刚学到，当匹配的左边包含变量的时候，匹配操作符同时会做赋值操作。有些时候，这种行为并不是预期的，这种情况下，我们可以使用 `^` 操作符。

使用 pin 操作符，我们就是用已经绑定的值去匹配，而不是重新绑定一个新值，让我们来看一下 pin 操作符是怎么工作的吧：

```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Elixir 1.2 开始支持对映射（Map）中的键（Key）以及匹配函数子句（function clause）：

```elixir
iex> key = "hello"
"hello"
iex> %{^key => value} = %{"hello" => "world"}
%{"hello" => "world"}
iex> value
"world"
iex> %{^key => value} = %{:hello => "world"}
** (MatchError) no match of right hand side value: %{hello: "world"}
```

下面是在函数子句中应用 pin 操作符的例子：

```elixir
iex> greeting = "Hello"
"Hello"
iex> greet = fn
...>   (^greeting, name) -> "Hi #{name}"
...>   (greeting, name) -> "#{greeting}, #{name}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Hello", "Sean")
"Hi Sean"
iex> greet.("Mornin'", "Sean")
"Mornin', Sean"
iex> greeting
"Hello"
```

在上面的例子中，对 `greeting` 重新赋值只是发生在函数里面，函数体以外，`greeting` 的值一直是 `"Hello"`，不会因为函数调用而改变。
