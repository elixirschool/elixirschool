---
version: 1.0.0
title: Nerves
---

## はじめに

このレッスンでは Nerves について話します。 Nerves プロジェクトは組込みソフトウェア開発に Elixir を使用するためのフレームワークです。Nerves のウェブサイトにあるように、それはあなたが「Elixir で、安全な組み込みソフトウェアを作り、そして展開する」ことを可能にします。このレッスンは他の Elixir School のレッスンとは少し異なります。上級者向けのシステム設定と追加のハードウェアの両方が必要なため、Nerves を習得するのは少し困難です。したがって、初心者にはオススメしません。

Nerves を使ってコードを書くためには、ネットワークによってこのデバイスにアクセスするための有線ネットワーク接続として、 [サポート対象のハードウェア](https://hexdocs.pm/nerves/targets.html) のいずれか、お好みのハードウェアでサポートされているメモリカードを持ったカードリーダーが必要です。

ただし、Raspberry Pi には制御可能な LED が搭載されているため、Raspberry Pi を使用することをお勧めします。 IEx を使用したデバッグが簡単になるため、画面をターゲットデバイスに接続することをお勧めします。

## セットアップ

Nerves プロジェクト自体は優れた [Getting started guide](https://hexdocs.pm/nerves/getting-started.html) を持っていますが、一部のユーザーにとっては情報量が圧倒的なものかもしれません。代わりに、このチュートリアルでは「言葉を減らし、コードを増やす」ことを試みます。

まず、環境設定が必要になります。このガイドは、Nerves wiki の [Installation](https://hexdocs.pm/nerves/installation.html) にあります。ガイドに記載されている OTP と Elixir の両方のバージョンが同じであることを確認してください。正しいバージョンを使用しないと、進行中に問題が発生する可能性があります。これを書いている時点では、どの Elixir（Erlang/OTP 21 でコンパイルされたもの）でも動作するはずです。

セットアップが完了したら、最初の Nerves プロジェクトを構築する準備が整いました!

今回の私たちの目標は、組み込み開発の「Hello world」、つまり単純な HTTP API を呼び出すことによって LED の点滅を制御することです。

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

Raspberry Pi 3 の場合、 `MIX_TARGET=rpi3` を設定しますが、ハードウェアに応じて、これをあなたが持っているハードウェアに合うように変更することができます。([Nerves documentation](https://hexdocs.pm/nerves/targets.html#content) を参照)

まず依存関係を設定しましょう:

```
$ export MIX_TARGET=rpi3
$ cd network_led
$ mix deps.get

....

Nerves environment
  MIX_TARGET:   rpi3
  MIX_ENV:      dev
Resolving Nerves artifacts...
  Resolving nerves_system_rpi3
  => Trying https://github.com/nerves-project/nerves_system_rpi3/releases/download/v1.7.0/nerves_system_rpi3-portable-1.7.0-17EA89A.tar.gz
|==================================================| 100% (133 / 133) MB
  => Success
  Resolving nerves_toolchain_arm_unknown_linux_gnueabihf
  => Trying https://github.com/nerves-project/toolchains/releases/download/v1.1.0/nerves_toolchain_arm_unknown_linux_gnueabihf-darwin_x86_64-1.1.0-2305AD8.tar.xz
|==================================================| 100% (50 / 50) MB
  => Success
```

注意: 指定したプラットフォーム用の適切なシステムイメージとツールチェーンをダウンロードするので、 `mix deps.get`を実行する前にターゲットプラットフォームを指定する環境変数を設定していることを確認してください。

## ファームウェアの書き込み

これでファームウェアを書き込むことができます。カードをリーダーに入れて、前の手順ですべてを正しく設定した場合は、 `mix firmware.burn` を実行してデバイスの使用を確認した後に、次のプロンプトが表示されるはずです:

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

画面が接続されている場合、このメモリカードを挿入した状態でデバイスの電源を入れた後に、Linux の起動シーケンスが表示されるはずです。

## ネットワークの設定

次のステップはネットワークを設定することです。Nerves のエコシステムはさまざまなパッケージを提供しています。[nerves_network](https://github.com/nerves-project/nerves_network) は、有線イーサネットポートを介してデバイスをネットワークに接続するために必要なものです。

あなたのプロジェクトにはすでに `nerves_init_gadget` が依存関係として存在しています。しかし、デフォルトでは DHCP を使います（ `config/config.exs` の中の `config :nerves_init_gadget` の後の実行内容を確認してください）。静的 IP アドレスを持つ方が簡単です。

静的ネットワークを設定するには、 `config/config.exs` に以下の行を追加する必要があります:

```
# Statically assign an address
config :nerves_network, :default,
  eth0: [
    ipv4_address_method: :static,
    ipv4_address: "192.168.88.2",
    ipv4_subnet_mask: "255.255.255.0",
    nameservers: ["8.8.8.8", "8.8.4.4"]
  ]
```

この設定は有線接続用です。無線接続を使用したい場合は、[Nerves network documentation](https://github.com/nerves-project/nerves_network#wifi-networking) を参照してください。

ここであなたのローカルネットワークパラメータを使う必要があることに注意してください。私のネットワークでは割り当てられていない IP `192.168.88.2` があるので、これを使用します。しかし、あなたの場合、IP アドレスは違うかもしれません。

これを変更した後、私たちは `mix firmware.burn` を通してファームウェアの変更されたバージョンを書き込んで、それから新しいカードで装置を起動する必要があります。

デバイスに電源を入れると、 `ping` を使ってオンラインになるのを見ることができます。

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

この出力は、デバイスがネットワークから到達可能になったことを意味します。

## ネットワークファームウェアの書き込み

これまでのところ、私達は SD カードに書き込んで、物理的にそれらを私達のハードウェアにロードしてきました。これは最初は問題ありませんが、ネットワーク経由で更新する方が簡単です。 `nerves_firmware_ssh` パッケージはまさにそれをしてくれます。デフォルトでは、すでにプロジェクトに存在し、ディレクトリ内の SSH キーを自動検出して見つけるように設定されています。

ネットワークファームウェアアップデート機能を使うためには、 `mix firmware.gen.script` を通してアップロードスクリプトを生成する必要があります。このコマンドはファームウェアを更新するために実行できる新しい `upload.sh` スクリプトを生成します。

前の手順を実行してネットワークが機能している場合は、問題ないので次に進みます。

設定を更新するための最も簡単な方法は `mix firmware && ./upload.sh 192.168.88.2` を使うことです。最初のコマンドは更新されたファームウェアを作成し、二番目のコマンドはそれをネットワーク経由でプッシュしてデバイスを再起動します。 SD カードをデバイスに出し入れする必要がなくなります。

_ヒント： `ssh 192.168.88.2` はアプリのコンテキストでデバイスに IEx シェルを提供します。_

_トラブルシューティング：ホームフォルダに ssh キーが存在しない場合は、 `No SSH public keys found in ~/.ssh.` というエラーが表示されます。この場合、 `ssh-keygen` を実行してネットワークアップデート機能を使用するためにファームウェアを再書き込みする必要があります。_

## LED のコントロールを設定する

LED とやり取りするには、[nerves_leds](https://github.com/nerves-project/nerves_leds) パッケージをインストールする必要があります。これは、 `mix.exs` ファイルに `{:nerves_leds, "~> 0.8", targets: @all_targets},` を追加することによって行われます。

依存関係を設定したら、特定のデバイスの LED リストを設定する必要があります。例えば、すべての Raspberry Pi モデルのために、ただ一つの LED である `led0` が搭載されています。 `config/config.exs` に `config :nerves_leds, names: [green: "led0"]` を追加して使用しましょう。

他のデバイスについては、[nerves_examples プロジェクトで対応する部分](https://github.com/nerves-project/nerves_examples/tree/master/hello_leds/config) を参照してください。

LED 自体を設定したら、どうにかしてそれを制御する必要があります。そのために、以下の内容を含む `lib/network_led/blinker.ex` に GenServer を追加します（[OTP Concurrency](../../advanced/otp-concurrency) レッスンの GenServer についての詳細を参照）。

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

Nerves のアプリケーションには 2 つの異なるスーパーバイザーツリーがあります。1 つはホストマシン用、もう 1 つは実際のデバイス用です。

この後、実際にファームウェアをアップロードし、ターゲットデバイス上で ssh を使って IEx を実行することで `NetworkLed.Blinker.disable()` が LED を消すこと（コードではデフォルトで有効になっています）、そして `NetworkLed.Blinker.enable()` が LED を点けることを確認できます。

コマンドプロンプトから LED を制御できます!

今残っているパズルが欠けている唯一の部分は、ウェブインタフェースを介して LED を制御することです。

## Web サーバーを追加する

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

ファームウェアのアップデート後に試すことができます。 `http://192.168.88.2/` はプレーンテキストの応答を返しており、 `http://192.168.88.2/disable` と一緒に `http://192.168.88.2/enable` はその LED を無効にして有効にします！

Phoenix を使ったユーザーインターフェースを Nerves アプリに導入することもできますが、それには[いくつかの調整が必要になります](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces)。
