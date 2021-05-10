%{
  version: "1.0.0",
  title: "Bypass",
  excerpt: """
  测试的时候，很多情况下我们要对外部服务发出请求。我们甚至可能需要模拟不同的场景，比如意外发生的服务器错误。在 Elixir 中要高效地实现上面的功能可得向外获取一些帮助。  

在本章课程中，我们将探索 [bypass](https://github.com/PSPDFKit-labs/bypass) 是如何快速方便地帮助我们在测试中处理这些请求。
  """
}
---

## Bypass 是什么？

[Bypass](https://github.com/PSPDFKit-labs/bypass) 被介绍为 “可快速创建取代实际 HTTP 服务器的自定义 plug，返回预先定义结果给客户端的工具”。  

这是什么意思？Bypass 背后其实是一个假扮为外部服务器，监听请求并返回结果的 OTP 应用。通过返回预定义值，我们可以测试各种可能性，如正常的场景，以及意外的服务中止和错误。这都不需要向外发出任何请求。  

## Bypass 用法

为了更好地展示 Bypass 的功能，我们将创建一个简单的工具应用。它会 ping 一些域名并确保它们在线。我们将创建一个 supervisor 项目，和一个 GenServer，按配置的间隔检查这些域名。在测试中使用 Bypass 可以确保在不同情形下，我们的应用都能正常工作。  

_注意_: 如果你希望获得最终的完整代码，可以到 Elixir School 的 [Clinic](https://github.com/elixirschool/clinic) 项目查看。  

假定我们已经对创建 Mix 项目，添加依赖比较熟悉了，这里就只关注在要测试的代码上。如果你需要稍微做些回顾，请参考我们 [Mix](https://elixirschool.com/en/lessons/basics/mix) 课程的 [New Projects](https://elixirschool.com/en/lessons/basics/mix/#new-projects) 部分。  

让我们先创建一个新的模块，它负责发送请求到那些域名上。通过使用 [HTTPoison](https://github.com/edgurgel/httpoison)，我们新建的函数 `ping/1` 会接收一个 URL 并发出请求。如果请求成功，并接收到 HTTP 200 状态码，这个函数就返回 `{:ok, body}`，否则返回 `{:error, reason}`：  

```elixir
defmodule Clinic.HealthCheck do
  def ping(urls) when is_list(urls), do: Enum.map(urls, &ping/1)

  def ping(url) do
    url
    |> HTTPoison.get()
    |> response()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, body}
  defp response({:ok, %{status_code: status_code}}), do: {:error, "HTTP Status #{status_code}"}
  defp response({:error, %{reason: reason}}), do: {:error, reason}
end
```

你可能发现，我并_没有_使用 GenServer。好处是，隔离开 GenServer 和实际的功能（和关注点），我们能在不引入并行处理的复杂度的情况下，测试我们的代码。  

实际代码已经准备好，是时候开始测试了。在使用 Bypass 以前，我们先要确保它在运行的状态。如下修改 `test/test_helper.exs` 就可以了：  

```elixir
ExUnit.start()
Application.ensure_all_started(:bypass)
```

既然 Bypass 已经能在跑测试用例的时候保持运行，我们马上通过 `test/clinic/health_check_test.exs` 来完成设置。通过在测试用例的 setup 回调中使用 `Bypass.open/1` 来打开连接，Bypass 就能够接收请求了：  

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end
end
```

我们暂且使用 Bypass 的默认端口，但是如果有需要，我们可以提供 `:port` 选项给 `Bypass.open/1` 函数，例如 `Bypass.open(port: 1337)`（下一章节我们就会这么做）。现在 Bypass 已经可以工作了，我们发起一个成功的请求看看：  

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  alias Clinic.HealthCheck

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "request with HTTP 200 response", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}")
  end
end
```

以上的测试应该已经足够简单，运行后应该能看到通过的信息。但是我们还是深入了解每一部分到底做了什么。第一部分是 `Bypass.expect/2` 函数：  

```elixir
Bypass.expect(bypass, fn conn ->
  Plug.Conn.resp(conn, 200, "pong")
end)
```

`Bypass.expect/2` 接收两个参数：Bypass 连接和单参数的函数。这个单参数的函数可以修改连接并返回。它同时也可以检查请求是否符合我们的期望。让我们修改测试的 url，使之包含 `/ping`，并且验证请求的路径和 HTTP method：  

```elixir
test "request with HTTP 200 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    assert "GET" == conn.method
    assert "/ping" == conn.request_path
    Plug.Conn.resp(conn, 200, "pong")
  end)

  assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}/ping")
end
```

测试的最后部分我们使用了 `HealthCheck.ping/1` 并断言返回和期望值相同，但是为什么会引用 `bypass.port` 呢？Bypass 实际上监听了本地的一个端口，并拦截了所有的请求。使用 `bypass.port` 就是获取默认的端口值，因为使用 `Bypass.open/1` 的时候我们并没有指明端口。  

下一步就添加错误场景的测试用例。我们可以像前面的测试那样，做出细微的改变就行了：返回 500 作为状态码，并且断言 `{:error, reason}` 元组就是返回值：  

```elixir
test "request with HTTP 500 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    Plug.Conn.resp(conn, 500, "Server Error")
  end)

  assert {:error, "HTTP Status 500"} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

这个测试用例没什么特别的地方，继续下一个意外服务中断的场景吧。这些情况的请求是我们最担心的地方。我们不会使用 `Bypass.expect/2` 来模拟实现这种情况，而是依靠 `Bypass.down/1` 来中断连接：  

```elixir
test "request with unexpected outage", %{bypass: bypass} do
  Bypass.down(bypass)

  assert {:error, :econnrefused} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

如果运行我们的新测试用例，我们会发现所有的都通过了！既然 `HealthCheck` 模块已经通过了测试，我们可以继续测试基于 GenServer 的定时任务了。  

## 多个外部域名

对于我们项目来说，我们必须保持定时任务的核心，依赖 `Process.send_after/3` 来触发不断重复的检查。要了解更多关于 `Process` 模块，请参考[文档](https://hexdocs.pm/elixir/Process.html)。我们的定时任务需要三个配置参数：网站列表，定时检查的间隔时间，和实现了 `ping/1` 函数的模块。通过传入实现的模块，我们把功能和 GenServer 解耦开，使我们更好地独立测试它们：  

```elixir
def init(opts) do
  sites = Keyword.fetch!(opts, :sites)
  interval = Keyword.fetch!(opts, :interval)
  health_check = Keyword.get(opts, :health_check, HealthCheck)

  Process.send_after(self(), :check, interval)

  {:ok, {health_check, sites}}
end
```

现在我们需要定义 `handle_info/2` 函数接收 `send_after/2` 发送的 `:check` 消息。简单期间，我们把网站列表传给 `HealthCheck.ping/1`，并且把结果通过 `Logger.info` 记录起来，或者用 `Logger.error` 记录错误。迟些我们会再改进我们代码里的日志记录功能：  

```elixir
def handle_info(:check, {health_check, sites}) do
  sites
  |> health_check.ping()
  |> Enum.each(&report/1)

  {:noreply, {health_check, sites}}
end

defp report({:ok, body}), do: Logger.info(body)
defp report({:error, reason}) do
  reason
  |> to_string()
  |> Logger.error()
end
```

如前所述，我们把网站列表传给 `HealthCheck.ping/1`，然后通过 `Enum.each/2` 遍历它们并应用 `report/1` 函数到每个网站上。有了这些函数，定时任务就完成了，我们也就可以关注在测试上面了。  

我们不会在定时任务的单元测试上面花太多的时间，因为那不需要使用到 Bypass。所以，最终的测试代码是：  

```elixir
defmodule Clinic.SchedulerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  defmodule TestCheck do
    def ping(_sites), do: [{:ok, "pong"}, {:error, "HTTP Status 404"}]
  end

  test "health checks are run and results logged" do
    opts = [health_check: TestCheck, interval: 1, sites: ["http://example.com", "http://example.org"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "pong"
    assert output =~ "HTTP Status 404"
  end
end
```

我们依赖 `TestCheck` 实现网站的健康测试代码，和使用 `CaptureLog.capture_log/1` 来断言相应的日志信息有被记录下来。  

现在我们已经把 `Scheduler` 和 `HealthCheck` 准备好了，我们可以开始写集成测试来确保所有的部件都能正确运行。我们需要在一个测试用例里面使用 Bypass 来测试多个请求。  

还记得之前的 `bypass.port` 吗？都能够我们模拟多个网站的时候，`:port` 选项是很好用的。所以，你可能已经猜到了，我们可以创建多个 Bypass 连接，每个使用不同的端口，相应地模拟各个独立的网站。最新的测试文件 `test/clinic_test.exs` 应该如下：  

```elixir
defmodule ClinicTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  test "sites are checked and results logged" do
    bypass_one = Bypass.open(port: 1234)
    bypass_two = Bypass.open(port: 1337)

    Bypass.expect(bypass_one, fn conn ->
      Plug.Conn.resp(conn, 500, "Server Error")
    end)

    Bypass.expect(bypass_two, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    opts = [interval: 1, sites: ["http://localhost:1234", "http://localhost:1337"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "[info]  pong"
    assert output =~ "[error] HTTP Status 500"
  end
end
```

以上的测试应该没有太多值得惊奇的地方。与其在 `setup` 创建一个 Bypass 连接，我们在测试用例中创建了两个端口分别为 1234 和 1337 的连接。然后，调用 `Bypass.expect/2` 模拟两个不同的返回。最后，再加上 `SchedulerTest` 中启动计划任务和断言信息的相同的代码。  

大功告成！一个持续监控一些域名，并汇报任何问题的工具就打造完成了。我们还学会如何使用 Bypass 来更好地编写测试外部服务的代码。  
