---
version: 1.0.1
title: 管道操作符
---

管道操作符 `|>` 把前一个表达式的结果作为第一个参数传递给后一个的表达式。

{% include toc.html %}

## 简介

程序的逻辑可能很混乱，比如函数调用有多层嵌套时就很难阅读，看下面这个例子：

```elixir
foo(bar(baz(new_function(other_function()))))
```

这个例子中，我们把 `other_function/0` 的值传递给 `new_function/1`，把 `new_function/1` 的值传递给 `baz/1`，把 `baz/1` 的值传递给 `bar/1`，最后把 `bar/1` 的结果传递给 `foo/1`。Elixir 给我们提供了管道操作符来解决这个语法上的混乱。管道操作符 `|>` *获取一个表达式的结果，并把它往后传递。* 我们把上面的代码用管道重写看看：

```elixir
other_function() |> new_function() |> baz() |> bar() |> foo()
```

管道获取左边的值，并把它传递给右边。

## 示例

对于下面的例子，我们会用到 Elixir 的 String 模块：

- 字符分组

```elixir
iex> "Elixir rocks" |> String.split()
["Elixir", "rocks"]
```

- 把所有分组大写

```elixir
iex> "Elixir rocks" |> String.upcase() |> String.split()
["ELIXIR", "ROCKS"]
```

- 检查尾部字符串

```elixir
iex> "elixir" |> String.ends_with?("ixir")
true
```

## 最佳实践

如果函数的元数大于 1，一定要使用括号。尽管这个语法对 Elixir 并没有实质上的影响，但是可能会让其他程序员错误理解你的代码。如果我们上面第三个例子中 `String.ends_with?/2` 的括号去掉，会收到下面的警告：

```shell
iex> "elixir" |> String.ends_with? "ixir"
warning: parentheses are required when piping into a function call. For example:

  foo 1 |> bar 2 |> baz 3

is ambiguous and should be written as

  foo(1) |> bar(2) |> baz(3)

true
```
