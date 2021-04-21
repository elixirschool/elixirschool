---
version: 1.0.0
title: Nerves
redirect_from:
  - /zh-hant/lessons/advanced/nerves
---

## 簡介和硬體需求

在本課程中將討論 Nerves。 Nerves 專案是在嵌入式軟體開發中使用 Elixir 的框架。正如 Nerves 網站所說，它允許 "使用 Elixir 製作和部署高性能嵌入式軟體"。本課程將與其他 Elixir School 課程略有不同。Nerves 較難入門，因為它需要一些進階的系統設定和額外的硬體，因此可能不適合初學者。

要使用 Nerves 編寫嵌入式程式碼，需要一個 [支援的目標設備](https://hexdocs.pm/nerves/targets.html)，一個支援所選硬體記憶卡使用的讀卡機，以及能通過網路存取該設備的有線網絡連接。

然而，我們建議使用樹莓派(Raspberry Pi)，因為它裝載具有可控制的 LED 。且建議有個連接到目標設備的螢幕，因為這樣可以簡化使用 IEx 除錯。

## 設定

Nerves 專案本身有一個很好的 [入門指南](https://hexdocs.pm/nerves/getting-started.html)，但對於一些使用者來說，其細節的數量可能難以消化。相反地，本教學將嘗試以 "更少文字，更多程式碼" 來展現。

首先，需要一個環境設定。可以在 Nerves wiki 的 [安裝](https://hexdocs.pm/nerves/installation.html) 部分找到該指南。請確保具有指南中所提到 OTP 和 Elixir 的相同版本。不使用正確的版本會導致安裝進行時出現問題。在本文撰寫時，任何 Elixir (使用 Erlang/OTP 21 編譯) 都應該可以使用。

在設定完成後，應該準備好來建立第一個 Nerves 專案了！

我們的目標是做到嵌入式開發的 "Hello world"：通過呼用簡單的 HTTP API 來控制閃爍的 LED。

## 建立專案

要產生一個新專案，請執行 `mix nerves.new network_led` 並在提示是否提取和安裝依賴時回答 `Y`。

應該會看到以下輸出：

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

專案已經產生完成，並準備好寫入到測試設備！現在來試試吧！

對於 Raspberry Pi 3，可以設定 `MIX_TARGET=rpi3`，但可以根據目標硬體來更改此設定以符合你的硬體 (請參閱 [Nerves 文件](https://hexdocs.pm/nerves/targets.html#content) 中的列表)

現在先設定依賴關係：

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

註：確保在執行 `mix deps.get` 之前設定指定目標平台的環境變數，因為它將為指定平台下載相應的系統映像和工具鏈。

## 燒錄韌體

現在可以繼續寫入驅動程式。將記憶卡放入讀卡機，如果在前面步驟中正確設定了所有內容，在執行 `mix firmware.burn` 並確認要使用的設備之後，應該會得到以下提示：

```
Building ......../network_led/_build/rpi_dev/nerves/images/network_led.fw...
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
```

如果確定這是你想要燒錄的卡 - 選擇 `Y` 記憶卡會在些許時間中就燒錄完成：

```
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
|====================================| 100% (32.51 / 32.51) MB
Success!
Elapsed time: 8.022 s
```

現在是時候將記憶卡放入裝置中並驗證它是否有效。

如果連接了一個螢幕 - 在插入此記憶卡的設備啟動後，應該會看到一個 Linux 啟動序列。

## 設定網路

下一步是設定網絡。 Nerves 生態系提供各種套件，而 [nerves_network](https://github.com/nerves-project/nerves_network) 是當要通過有線乙太網埠將裝置連線到網路所需要的。

它已作為 `nerves_init_gadget` 的依賴關係存在於專案中。但是，預設情況下，它使用 DHCP (在執行  `config :nerves_init_gadget` 之後，請參考 `config/config.exs` 中的配置)。這讓擁有靜態 IP 位址更容易。

要設定靜態網路，需要將以下幾行加入到 `config/config.exs`：

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

請注意，此配置是用於有線連線。如果要使用無線連線 - 請查看 [Nerves 網路文件](https://github.com/nerves-project/nerves_network#wifi-networking)。

注意到，需要在此處使用本機網路參數 - 在我的網路中有一個未分配的IP `192.168.88.2`，所以會使用它。但是，在你的情境中，它可能會有所不同。

在修改後，需要通過 `mix firmware.burn` 重新燒錄修改版本後的韌體，然後使用新燒錄的卡啟動裝置。

當開啟裝置電源時，可以使用 `ping` 查看它是否在線上。

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

此輸出表示現在可以從網路連線到該裝置。

## 網路遠端燒錄韌體

到目前為止，我們一直在燒錄 SD 卡並將它們物理裝載到硬體中。雖然這很好，但通過網路推送更新將更為直接。`nerves_firmware_ssh` 套件正是為此而生的。預設情況下，它已存在於專案中，設定為自動偵測並會在目錄中搜尋 SSH 密鑰。

要使用網路韌體更新功能，需要通過 `mix firmware.gen.script` 生成上傳用 script。該指令將生成一個新的 `upload.sh` script，可以執行該 script 來更新韌體。

如果在上一步之後網路正常運作，就可以開始使用了。

要更新設定，最簡單的方法是使用 `mix firmware && ./upload.sh 192.168.88.2`：第一個指令建立更新的韌體，第二個指令通過網路推送它並重新啟動設備。完成後可以停止並將 SD 卡插入和拔出設備！

_提示：`ssh 192.168.88.2` 在應用程式的上下文中提供設備上的 IEx 殼層。_

_故障排除：如果主資料夾中沒有存在 ssh 密鑰，則會出現錯誤訊息 `No SSH public keys found in ~/.ssh.`。在這種情況下，需要執行 `ssh-keygen` 並重新燒錄靭體以使用網路更新功能。_

## 設定 LED 控制

要與 LED 互動，需要安裝 [nerves_leds](https://github.com/nerves-project/nerves_leds) 套件，這需要將 `{:nerves_leds, "~> 0.8", targets: @all_targets},` 加到 `mix.exs` 檔案中。

設定相依關係後，需要為該設備配置 LED 列表。例如，對於所有 Raspberry Pi 型號，內建只有一個LED：`led0`。現在通過在 `config/config.exs` 中加入一行 `config :nerves_leds, names: [green: "led0"]` 來使用它。

對於其他設備，可以查看 [nerves_examples 專案與之對應的部分](https://github.com/nerves-project/nerves_examples/tree/master/hello_leds/config)。

配置 LED 本身後，肯定需要以某種方式控制它。為此，將在包含以下內容的 `lib/network_led/blinker.ex` 中加入一個 GenServer (更多關於 GenServers 的細節請參考 [OTP Concurrency](../../advanced/otp-concurrency) 課程)：

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

要啟用此功能，還需要將其加入到 `lib/network_led/application.ex` 中的 supervision tree：在 `def children(_target) do` 群組下加入 `{NetworkLed.Blinker, name: NetworkLed.Blinker}`。

請注意，Nerves 在應用程式中有兩個不同的 supervision tree - 一個用於主機，一個用於實際設備。

在此之後 - 就完成了！實際上可以上傳靭體並通過目標設備中的 ssh 執行 IEx 來檢驗 `NetworkLed.Blinker.disable()` 關閉 LED(程式碼中預設啟用)，以及用 `NetworkLed.Blinker.enable()` 開啟。

現在可以從命令提示字元控制 LED！

現在，剩下唯一缺少的部分是通過網路介面控制 LED。

## 加入網路伺服器

在這一步中，將使用 `Plug.Router`。如果需要些提示 - 請輕鬆瀏覽 [Plug](../../../lessons/specifics/plug/) 課程。

首先，將 `{:plug_cowboy, "~> 2.0"},` 加入到 `mix.exs` 並安裝相依關係。

然後，在 `lib/network_led/http.ex` 中加入實際處理程序來處理這些請求：

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

最後一步 - 將 `{Plug.Cowboy, scheme: :http, plug: NetworkLed.Http, options: [port: 80]}` 加入到應用程式 supervision tree 中。

靭體更新後，就可以來試試！`http://192.168.88.2/` 將回傳純文字響應，並以 `http://192.168.88.2/enable` 與 `http://192.168.88.2/disable` 來停用並啟用該 LED！

甚至可以將 Phoenix 支援的使用者介面打包進 Nerves 應用程式中，不過， [需要進行一些調整](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces)。
