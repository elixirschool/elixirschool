%{
  version: "1.1.2",
  title: "Nerves",
  excerpt: """
  """
}
---

## Введение и требования

Мы поговорим о Nerves в этом уровке.
Проект Nerves - это фреймворк для использования Elixir в разработке встроенного программного обеспечения.
Как говорится на сайте Nerves, он позволяет вам "создавать и развёртывать надёжное встроенное программное обеспечение на Elixir".
Данный урок будет немного отличаться от других уроков.
Nerves является более сложным для вхождения, потому что требует расширенной настройки как системы, так и дополнительного оборудования, что может не подходить для начинающих.

Чтобы писать встроенный код с использованием Nerves, вам понадобится что-нибудь из [перечисленного](https://hexdocs.pm/nerves/supported-targets.html) поддерживаемого оборудования, кардридер с картой памяти, поддерживаемой выбранным вами оборудованием, а также проводное сетевое соединение для доступа к этому устройству по сети.

Мы рекомендуем использовать Raspberry Pi, поскольку он имеет на борту управляемый светодиод.
Также желательно подключить экран к целевому устройству, так как это упростит отладку с использованием IEx.

## Настройка

Проект Nerves сам по себе имеет отличное [Руководство для старта](https://hexdocs.pm/nerves/getting-started.html), но для некоторых пользователей количество подробностей может оказаться непосильным.
Напротив, данный урок построен по принципу "меньше слов, больше кода".

Во-первых, вам понадобится настроить окружение.
Вы можете найти [Руководство по установке](https://hexdocs.pm/nerves/installation.html) в документации Nerves.
Убедитесь, что у вас установлена ​​та же версия OTP и Elixir, которая указана в руководстве.
Использование неправильной версии может привести к проблемам по мере изучения урока.
На момент написания статьи должна работать любая версия Elixir, скомпилированная с помощью Erlang/OTP 21.

После настройки вы будете готовы создать свой первый проект Nerves!

Нашей целью будет получить «Hello world» в разработке встраиваемых систем: мигающий светодиод, управляемый вызовом простого HTTP API.

## Создание проекта

Чтобы создать новый проект, запустите `mix nerves.new network_led` и ответьте `«Да»`(`«Y»`) на вопрос о том, следует ли загрузить и установить зависимости.

Вы должны получить следующий вывод в консоли:

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

Наш проект сгенерирован и готов, чтобы стать прошивкой для нашего тестового устройства!
Давайте запустим его прямо сейчас!

В случае Raspberry Pi 3 переменная окружения установлена следующим образом: `MIX_TARGET=rpi3`. Вы можете изменить её в соответствии с имеющимся у вас оборудованием (см. список в [документации Nerves](https://hexdocs.pm/nerves/targets.html#content)).

Сначала давайте настроим наши зависимости:

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

Замечание: перед запуском `mix deps.get` убедитесь, что вы установили переменную окружения, указывающую целевую платформу, поскольку произойдёт загрузка соответствующего образа системы и набора инструментов для указанной платформы.

## Запись прошивки

Теперь можно приступить к прошивке накопителя.
Вставьте карту в считыватель, и если вы все правильно настроили на предыдущих шагах, после запуска `mix firmware.burn` и подтверждения используемого устройства вы должны получить следующее сообщение:

```
Building ......../network_led/_build/rpi_dev/nerves/images/network_led.fw...
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
```

Если вы уверены, что это именно та карта, которую вы хотите записать, выберите `«Да»`(`«Y»`) и через некоторое время карта памяти будет готова:

```
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
|====================================| 100% (32.51 / 32.51) MB
Success!
Elapsed time: 8.022 s
```

Теперь пришло время вставить карту памяти в ваше устройство и проверить ее работу.

Если у вас подключен экран, вы должны увидеть на нем последовательность загрузки Linux после включения устройства со вставленной картой памяти.

## Настройка сети

Следующий шаг — настройка сети.
Экосистема Nerves предоставляет множество пакетов, и [vintage_net](https://github.com/nerves-networking/vintage_net) — это то, что нам понадобится для подключения устройства к сети через проводной порт Ethernet.

Данный пакет уже присутствует в вашем проекте как зависимость [`nerves_pack`](https://github.com/nerves-project/nerves_pack).
Однако по умолчанию он использует протокол динамической конфигурации DHCP (см. конфигурацию для него в `config/target.exs` после `config :vintage_net`).
Для простоты установим статический IP-адрес.

Чтобы настроить статическую сеть на проводном порту Ethernet, необходимо обновить конфигурацию `:vintage_net` в `config/target.exs` следующим образом:

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

Обратите внимание, что эта конфигурация обновляет только проводной порт Ethernet.
Если вы хотите использовать беспроводное соединение — ознакомьтесь с [Кулинарной книгой VintageNet](https://hexdocs.pm/vintage_net/cookbook.html#wifi).

Обратите внимание, что здесь вам необходимо использовать параметры вашей локальной сети — в моей сети есть невыделенный IP-адрес `192.168.88.2`, который я собираюсь использовать.
Однако в вашей сети невыделенный IP-адрес может отличаться.

После внесения изменений нам потребуется записать измененную версию прошивки с помощью `mix firmware.burn`, а затем запустить устройство с картой, на которой записана новая версия прошивки.

При включении устройства вы можете использовать команду `ping`, чтобы увидеть, что оно подключено к сети.

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

Этот вывод означает, что устройство теперь доступно из сети.

## Прошивка по сети

До сих пор мы записывали SD-карты и физически загружали их в наше оборудование.
Первое время этого достаточно, но гораздо проще устанавливать наши обновления по сети.
Пакет [`ssh_subsystem_fwup`](https://github.com/nerves-project/ssh_subsystem_fwup) делает именно это.
Он уже присутствует в вашем проекте по умолчанию и настроен на автоматическое обнаружение и поиск ключей SSH в вашем каталоге `~/.ssh`.

Чтобы использовать функцию обновления прошивки по сети, вам необходимо сгенерировать скрипт загрузки с помощью команды `mix firmware.gen.script`.
Эта команда сгенерирует новый скрипт `upload.sh`, который мы сможем запустить для обновления прошивки.

Если после предыдущего шага сеть функционирует, все готово.

Чтобы обновить настройки, проще всего использовать `mix firmware && ./upload.sh 192.168.88.2`: первая команда создает обновленную прошивку, а вторая отправляет ее по сети и перезагружает устройство.
Наконец-то вам больше не придется постоянно вставлять и вынимать SD-карты из устройства!

_Подсказка: `ssh 192.168.88.2` предоставляет вам оболочку IEx на устройстве в контексте приложения._

_Устранение неполадок: Если в вашей домашней папке нет существующего ключа SSH, вы получите ошибку `No SSH public keys found in ~/.ssh.`.
В этом случае вам нужно будет запустить `ssh-keygen` и повторно записать прошивку, чтобы использовать функцию обновления по сети._

## Настройка управления светодиодами

Для взаимодействия со светодиодами вам необходимо установить пакет [nerves_leds](https://github.com/nerves-project/nerves_leds), что делается путем добавления зависимости `{:nerves_leds, "~> 0.8", targets: @all_targets},` в файл `mix.exs`.

После установки зависимости вам необходимо настроить список светодиодов для данного устройства.
Например, для всех моделей Raspberry Pi на плате есть только один светодиод: `led0`.
Давайте используем его, добавив строку `config :nerves_leds, names: [green: "led0"]` в `config/config.exs`.

Для других устройств вы можете взглянуть на [соответствующую часть проекта nerves_examples](https://github.com/nerves-project/nerves_examples/tree/main/hello_leds/config).

После настройки самого светодиода нам, конечно, нужно как-то им управлять.
Для этого мы добавим GenServer (подробности о GenServers см. в уроке [OTP Concurrency](/en/lessons/advanced/otp_concurrency)) в `lib/network_led/blinker.ex` с таким содержимым:

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

Чтобы запустить полученный GenServer, его необходимо добавить в дерево супервизора `lib/network_led/application.ex` в качестве дочернего процесса: добавьте кортеж `{NetworkLed.Blinker, name: NetworkLed.Blinker}` в группу `def children(_target) do`.

Обратите внимание, что в приложении Nerves имеется два разных дерева супервизоров: одно для хост-машины и одно для реальных устройств.

Вот и всё! Фактически вы можете загрузить прошивку и, запустив IEx через ssh на целевом устройстве, проверить, что `NetworkLed.Blinker.disable()` выключает светодиод (который включен по умолчанию в коде), а `NetworkLed.Blinker.enable()` включает его.

Теперь мы можем управлять светодиодом из командной строки!

Остаётся только один недостающий элемент головоломки — управление светодиодом через веб-интерфейс.

## Добавление веб-сервера

На этом этапе мы будем использовать `Plug.Router`.
Если вам нужно освежить знания, просмотрите урок [Plug](/en/lessons/misc/plug).

Сначала мы добавим `{:plug_cowboy, "~> 2.0"},` в `mix.exs` и установим зависимости.

Затем напишем сам процесс обработки запросов в `lib/network_led/http.ex`:

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

И последний шаг: необходимо добавить `{Plug.Cowboy, scheme: :http, plug: NetworkLed.Http, options: [port: 80]}` в дерево супервизора приложения.

После обновления прошивки вы можете использовать веб-интерфейс для управления светодиодом! `http://192.168.88.2/` возвращает простой текстовый ответ, а `http://192.168.88.2/enable` и `http://192.168.88.2/disable` включают и отключают наш светодиод!

Вы даже можете упаковать пользовательские интерфейсы на базе Phoenix в свое приложение Nerves, однако это [потребует некоторой настройки](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces).
