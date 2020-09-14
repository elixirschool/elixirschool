---
version: 1.0.2
title: 和 Erlang 互操作
---

在 Erlang VM (BEAM) 上构建 Elixir 的好处之一就是已经有大量的库可以供我们使用。互操作性允许我们在 Elixir 代码中直接使用 Erlang 的标准库和三方库。这节课，我们就讲讲如何来做。  

{% include toc.html %}

## 标准库

在任何 Elixir 代码中都能直接使用 Erlang 提供的标准库，Erlang 的模块用小写的原子变量表示，比如 `:os` 和 `:timer`。  

我们可以用 `timer.tc` 计算某个函数执行的时间：  

```elixir
defmodule Example do
  def timed(fun, args) do
    {time, result} = :timer.tc(fun, args)
    IO.puts("Time: #{time} μs")
    IO.puts("Result: #{result}")
  end
end

iex> Example.timed(fn (n) -> (n * n) * n end, [100])
Time: 8 μs
Result: 1000000
```

要了解所有可用的模块，请看 [Erlang 参考手册](http://erlang.org/doc/apps/stdlib/)。  

## Erlang 第三方依赖

在之前的课程中，我们讲过如何使用 Mix 和管理依赖。要引入 Erlang 的依赖，方法也是一样的。如果依赖的 Erlang 库不在 [hex](https://hex.pm)，你也可以直接使用 git 代码库的地址：  

```elixir
def deps do
  [{:png, github: "yuce/png"}]
end
```

然后我们就可以用 Erlang 的库了：  

```elixir
png =
  :png.create(%{:size => {30, 30}, :mode => {:indexed, 8}, :file => file, :palette => palette})
```

## 区别

知道了怎么在 Elixir 中使用 Erlang ，我们还要讲讲操作 Erlang 语言会遇到的坑：  

### 原子

Erlang 的原子和 Elixir 很相似，只是没有前面的冒号（`:`），Erlang 中的原子是小写字母和下划线的组合。  

Elixir:  

```elixir
:example
```

Erlang:  

```erlang
example.
```

### 字符串

在 Elixir 里面，字符串表达的是 UTF-8 编码的二进制数据。而在 Erlang，字符串还是使用双引号表示，但是却是字符列表。  

Elixir:  

```elixir
iex> is_list('Example')
true
iex> is_list("Example")
false
iex> is_binary("Example")
true
iex> <<"Example">> === "Example"
true
```

Erlang:  

```erlang
1> is_list('Example').
false
2> is_list("Example").
true
3> is_binary("Example").
false
4> is_binary(<<"Example">>).
true
```

需要特别注意的是，有些 Erlang 的库不支持二进制数据，我们要把 Elixir 字符串转换成字符列表。还好，`to_charlist/1` 函数可以帮我们轻松完成这个转换。  

```elixir
iex> :string.words("Hello World")
** (FunctionClauseError) no function clause matching in :string.strip_left/2

    The following arguments were given to :string.strip_left/2:

        # 1
        "Hello World"

        # 2
        32

    (stdlib) string.erl:1661: :string.strip_left/2
    (stdlib) string.erl:1659: :string.strip/3
    (stdlib) string.erl:1597: :string.words/2

iex> "Hello World" |> to_charlist() |> :string.words()
2
```

### 变量

在 Erlang 中，变量是以大写的字符开头，并且不允许重新绑定

Elixir:  

```elixir
iex> x = 10
10

iex> x = 20
20

iex> x1 = x + 10
30
```

Erlang:  

```erlang
1> X = 10.
10

2> X = 20.
** exception error: no match of right hand side value 20

3> X1 = X + 10
20
```

就这么多！在 Elixir 应用中使用 Erlang 简单高效，把原来可用的库直接加倍啦！  
