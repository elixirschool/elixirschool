%{
  version: "1.0.1",
  title: "行为",
  excerpt: """
  我们在前面的课程学习了类型和 specification。那么，这一章我们将学习如何引用一个模块来实现那些 specification。在 Elixir 里，这个功能被称之为行为。
  """
}
---

## 使用场景

有时候，你希望一些模块能够分享一个开放的 API 接口，在 Elixir 里的解决方案就是行为。行为承担了两大角色：  

+ 定义一组需要被实现的函数  
+ 检查这组函数是否真的被实现  

Elixir 预定义了好一些行为，例如 `GenServer`，但是，本次课程我们的重点是创建我们自己的行为。  

## 定义一个行为

为了更好的理解行为，让我们为 worker 模块来具体实现一组行为。这些 workers 都应该实现两个函数：`init/1` 和 `perform/2`。  

实现的方式是，我们要使用和 `@spec` 语法类似的 `@callback` 注解。这个注解定义了 __required__ 函数；对于宏来说，我们可以使用 `@macrocallback`。让我们看看 `init/1` 和 `perform/2` 在 workers 里怎么定义：  

```elixir
defmodule Example.Worker do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

这里我们定义了 `init/1` 作为一个接收任何参数，并返回一个 值为 `{:ok, state}` 或 `{:error, reason}` 的 Tuple（元组）。这是一个很典型的初始化方式。`perform/2` 函数则接收一些参数，以及初始化后的状态。`perform/2` 的返回值则是 `{:ok, result, state}` 或者 `{:error, reason, state}`，很像 GenServers。  

## 实现使用行为

既然已经定义好我们的行为，下一步我们也就可以使用它们来创建一些拥有同样的开放的 API 接口的模块了。在模块中添加行为非常简单，我们只需要使用 `@behaviour` 属性。  

让我们来创建一个使用了这些新行为的模块，它的功能是可以把远端的一个文件下载到本地：  

```elixir
defmodule Example.Downloader do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(url, opts) do
    url
    |> HTTPoison.get!()
    |> Map.fetch(:body)
    |> write_file(opts[:path])
    |> respond(opts)
  end

  defp write_file(:error, _), do: {:error, :missing_body}

  defp write_file({:ok, contents}, path) do
    path
    |> Path.expand()
    |> File.write(contents)
  end

  defp respond(:ok, opts), do: {:ok, opts[:path], opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

或者，一个能压缩一个数组的文件的 worker？这也是可行的：  

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

虽然它们的功能很不一样，但是这些开放的 API 接口却是相同的。任何使用了这些模块的代码，都能非常确定这些模块的行为和返回和期望是一致的。这使得我们可以创建任何数量的 worker，即便各自执行不同的任务，但是仍然符合一致的开放 API 接口。  

如果我们添加了某个行为，但是没有把所有的函数都实现，代码在编译期就会给出一个警告。我们马上修改一下 `Example.Compressor`，删除 `init/1` 函数，看看情况会是怎么样：  

```elixir
defmodule Example.Compressor do
  @behaviour Example.Worker

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

我们现在编译代码的话，应该会出现这样的警告：  

```shell
lib/example/compressor.ex:1: warning: undefined behaviour function init/1 (for behaviour Example.Worker)
Compiled lib/example/compressor.ex
```

大功告成！现在我们已经有能力制定和分享行为给其他人了。  
