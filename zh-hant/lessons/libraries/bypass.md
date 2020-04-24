---
version: 1.0.0
title: Bypass
---

在測試應用程式時，通常需要向外部服務發出請求。
甚至可能想要模擬不同的情況，例如意外的伺服器錯誤。
在沒有任何幫助下，要在 Elixir 中以效率高的方式進行處理並不容易。

在本課程中，將探討 [bypass](https://github.com/PSPDFKit-labs/bypass) 如何幫助我們快速輕鬆地處理測試中的這些請求。

{% include toc.html %}

## 什麼是 Bypass？

[Bypass](https://github.com/PSPDFKit-labs/bypass) 被描述為「一種建立自訂 plug 的快速方法，該 plug 可以取代原本應是真正的 HTTP 伺服器位置以將預製好的回應回傳給客戶端請求。」

這代表著什麼？
Bypass 的內部是一個 OTP 應用程式，它偽裝成外部伺服器來監聽和回應請求。
通過使用預先定義的回應進行響應，可以測試各種可能性，例如意外的服務中斷和錯誤以及預期將會遇到的情景，而無需發出一個單獨的外部請求。

## 使用 Bypass

為了更好地說明 Bypass 的功能，將建立一個簡單的公用程式來 ping 一份域名清單，並確保它們在線上。
為此，將建立一個新的 supervisor 專案和一個 GenServer，再配置的間隔下檢查域名。
通過在測試中利用 Bypass，將能夠驗證應用程式可以在許多不同的情況中工作。

_註_：如果希望直接跳至最後的完整程式碼，請前往 Elixir School [Clinic](https://github.com/elixirschool/clinic) 儲存庫來瞧瞧。

至此，應該可以輕鬆地建立新的 Mix 專案並加入相依性，因此這裡將只專注於要測試的程式碼片段。
如果需要快速復習，請參考 [Mix](https://elixirschool.com/en/lessons/basics/mix) 課程的 [New Projects](https://elixirschool.com/en/lessons/basics/mix/#new-projects) 部分。


現在從建立一個新模組開始，該模組將處理對域名的請求。
使用 [HTTPoison](https://github.com/edgurgel/httpoison) 建立一個名為 `ping/1` 的函數，該函數接收一個 URL，並為 HTTP 200 的請求回傳 `{:ok, body}` 否則則回傳 `{:error, reason}`。

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

注意到我們 _不是_ 在建立 GenServer，這是有充分理由的：
通過將功能(和關注點)與 GenServer 分離，則能夠在不增加並行的複雜度障礙下，測試程式碼。

編寫好程式碼後，需要啟動測試。
在使用 Bypass 前，需要確保它正在執行。
為此，現在更新 `test/test_helper.exs`，如下所示：

```elixir
ExUnit.start()
Application.ensure_all_started(:bypass)
```

在知道 Bypass 將在測試期間執行後，現在轉到 `test/clinic/health_check_test.exs` 繼續並完成設定。
為了準備 Bypass 來接受請求，需要使用 `Bypass.open/1` 開啟連線，這可以在測試的 setup 中由回呼完成：

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end
end
```

現在，將依靠 Bypass 並使用它的預設埠號，但是如果需要更改它(將在後面的部分中進行更改)，可以在 `Bypass.open/1` 中增加 `:port` 選項，可以像是 `Bypass.open(port: 1337)` 這樣的值。
現在，準備好使用 Bypass。
將會從一個成功的請求開始：

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

我們的測試非常簡單，如果執行它，將看到它通過測式，但是現在深入研究一下每個部分在做什麼。
在測試中看到的第一件事是 `Bypass.expect/2` 函數：

```elixir
Bypass.expect(bypass, fn conn ->
  Plug.Conn.resp(conn, 200, "pong")
end)
```

`Bypass.expect/2` 接受 Bypass 連接和一個單一的 arity 函數，該函數可以修改連接並回傳它，這也是一個機會，可以在請求中進行斷言以驗證是否符合預期。
現在更新測試網址，使其包含 `/ping` 並驗證請求路徑和 HTTP 方法：

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

測試的最後一部分，使用 `HealthCheck.ping/1` 並且斷言的回應如預期，但是 `bypass.port` 到底是什麼呢？
Bypass 實際上是在監聽本機連接埠並攔截這些請求，因為沒有在 `Bypass.open/1` 中提供連接埠，所以使用 `bypass.port` 來檢索預設連接埠。

下一步是加入測試案例來測試錯誤。
可以從測試開始，就像首次測試一樣，做一些小的改變：回傳 500 作為狀態代碼，並斷言 `{:error, reason}` tuple 是被回傳：

```elixir
test "request with HTTP 500 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    Plug.Conn.resp(conn, 500, "Server Error")
  end)

  assert {:error, "HTTP Status 500"} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

這個測試案例沒有什麼特別的，所以繼續下一個：意外的伺服器中斷，這些是我們最掛慮的請求。
為了做到這一點，將不使用 `Bypass.expect/2`，而是依靠 `Bypass.down/1` 來關閉連接：

```elixir
test "request with unexpected outage", %{bypass: bypass} do
  Bypass.down(bypass)

  assert {:error, :econnrefused} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

如果執行新的測試，將看到一切都如預期般通過！
通過測試 `HealthCheck` 模組，可以繼續與基於 GenServer 的排程器(scheduler) 一起對其進行測試。

## 多個外部主機

對於我們的專案，將讓排程器保持準系統狀態，並依賴於 `Process.send_after/3` 來驅動不斷重複的檢查，有關 `Process` 模組的更多資訊，請查看 [文件](https://hexdocs.pm/elixir/Process.html)。
排程器需要三個選項：網址清單、檢驗間隔和實作 `ping/1` 的模組。
藉由傳入模組，能進一步將功能與 GenServer 解耦開來，而能夠更好地獨立測試它們：

```elixir
def init(opts) do
  sites = Keyword.fetch!(opts, :sites)
  interval = Keyword.fetch!(opts, :interval)
  health_check = Keyword.get(opts, :health_check, HealthCheck)

  Process.send_after(self(), :check, interval)

  {:ok, {health_check, sites}}
end
```

現在需要為發送給 `send_after/2` 的 `:check` 訊息定義 `handle_info/2` 函數。
為了簡單起見，將網址傳遞到 `HealthCheck.ping/1` 並將結果記錄到 `Logger.info` 或者當出現錯誤情況時到 `Logger.error`。
我們將以一種能夠在以後改進報告功能的方式設定程式碼：

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

如前所述，將網址傳遞給 `HealthCheck.ping/1`，然後對每個網址應用 `report/1` 函數，並通過 `Enum.each/2` 疉代結果。
有了這些函數，排程器就完成了，接著可以專注於對它進行測試。

不需要過多地專注在排程器的單元測試，因為它不需要 Bypass，因此可以跳到最後的程式碼：

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

依靠 `TestCheck` 測試實現站台的健康檢查並以 `CaptureLog.capture_log/1` 斷言相應訊息有被記錄。

現在，有了工作中的 `Scheduler` 和 `HealthCheck` 模組，接著編寫一個集成測試來驗證所有功能是否可以協同工作。
此測試需要 Bypass，並且每個測試必須處理多個 Bypass 請求，現在看看如何做到這一點。

還記得之前的 `bypass.port` 嗎？當需要模擬多個網址站台時，`:port` 選項很方便。
你可能已經猜到，可以建立多個 Bypass 連接，每個連接具有不同的連接埠，它們將模擬獨立的站台。
將從檢查已更新的 `test/clinic_test.exs` 檔案開始：

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

上面的測試中應該沒有什麼令人驚訝的。
我們沒有在 `setup` 中建立單個 Bypass 連接，而是在測試中建立兩個，並將其連接埠指定為 1234 和 1337。
接下來，看到 `Bypass.expect/2` 呼用，最後看到與 `SchedulerTest` 中相同的程式碼，以啟動排程器並斷言有記錄相應訊息。

就這樣！現在已經建立了一個公用程式，可以及時通知域名是否存在問題，並且學會如何使用 Bypass 替外部服務編寫更好的測試。