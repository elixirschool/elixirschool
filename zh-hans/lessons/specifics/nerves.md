---
version: 1.0.0
title: Nerves
---

## Nerves 简介

我们将在本课中介绍 Nerves， Nerves 项目是在嵌入式软件开发中使用 Elixir 的框架。 正如 Nerves 官网所说，它允许您“使用 Elixir 制作和部署防弹嵌入式软件”。 本课将与其他 Elixir School课程略有不同。 Nerves 学习起来有点困难，因为它需要一些先进的系统设置和额外的硬件，因此可能不适合初学者。

要使用 Nerves 编写嵌入式代码，您需要一个[目标设备](https://hexdocs.pm/nerves/targets.html)，一个带有您所选硬件支持的存储卡的读卡器，以及可以通过网络访问此设备。

在这里我们建议使用 Raspberry Pi (树莓派)，因为它具有可控的 LED 板。 同时也建议将目标设备连接到一个屏幕，因为这样可以简化使用 IEx 的调试。

## 环境安装

Nerves 项目本身有一个很好的[入门指南](https://hexdocs.pm/nerves/getting-started.html)，但文档里面大量的细节对于一些用户来说可能有点压力。 相反地，本教程将尝试呈现“少说话，放码过来”。

首先，您需要安装环境。 您可以在 Nerves wiki 的 [安装](https://hexdocs.pm/nerves/installation.html) 部分找到该指南。 请确保您同时也已经具备指南中提到的 OTP 和 Elixir 的相同版本。 不使用正确的版本会导致安装时出现问题。 在撰写本文时，任何 Elixir 版本（使用 Erlang/OTP 21编译）都应该可以工作。

环境安装完成后，您应当已经准备好构建您的第一个 Nerves 项目了！

我们的目标是嵌入式开发中的 “Hello world” ：通过调用简单的 HTTP API 来控制闪烁的 LED。

## 创建项目

要创建一个新项目，请运行 `mix nerves.new network_led` 并在提示是否获取和安装依赖项时输入 `Y`。

你应该会看到以下输出：

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

我们的项目已经创建完成，并准备好被写入到我们测试设备中！ 我们现在开始试试吧！

对于 Raspberry Pi 3，您可以设置 `MIX_TARGET=rpi3`，但您可以根据目标硬件更改此设置以适应您的硬件（请参阅 [Nerves 文档](https://hexdocs.pm/nerves/targets.html#content)).

让我们先设置我们的依赖项：

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

注意：确保在运行 `mix deps.get` 之前设置了指定目标设备的环境变量，因为它将为指定设备下载相应的系统镜像和工具链。

## 烧录固件

现在我们可以使用闪存驱动器了。 将卡放入读卡器，如果您在前面的步骤中正确设置了所有内容，在运行 `mix firmware.burn` 并确认要使用的设备之后，您应该得到以下提示：

```
Building ......../network_led/_build/rpi_dev/nerves/images/network_led.fw...
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
```

如果你确定这是你想要烧录的卡 - 选择 `Y`, 一段时间后存储卡就烧好了：

```
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
|====================================| 100% (32.51 / 32.51) MB
Success!
Elapsed time: 8.022 s
```

现在是时候将存储卡放入您的设备并验证它是否有效。

如果您连接了一个屏幕 - 在插入此存储卡的设备启动后，您应该看到一个 Linux 启动序列。

## 网络设置

下一步是连接网络。 Nerves 生态系统提供各种软件包，[nerves_network](https://github.com/nerves-project/nerves_network) 是我们通过有线以太网端口将设备连接到网络所需的。

其实它已作为 `nerves_init_gadget` 的依赖项存在于您的项目中。 但是，默认情况下，它使用 DHCP（在运行 `config: nerves_init_gadget` 之后，请参阅 `config/config.exs` 中的配置）。 拥有静态 IP 地址更容易。

要设置静态网络，您需要在 `config/config.exs` 文件中添加以下行:

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

请注意，此配置适只适用于有线连接。 如果要使用无线连接——请查看[Nerves network documentation](https://github.com/nerves-project/nerves_network#wifi-networking).

请注意，您需要根据所在的局域网的具体情况设置这里的参数，在我的网络中有一个未分配的 IP `192.168.88.2`，所以使用了这个 IP。 但是在您的网络环境中，这些参数可能会有所不同。

更改后，我们需要运行 `mix firmware.burn` 重新烧录固件的更改版本，然后使用新卡启动设备。

当您打开设备电源后，可以使用 `ping` 命令查看它是否在线。

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

此输出表示设备已经连上网，并且可以被访问到了

## 远程更新

到目前为止，我们一直在烧录 SD 卡并将它们通过物理方式加载到我们的硬件中。 虽然这很好，但通过网络推送我们的更新更为直接。 `nerves_firmware_ssh` 包正是做这个事的。 默认情况下，它已存在于您的项目中，并配置为自动检测并在目录中查找 SSH 密钥。

要使用网络固件更新功能，您需要通过 `mix firmware.gen.script` 生成上传脚本。 该命令将生成一个新的 `upload.sh` 脚本，我们可以运行该脚本来更新固件。

如果在上一步之后网络正常运行，您就可以开始使用了。

要更新您的设置，最简单的方法是使用 `mix firmware && ./upload.sh 192.168.88.2`：第一个命令创建更新的固件，第二个命令通过网络推送它并重新启动设备。 您最终可以停止将 SD 卡插入和拔出设备！

_提示：`ssh 192.168.88.2` 在应用程序的上下文中为您提供设备上的 IEx shell。_

_故障排除：如果您的主文件夹中没有现有的 ssh 密钥，则会出现错误 `No SSH public keys found in ~/.ssh.` 在这种情况下，您需要运行 `ssh-keygen` 并重新烧录固件以使用网络更新功能._

## 控制 LED

要与 LED 交互，需要安装 [nerves_leds](https://github.com/nerves-project/nerves_leds) 软件包，这需要添加 `{:nerves_leds，"〜> 0.8", targets: @all_targets},` 到 `mix.exs` 文件。

设置依赖关系后，需要为设备配置 LED 列表。 例如，对于所有 Raspberry Pi 型号，板载只有一个 LED：`led0`。 让我们通过在 `config/config.exs` 中添加一行 `config: nerves_leds, names:[green: "led0"]` 来使用它。


对于其他设备，您可以查看[nerves_examples 项目的相应部分](https://github.com/nerves-project/nerves_examples/tree/master/hello_leds/config).

配置 LED 后，我们肯定需要以某种方式控制它。 为此，我们将在 `lib/network_led/blinker.ex` 中添加一个 GenServer（请参阅 [OTP Concurrency](../../advanced/otp-concurrency) 课程中有关 GenServers 的详细信息），其中包含以下内容：

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

要启用此功能，还需要将其添加到 `lib/network_led/application.ex` 中的监督树中：在 `def children（_target）do` 组下添加 `{NetworkLed.Blinker, name: NetworkLed.Blinker}`。

请注意，Nerves 在应用程序中有两个不同的监督树 - 一个用于主机，一个用于实际设备。

在此之后 - 就是这样！ 您实际上可以上传固件并通过目标设备上的 ssh 运行 IEx 检查 `NetworkLed.Blinker.disable()` 关闭 LED（默认情况下在代码中启用），以及 `NetworkLed.Blinker.enable()` 打开它。

我们可以从命令提示符控制 LED 了！

现在，剩下的唯一缺失的部分是通过网络界面控制 LED。

## 添加 Web 服务器

在这一步中，我们将使用 `Plug.Router`。 如果您需要提醒 - 请随意浏览[插件](../../../lessons/specifics/plug/) 课程.

首先，我们将 `{plug_cowboy, '〜> 2.0“}，` 添加到 `mix.exs` 并安装依赖项。

然后，在 `lib/network_led/http.ex` 中添加实际进程来处理这些请求：

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
最后一步 - 将 `{Plug.Cowboy, scheme: :http, plug: NetworkLed.Http, options: [port: 80]}` 添加到应用程序监督树中。

固件更新后，您可以试试。 访问 `http://192.168.88.2/` 将返回纯文本响应，`http://192.168.88.2/enable` 和 `http://192.168.88.2/disable` 将控制禁用并启用该 LED！

您甚至可以将 Phoenix 支持的用户界面打包到您的 Nerves 应用程序中，但是，这[需要进行一些调整](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces)。
