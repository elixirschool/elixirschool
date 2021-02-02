%{
  version: "1.1.0",
  title: "错误处理",
  excerpt: """
  Elixir 通常会返回 `{:error, reason}` 元组来表示错误, 但也支持产生异常. 这节课我们来看看都有那些处理错误的方式, 以及我们该怎样处理错误.

一般情况下在 Elixir 中 (`example/1`) 的函数会返回 `{:ok, result}` 或 `{:error, reason}`. 另一个 (`example!/1`)  的函数会返回 unwrapped 的结果或者触发一个错误.

这节课我们将关注后者.
  """
}
---

## 约定习俗

当前，Elixir 社区在返回错误方面有这么一些约定：

* 对于那些作为一个函数功能相关的错误（比如：用户输入了一个错误的日期类型值），这个函数应当相应地返回 `{:ok, result}` 和 `{:error, reason}`。  
* 对于那些和函数功能无关的错误（比如：无法正确解析配置的参数），则需要抛出异常。  

我们一般都使用[模式匹配](../basics/pattern-matching/)的方式来处理错误流程。但是，本课程将主要关注另一种场景 - 异常处理。

通常，我们会在一些公开的 API 里发现带有一个感叹号版本的函数，如 (example!/1)。这些函数会返回一个未封包的结果，或者直接抛出一个错误。

## Error Handling

在处理错误前我们需要先创建他们. 最简单的方式是使用 `raise/1` 函数:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

如果我们需要指定错误类型和错误信息, 就需要使用 `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

在可能产生错误的地方, 我们可以用 `try/rescue` 和模式匹配来处理:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occurred: Oh no!
:ok
```

也可以在一个`rescue`中匹配多个错误:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file option")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

有些时候无论是否产生错误都需要在 `try/rescue` 后执行一些操作. 这种情况我们可以使用 `try/after`. 这就像 Ruby 中的 `begin/rescue/ensure` 或者 Java 中的 `try/catch/finally`:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

最常见的用法是处理需要关闭的文件和连接:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## New Errors

虽然Elixir 包含了一些像 `RuntimeError` 的内建错误类型, 但如果需要仍可以创建我们自己的错误类型. 使用 `defexception/1` 宏可以轻易的创建一个新的错误类型, 并且可以通过 `:message` 参数来设置默认的错误信息:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

来试试我们的新错误类型:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Throws

Elixir 另一个处理错误的方式是 `throw` 和 `catch`. 事实上他们在新一些的 Elixir 代码中出现的非常少, 但无论如何知道并理解他们还是很重要的.

`throw/1` 函数可以让我们指定一个值并从当前执行流程中退出, 使用 `catch` 可以获取到这个值来进行使用:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

像上面提到的, `throw/catch` 非常少见, 通常在 library 提供的 API 不够完善时来产生缺省的错误信息.

## Exiting

Elixir 中最后一个产生错误的方式是 `exit`. 当进程死掉的时候会产生退出信号, 它也是 Elixir 容错机制重要的一部分.

我们用 `exit/1` 来显示的退出:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

虽然可以使用 `try/catch` 来捕获退出, 但这样的做法非常少见. 大多数的情况下使用 supervisor 来处理进程的退出更好:

```elixir
iex> try do
...>   exit "oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
