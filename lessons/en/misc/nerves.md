%{
  version: "1.1.2",
  title: "Nerves",
  excerpt: """
  """
}
---

## Introduction and requirements

We will be talking about Nerves in this lesson.
The Nerves project is a framework for using Elixir in embedded software development.
As the website for Nerves says, it allows you to "craft and deploy bulletproof embedded software in Elixir".
This lesson will be a bit different from other Elixir School lessons.
Nerves is a bit more difficult to get into as it requires both some advanced system setup and additional hardware, so may not be suitable for beginners.

To write embedded code using Nerves, you will need one of the [supported targets](https://hexdocs.pm/nerves/targets.html), a card reader with a memory card supported by the hardware of your choice, as well as wired networking connection to access this device by the network.

However, we would suggest using a Raspberry Pi, due to it having controllable LED onboard.
It is also advisable to have a screen connected to your target device as this will simplify debugging using IEx.

## Setup

The Nerves project itself has an excellent [Getting started guide](https://hexdocs.pm/nerves/getting-started.html), but the amount of detail there may be overwhelming for some users.
Instead, this tutorial will try and present "fewer words, more code".

Firstly, you will need an environment set up.
You can find the guide in the [Installation](https://hexdocs.pm/nerves/installation.html) part of Nerves wiki.
Please make sure that you have the same version of both OTP and Elixir mentioned in the guide.
Not using the right version can cause trouble as you progress.
At the time of writing, any Elixir (compiled with Erlang/OTP 21) should work.

After getting set up, you should be ready to build your first Nerves project!

Our goal will be getting to the "Hello world" of embedded development: a blinking LED controlled by calling a simple HTTP API.

## Creating a project

To generate a new project, run `mix nerves.new network_led` and answer `Y` when prompted whether to fetch and install dependencies.

You should get the following output:

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

Our project has been generated and is ready to be flashed to our test device!
Let's try it now!

In the case of a Raspberry Pi 3, you set `MIX_TARGET=rpi3`, but you can change this to suit the hardware you have depending on the target hardware (see the list in the [Nerves documentation](https://hexdocs.pm/nerves/targets.html#content)).

Let's set up our dependencies first:

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

Note: be sure you have set the environment variable specifying the target platform before running `mix deps.get`, as it will download the appropriate system image and toolchain for the specified platform.

## Burning the firmware

Now we can proceed to flashing the drive.
Put the card into the reader, and if you set up everything correctly in previous steps, after running `mix firmware.burn` and confirming the device to use you should get this prompt:

```
Building ......../network_led/_build/rpi_dev/nerves/images/network_led.fw...
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
```

If you are sure this is the card you want to burn - pick `Y` and after some time the memory card is ready:

```
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
|====================================| 100% (32.51 / 32.51) MB
Success!
Elapsed time: 8.022 s
```

Now it is time to put the memory card into your device and verify whether it works.

If you have a screen connected - you should see a Linux boot sequence on it after powering up the device with this memory card inserted.

## Setting up networking

The next step is to set up the network.
The Nerves ecosystem provides a variety of packages, and [vintage_net](https://github.com/nerves-networking/vintage_net) is what we will need to connect the device to the network over the wired Ethernet port.

It is already present in your project as a dependency of [`nerves_pack`](https://github.com/nerves-project/nerves_pack).
However, by default, it uses DHCP (see the configuration for it in `config/target.exs` after `config :vintage_net`).
It is easier to have a static IP address.

To set up static networking on the wired Ethernet port, you need to update the `:vintage_net` configuration in `config/target.exs` as follows:

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

Please note that this configuration only updates the wired Ethernet port.
If you want to use the wireless connection - take a look at the [VintageNet Cookbook](https://hexdocs.pm/vintage_net/cookbook.html#wifi).

Note that you need to use your local network parameters here - in my network there is an unallocated IP `192.168.88.2`, which I am going to use.
However, in your case, it may differ.

After changing this, we will need to burn the changed version of the firmware via `mix firmware.burn`, then start up the device with the new card.

When you power up the device, you can use `ping` to see it coming online.

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

This output means that the device now is reachable from the network.

## Network firmware burning

So far, we have been burning SD cards and physically load them into our hardware.
While this is fine to start with, it is more straightforward to push our updates over the network.
The [`ssh_subsystem_fwup`](https://github.com/nerves-project/ssh_subsystem_fwup) package does just that.
It is already present in your project by default and is configured to auto-detect and find SSH keys in your `~/.ssh` directory.

To use the network firmware update functionality, you will need to generate an upload script via  `mix firmware.gen.script`.
This command will generate a new `upload.sh` script which we can run to update the firmware.

If the network is functional after the previous step, you are good to go.

To update your setup, the simplest way is to use `mix firmware && ./upload.sh 192.168.88.2`: the first command creates the updated firmware, and the second one pushes it over the network and reboots the device.
You can finally stop having to swap SD cards in and out of the device!

_Hint: `ssh 192.168.88.2` gives you an IEx shell on the device in the context of the app._

_Troubleshooting: If you don't have an existing ssh key in your home folder, you will have an error `No SSH public keys found in ~/.ssh.`.
In this case, you will need to run `ssh-keygen` and re-burn the firmware to use the network update feature._

## Setting up the LED control

To interact with LEDs, you need [nerves_leds](https://github.com/nerves-project/nerves_leds) package installed which is done by adding `{:nerves_leds, "~> 0.8", targets: @all_targets},` to `mix.exs` file.

After setting up the dependency, you need to configure the LED list for the given device.
For example, for all Raspberry Pi models, there is only one LED onboard: `led0`.
Let's use it by adding a `config :nerves_leds, names: [green: "led0"]` line to the `config/config.exs`.

For other devices, you can take a look at the [corresponding part of the nerves_examples project](https://github.com/nerves-project/nerves_examples/tree/main/hello_leds/config).

After configuring the LED itself, we surely need to control it somehow.
To do that, we will add a GenServer (see details about GenServers in [OTP Concurrency](/en/lessons/advanced/otp_concurrency) lesson) in `lib/network_led/blinker.ex` with these contents:

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

To enable this, you also need to add it to the supervision tree in `lib/network_led/application.ex`: add `{NetworkLed.Blinker, name: NetworkLed.Blinker}` under the `def children(_target) do` group.

Notice that Nerves has two different supervision trees in application - one for the host machine and one for actual devices.

After this - that's it! You actually can upload the firmware and via running IEx through ssh on target device check that `NetworkLed.Blinker.disable()` turns the LED off (which is enabled by default in code), and `NetworkLed.Blinker.enable()` turns it on.

We have control over the LED from the command prompt!

Now the only missing piece of the puzzle left is to control the LED via the web interface.

## Adding the web server

In this step, we will be using `Plug.Router`.
If you need a reminder - feel free to skim through the [Plug](/en/lessons/misc/plug) lesson.

First, we will add `{:plug_cowboy, "~> 2.0"},` to `mix.exs` and install the dependencies.

Then, add the actual process to process those requests in `lib/network_led/http.ex` :

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

And, the final step - add `{Plug.Cowboy, scheme: :http, plug: NetworkLed.Http, options: [port: 80]}` to the application supervision tree.

After the firmware update, you can try it! `http://192.168.88.2/` is returning plain text response, and `http://192.168.88.2/enable` with `http://192.168.88.2/disable` disable and enable that LED!

You can even pack Phoenix-powered user interfaces into your Nerves app, however, it [will require some tweaking](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces).
