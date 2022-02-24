%{
  version: "1.0.1",
  title: "Bypass",
  excerpt: """
  アプリケーションのテストでは、しばしば外部サービスにリクエストを出す必要があります。
  予期せぬサーバーエラーのような、さまざまな状況をシミュレートしたいこともあるでしょう。
  Elixirでは、このような状況を効率的に処理するために、ちょっとした手助けが必要です。

  このレッスンでは、[bypass](https://github.com/PSPDFKit-labs/bypass) を使って、テストの中でこれらのリクエストを素早く簡単に処理する方法を探ります。
  """
}
---

## Bypassとは何か？

[Bypass](https://github.com/PSPDFKit-labs/bypass)は、"クライアントのリクエストに対して事前に用意したレスポンスを返すために、実際のHTTPサーバの代わりに設置できるカスタムプラグの迅速な作成方法"として説明されています。どういうことでしょうか？

Bypassの中身は、外部サーバーを装ってリクエストを聞き、それに応答するOTPアプリケーションです。
あらかじめ定義されたレスポンスで応答することにより、予期せぬサービスの停止やエラーなど、遭遇する可能性のあるシナリオを、すべて一度も外部リクエストをすることなくテストできます。

## Bypassを利用する

Bypassの機能をよりよく説明するために、ドメインのリストにpingを打ち、それらがオンラインであることを確認するためのシンプルなユーティリティアプリケーションを構築します。

これを行うために、新しいスーパーバイザープロジェクトと、設定可能な間隔でドメインをチェックするためのGenServerを作成します。
テストでBypassを活用することで、アプリケーションが多くの異なる結果で動作することを確認できます。

注意: もし最終的なコードまで読み飛ばしたい場合は、Elixir Schoolのリポジトリ[Clinic](https://github.com/elixirschool/clinic)にアクセスしてみてください。

この時点で、新しいMixプロジェクトを作成し、依存関係を追加することに慣れ、テストするコードに集中できるようになります。
もし復習が必要なら、[Mix](https://elixirschool.com/ja/lessons/basics/mix) のレッスンの [新しいプロジェクト](https://elixirschool.com/ja/lessons/basics/mix/#new-projects) のセクションを参照してください。

ドメインへのリクエストを処理する新しいモジュールを作成することから始めましょう。
[HTTPoison](https://github.com/edgurgel/httpoison)を使って、 `ping/1` という関数を作成します。これはURLを受け取り、HTTP 200リクエストの場合は `{:ok, body}` を、それ以外の場合は `{:error, reason}` を返します。

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

私たちがGenServerを*作っていない*ことにお気づきでしょうが、これには十分な理由があります。
私たちの機能（と関心事）を GenServer から分離することで、並行処理のハードルを追加することなく私たちのコードをテストすることができるのです。

コードを配置した状態で、私たちはテストに着手する必要があります。
Bypass を使用する前に、それが実行されていることを確認する必要があります。
そのために、`test/test_helper.exs` をこのように更新しましょう。

```elixir
ExUnit.start()
Application.ensure_all_started(:bypass)
```

テスト中にBypassが実行されることがわかったので、`test/clinic/health_check_test.exs`に向かい、セットアップを完了させましょう。
Bypassがリクエストを受け入れる準備をするために、`Bypass.open/1`でコネクションを開く必要がありますが、これはテストのセットアップコールバックで行うことができます。

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end
end
```

今のところ、Bypassがデフォルトのポートを使うことに頼っていますが、もし変更する必要があれば（後のセクションで行います）、`Bypass.open/1`に `:port` オプションと `Bypass.open(port: 1337)` という値を指定できます。

これでBypassを動かす準備ができました。まずは成功するリクエストから始めましょう。

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

このテストはとてもシンプルで、実行すればパスすることがわかりますが、それぞれの部分が何をしているのか、掘り下げて見てみましょう。
このテストで最初に見ることができるのは `Bypass.expect/2` 関数です。

```elixir
Bypass.expect(bypass, fn conn ->
  Plug.Conn.resp(conn, 200, "pong")
end)
```

`Bypass.expect/2` は、Bypassのコネクションと、コネクションを変更してそれを返すことが期待される単一のアリティ関数を取ります。これは、期待通りのものであることを確認するために、リクエストに対してアサーションを行う機会でもあります。
テストURLを更新して `/ping` を含め、リクエストパスとHTTPメソッドの両方をアサーションしてみましょう。

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

テストの最後の部分では `HealthCheck.ping/1` を使って、期待通りのレスポンスが得られたことを確認しています。`bypass.port` とは何なのでしょうか？
Bypassは実際にはローカルポートをリスニングしており、これらのリクエストを傍受しています。`Bypass.open/1`でデフォルトポートを指定していないため、`bypass.port`を使用してデフォルトポートを取得しているのです。

次は、エラーに対するテストケースを追加します。最初のテストと同じように、いくつかの小さな変更から始めます。ステータスコードとして500を返し、 `{:error, reason}` タプルが返されたことを確認します。

```elixir
test "request with HTTP 500 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    Plug.Conn.resp(conn, 500, "Server Error")
  end)

  assert {:error, "HTTP Status 500"} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

このテストケースには特別なものはないので、次の「予期せぬサーバーの停止」に進みましょう。
これは私たちがもっとも懸念しているリクエストです。
これを達成するために、`Bypass.expect/2`は使用せず、代わりに`Bypass.down/1`に依存して、接続をシャットダウンしましょう。

```elixir
test "request with unexpected outage", %{bypass: bypass} do
  Bypass.down(bypass)

  assert {:error, :econnrefused} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

新しいテストを実行すると、すべてが期待通りになることがわかります。
`HealthCheck` モジュールがテストされたので、GenServer ベースのスケジューラと一緒にテストに移ることができます。

## 複数の外部ホスト

今回のプロジェクトでは、スケジューラはシンプルなものにし、 `Process.send_after/3` を利用して、繰り返し行うチェックを行うことにします。`Process` モジュールの詳細については、 [ドキュメント](https://hexdocs.pm/elixir/Process.html) を参照してください。

このスケジューラは3つのオプションを必要とします。サイトのコレクション、チェックの間隔、そして`ping/1`を実装したモジュールです。
モジュールを渡すことで、機能とGenServerをさらに切り離し、それぞれを分離してよりよくテストできるようにします。

```elixir
def init(opts) do
  sites = Keyword.fetch!(opts, :sites)
  interval = Keyword.fetch!(opts, :interval)
  health_check = Keyword.get(opts, :health_check, HealthCheck)

  Process.send_after(self(), :check, interval)

  {:ok, {health_check, sites}}
end
```

次に、 `:check` メッセージが `send_after/2` に送信されたときの `handle_info/2` 関数を定義する必要があります。
シンプルにするために、サイトを `HealthCheck.ping/1` に渡し、結果を `Logger.info` か、エラーの場合は `Logger.error` に記録することにします。
後日、レポート機能を改善できるように、コードをセットアップしておきます。

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

説明したように、サイトを `HealthCheck.ping/1` に渡し、その結果を `Enum.each/2` で反復し、それぞれに対して `report/1` 関数を適用しています。
これらの関数を配置することで、スケジューラは完成し、そのテストに集中できます。

スケジューラのユニットテストはBypassを必要としないので、あまり焦点を当てないことにします。最終的なコードに飛びます。

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

適切なメッセージがログに記録されることを保証するために、 `CaptureLog.capture_log/1` と共に `TestCheck` によるヘルスチェックのテスト実装に依存しています。

これで `Scheduler` と `HealthCheck` モジュールが動作するようになったので、統合テストを書いて、すべてが一緒に動作することを確認しましょう。
このテストにはBypassが必要で、テストごとに複数のBypassリクエストを処理する必要があります。そのやり方を見ていきましょう。

先ほどの`bypass.port`を覚えていますか？複数のサイトを模倣する必要があるとき、`:port`オプションは便利です。
おそらくご想像の通り、複数のBypass接続をそれぞれ異なるポートで作成することができ、これらは独立したサイトをシミュレートすることになります。
まず、更新した `test/clinic_test.exs` ファイルを確認します。

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

上記のテストでは、あまり驚くようなことはないはずです。
`setup`でBypass接続を1つ作る代わりに、テスト内で2つ作り、そのポートを1234と1337に指定しています。
次に `Bypass.expect/2` を呼び出し、最後に `SchedulerTest` で行ったのと同じコードでスケジューラを起動し、適切なメッセージをログに記録していることを確認します。

これで終わりです！ドメインに何か問題があった場合に知らせてくれるユーティリティを構築し、外部サービスを使ったより良いテストを書くためにBypassを採用する方法を学びました。
