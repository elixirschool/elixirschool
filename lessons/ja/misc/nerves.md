%{
  version: "1.1.2",
  title: "Nerves",
  excerpt: """
  """
}
---

## はじめに

このレッスンではNervesについて話します。Nervesプロジェクトは組込みソフトウェア開発にElixirを使用するためのフレームワークです。Nervesのウェブサイトにあるように、それはあなたが「Elixirで、安全な組み込みソフトウェアを作り、そして展開する」ことを可能にします。このレッスンは他のElixir Schoolのレッスンとは少し異なります。上級者向けのシステム設定と追加のハードウェアの両方が必要になるため、Nervesを習得するのは初心者には難しいかもしません。

Nervesを使って組み込み向けのコードを書くためには、 [サポート対象のハードウェア](https://hexdocs.pm/nerves/targets.html) のいずれかと、お好みのハードウェアでサポートされているメモリカードのカードリーダーと、ネットワーク越しにデバイスにアクセスするための有線ネットワーク接続が必要です。

ただし、Raspberry Piには制御可能なLEDが搭載されているため、Raspberry Piを使用することをお勧めします。IExを使用したデバッグが簡単になるため、モニタをターゲットデバイスに接続することをお勧めします。

## セットアップ

Nervesプロジェクト自体は優れた [Getting started guide](https://hexdocs.pm/nerves/getting-started.html) を持っていますが、一部のユーザーにとっては情報量が圧倒的なものかもしれません。代わりに、このチュートリアルでは「言葉を減らし、コードを増やす」ことを試みます。

まず、環境設定が必要になります。このガイドは、Nerves wikiの [Installation](https://hexdocs.pm/nerves/installation.html) にあります。ガイドに記載されているOTPとElixirの両方のバージョンが同じであることを確認してください。正しいバージョンを使用しないと、進行中に問題が発生する可能性があります。これを書いている時点では、どのElixir（Erlang/OTP 21でコンパイルされたもの）でも動作するはずです。

セットアップが完了したら、最初のNervesプロジェクトを構築する準備が整いました!

今回の私たちの目標は、組み込み開発の「Hello world」、つまり単純なHTTP APIを呼び出すことによってLEDの点滅を制御することです。

## プロジェクトを作成する

新しいプロジェクトを生成するには、 `mix nerves.new network_led` を実行し、依存関係を取得してインストールするかどうかを尋ねられたら `Y` と答えてください。

次のような出力が得られるはずです:

```
Your Nerves project was created successfully.

You should now pick a target. See https://hexdocs.pm/nerves/targets.html#content
for supported targets. If your target is on the list, set `MIX_TARGET`
to its tag name:

For example, for the Raspberry Pi 3 you can either
  $ export MIX_TARGET=rpi3
Or prefix `mix` commands like the following:
  $ MIX_TARGET=rpi3 mix firmware

If you will be using a custom system, update the `mix.exs`
dependencies to point to desired system's package.

Now download the dependencies and build a firmware archive:
  $ cd network_led
  $ mix deps.get
  $ mix firmware

If your target boots up using an SDCard (like the Raspberry Pi 3),
then insert an SDCard into a reader on your computer and run:
  $ mix firmware.burn

Plug the SDCard into the target and power it up. See target documentation
above for more information and other targets.
```

プロジェクトは生成され、テスト装置を点滅させる準備ができています！早速試してみましょう!

Raspberry Pi 3の場合、 `MIX_TARGET=rpi3` を設定しますが、ハードウェアに応じて、これをあなたが持っているハードウェアに合うように変更することができます。([Nerves documentation](https://hexdocs.pm/nerves/targets.html#content) を参照)

まず依存関係を設定しましょう:

```shell
$ export MIX_TARGET=rpi3
$ cd network_led
$ mix deps.get

....

Nerves environment
  MIX_TARGET:   rpi3
  MIX_ENV:      dev
Resolving Nerves artifacts...
  Resolving nerves_system_rpi3
  => Trying https://github.com/nerves-project/nerves_system_rpi3/releases/download/v1.12.2/nerves_system_rpi3-portable-1.12.2-E904717.tar.gz
|==================================================| 100% (142 / 142) MB
  => Success
  Resolving nerves_toolchain_arm_unknown_linux_gnueabihf
  => Trying https://github.com/nerves-project/toolchains/releases/download/v1.3.2/nerves_toolchain_arm_unknown_linux_gnueabihf-darwin_x86_64-1.3.2-E31F29C.tar.xz
|==================================================| 100% (55 / 55) MB
  => Success
```

注意: 指定したプラットフォーム用の適切なシステムイメージとツールチェーンをダウンロードするので、 `mix deps.get`を実行する前にターゲットプラットフォームを指定する環境変数を設定していることを確認してください。

## ファームウェアの書き込み

これでファームウェアを書き込むことができます。カードをリーダーに入れて、前の手順ですべてを正しく設定した場合は、 `mix firmware.burn` を実行すると、書き込むカードを確認するために、次のプロンプトが表示されるはずです:

```
Building ......../network_led/_build/rpi_dev/nerves/images/network_led.fw...
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
```

これがあなたが書き込むカードであると確信しているなら、 `Y` を選んで、しばらくするとメモリカードは準備ができています:

```
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
|====================================| 100% (32.51 / 32.51) MB
Success!
Elapsed time: 8.022 s
```

これで、メモリカードをデバイスに挿入して動作するかどうかを確認します。

画面が接続されている場合、このメモリカードを挿入した状態でデバイスの電源を入れた後に、Linuxの起動シーケンスが表示されるはずです。

## ネットワークの設定

次のステップはネットワークを設定することです。Nervesのエコシステムはさまざまなパッケージを提供しています。[vintage_net](https://github.com/nerves-networking/vintage_net) は、有線イーサネットポートを介してデバイスをネットワークに接続するために必要なものです。

あなたのプロジェクトにはすでに [`nerves_pack`](https://github.com/nerves-project/nerves_pack) が依存関係として存在しています。しかし、デフォルトではDHCPを使います（ `config/target.exs` の中の `config :vintage_net` の後の設定内容を確認してください）。静的IPアドレスを持つ方が簡単です。

静的ネットワークを設定するには、 `config/target.exs` 内の `:vintage_net` 設定を更新する必要があります:

```elixir
# Statically assign an address
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{
         method: :static,
         address: "192.168.88.2",
         prefix_length: 24,
         gateway: "192.168.88.1",
         name_servers: ["8.8.8.8", "8.8.4.4"]
       }
     }},
    {"wlan0", %{type: VintageNetWiFi}}
  ]
```

この設定は有線接続の設定のみを更新します。WiFiを使用したい場合は、 [VintageNet Cookbook](https://hexdocs.pm/vintage_net/cookbook.html#wifi) を参照してください。

ここであなたのローカルネットワークパラメータを使う必要があることに注意してください。私のネットワークでは割り当てられていないIP `192.168.88.2` があるので、これを使用します。しかし、あなたの場合、IPアドレスは違うかもしれません。

これを変更した後、私たちは `mix firmware.burn` を通してファームウェアの変更されたバージョンを書き込んで、それから新しいカードで装置を起動する必要があります。

デバイスに電源を入れると、 `ping` を使ってオンラインになるのを見ることができます。

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

この出力は、デバイスがネットワークから到達可能になったことを意味します。

## ネットワーク経由のファームウェアの書き込み

これまでのところ、私達はSDカードに書き込んで、物理的にそれらを私達のハードウェアにロードしてきました。これは最初は問題ありませんが、ネットワーク経由で更新する方が簡単です。 [`ssh_subsystem_fwup`](https://github.com/nerves-project/ssh_subsystem_fwup) パッケージはまさにそれをしてくれます。プロジェクトにはデフォルトですでに設定されていて、 `~/.ssh` ディレクトリ内のSSHキーを自動検出して見つけるように構成されています。

ネットワーク経由のファームウェアアップデート機能を使うためには、 `mix firmware.gen.script` を通してアップロードスクリプトを生成する必要があります。このコマンドはファームウェアを更新するために実行できる新しい `upload.sh` スクリプトを生成します。

前の手順を実行してネットワークが機能している場合は、問題ないので次に進みます。

設定を更新するための最も簡単な方法は `mix firmware && ./upload.sh 192.168.88.2` を使うことです。最初のコマンドは更新されたファームウェアを作成し、二番目のコマンドはそれをネットワーク経由でプッシュしてデバイスを再起動します。SDカードをデバイスに出し入れする必要がなくなります!

_ヒント： `ssh 192.168.88.2` はアプリのコンテキストでデバイスにIExシェルを提供します。_

_トラブルシューティング：ホームフォルダにsshキーが存在しない場合は、 `No SSH public keys found in ~/.ssh.` というエラーが表示されます。この場合、 `ssh-keygen` を実行してネットワークアップデート機能を使用するためにファームウェアを再書き込みする必要があります。_

## LEDのコントロールを設定する

LEDとやり取りするには、[nerves_leds](https://github.com/nerves-project/nerves_leds) パッケージをインストールする必要があります。これは、 `mix.exs` ファイルに `{:nerves_leds, "~> 0.8", targets: @all_targets},` を追加することによって行われます。

依存関係を設定したら、特定のデバイスのLEDリストを設定する必要があります。例えば、すべてのRaspberry Piモデルのために、ただ一つのLEDである `led0` が搭載されています。 `config/config.exs` に `config :nerves_leds, names: [green: "led0"]` を追加して使用しましょう。

他のデバイスについては、[nerves_examplesプロジェクトで対応する部分](https://github.com/nerves-project/nerves_examples/tree/main/hello_leds/config) を参照してください。

LED自体を設定したら、どうにかしてそれを制御する必要があります。そのために、以下の内容を含む `lib/network_led/blinker.ex` にGenServerを追加します（[OTP Concurrency](../../advanced/otp-concurrency) レッスンのGenServerについての詳細を参照）。

```elixir
defmodule NetworkLed.Blinker do
  use GenServer

  @moduledoc """
    Simple GenServer to control GPIO #18.
  """

  require Logger
  alias Nerves.Leds

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    enable()

    {:ok, state}
  end

  def handle_cast(:enable, state) do
    Logger.info("Enabling LED")
    Leds.set(green: true)

    {:noreply, state}
  end

  def handle_cast(:disable, state) do
    Logger.info("Disabling LED")
    Leds.set(green: false)

    {:noreply, state}
  end

  def enable() do
    GenServer.cast(__MODULE__, :enable)
  end

  def disable() do
    GenServer.cast(__MODULE__, :disable)
  end
end

```

これを有効にするには、それを `lib/network_led/application.ex` のスーパーバイザーツリーに追加する必要があります。`def children(_target) do` グループの下に `{NetworkLed.Blinker, name: NetworkLed.Blinker}` を追加してください。

Nervesのアプリケーションには2つの異なるスーパーバイザーツリーがあります。1つはホストマシン用、もう1つは実際のデバイス用です。

この後、実際にファームウェアをアップロードし、ターゲットデバイス上でsshを使ってIExを実行することで `NetworkLed.Blinker.disable()` がLEDを消すこと（コードではデフォルトで有効になっています）、そして `NetworkLed.Blinker.enable()` がLEDを点けることを確認できます。

コマンドプロンプトからLEDを制御できます!

今残っているパズルが欠けている唯一の部分は、ウェブインタフェースを介してLEDを制御することです。

## Webサーバーを追加する

このステップでは、 `Plug.Router` を使います。思い出す必要がある場合は、[Plug](../../../lessons/specifics/plug/) レッスンを読んでください。

最初に、 `{:plug_cowboy, "~> 2.0"},` を `mix.exs` に追加して依存関係をインストールします。

それから、 `lib/network_led/http.ex` でそれらのリクエストを処理するための実際のプロセスを追加します。

```elixir
defmodule NetworkLed.Http do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Feel free to use API endpoints!"))

  get "/enable" do
    NetworkLed.Blinker.enable()
    send_resp(conn, 200, "LED enabled")
  end

  get "/disable" do
    NetworkLed.Blinker.disable()
    send_resp(conn, 200, "LED disabled")
  end

  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

そして最後のステップ - アプリケーションのスーパーバイザーツリーに `{Plug.Cowboy, scheme: :http, plug: NetworkLed.Http, options: [port: 80]}` を追加します。

ファームウェアのアップデート後に試すことができます！ `http://192.168.88.2/` はプレーンテキストの応答を返しており、 `http://192.168.88.2/disable` でLEDが消灯し、 `http://192.168.88.2/enable` でLEDが点灯します！

Phoenixを使ったユーザーインターフェースをNervesアプリに導入することもできますが、それには[いくつかの調整が必要になります](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces)。
