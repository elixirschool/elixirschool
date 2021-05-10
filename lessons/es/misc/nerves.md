%{
  version: "1.0.1",
  title: "Nerves",
  excerpt: """
  
  """
}
---

## Introducción y requerimientos

Vamos a hablar acerca de Nerves en esta lección. El proyecto Nerves es un *framework* para usar Elixir en desarrollo de software embebido. Como dice el sitio web de Nerves, te permite "crear y desplegar software embebido a prueba de fallas". Esta lección será un poco diferente de otra lecciones de Elixir School. Nerves es un poco mas difícil de entender y requiere una configuración avanzada y hardware adicional por lo que puede no ser recomendable para principiantes.

Para escribir código embebido usando Nerves necesitarás uno de los [sistemas compatibles](https://hexdocs.pm/nerves/targets.html), un lector de tarjetas con una tarjeta de memoria soportada por el hardware de tu elección y también una conexión cableada de red para acceder a este dispositivo mediante la red.

Sin embargo sugerimos usar una Raspberry Pi debido a que tiene un LED controlable integrado. Es también aconsejable tener una pantalla conectada a tu dispositivo para simplificar el debugging usando IEx.

## Configuración

El proyecto Nerves en si mismo tiene una excelente [Guía para empezar](https://hexdocs.pm/nerves/getting-started.html) pero la cantidad de detalle puede ser abrumadora para algunos usuarios. En cambio este tutorial intentará presentar "menos palabras y más código".

Primeramente necesitarás un entorno de desarrollo. Puedes encontrar una guía en la parte de [instalación](https://hexdocs.pm/nerves/installation.html) en la wiki de Nerves. Por favor asegúrate que tienes la misma versión de Elixir y OTP mencionada en la guía. No usar la versión adecuada puede causar problemas en tu progreso. Al momento de escribir esta lección cualquier versión de Elixir(compilada con Erlang/OTP 21) debería funcionar.

Luego de tener la configuración para el "Hola mundo" del desarrollo embebido: un LED parpadeante controlado por una simple llamada HTTP.

Nuestro objetivo será realizar el "Hola mundo" del desarrollo embebido: un LED parpadeante controlado por una simple llamada HTTP.

## Creando un proyecto

Para generar un nuevo proyecto ejecuta `mix nerves.new network_led` y responde `Y` cuando te pregunta por descargar e instalar las dependencias.

Deberías obtener la siguiente salida:

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

Nuestro proyecto ha sido generado y está listo para ser grabado en nuestro dispositivo de pruebas. ¡Vamos a intentarlo ahora!

En caso de un Raspberry Pi 3 deber establecer `MIX_TARGET=rpi3` pero puedes cambiar esto para ajustarse al hardware que tengas dependiendo de tu dispositivo (mira la lista de la [documentación de Nerves](https://hexdocs.pm/nerves/targets.html#content)).

Vamos a configurar nuestras dependencias primero:

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

Nota: asegúrate de haber configurado la variable de entorno especificando tu dispositivo antes de ejecutar `mix deps.get`, ahora descargará la imagen de sistema y *toolchain* apropiados para la plataforma específica.

## Grabando el firmware

Ahora podemos proceder a grabar la memoria. Pon la tarjeta de memoria en el lector y si has configurado todo correctamente en los pasos previos después de ejecutar `mix firmware.burn` y confirmar el dispositivo a usar deberías obtener esta salida:

```
Building ......../network_led/_build/rpi_dev/nerves/images/network_led.fw...
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
```

Si estás seguro de que es esta la tarjeta que quieres grabar elige `Y` y luego de unos momentos la tarjeta de memoria estará lista.

```
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
|====================================| 100% (32.51 / 32.51) MB
Success!
Elapsed time: 8.022 s
```

Ahora es momento de poner la tarjeta de memoria en tu dispositivo y verificar que todo funciona.

Si tienes una pantalla conectada deberías ver una secuencia de arranque de Linux en ella luego de encender el dispositivo con la tarjeta de memoria insertada.

## Configurando la red

El siguiente paso es configurar la red. El ecosistema de Nerves provee una variedad de paquetes y [nerves_network](https://github.com/nerves-project/nerves_network) es el que necesitaremos para conectar el dispositivo a la red sobre el puerto de red cableado.

Este paquete ya está presente en tu proyecto como dependencia de `nerves_init_gadget`, Sin embargo por defecto usa DHCP(mira su configuración en `config/config.exs` luego de ejecutar `config :nerves_init_gadget`). Es mas fácil tener una dirección IP estática.

Para configurar la IP estática necesitas agregar las siguientes lineas a `config/config.exs`:

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

Por favor nota que esta configuración es para la conexión cableada. Si quieres usar una conexión inalámbrica revisa la [documentación de red de Nerves](https://github.com/nerves-project/nerves_network#wifi-networking).

Nota que necesitas usar los parámetros de tu red local aquí, en mi red hay una IP no asignada `192.168.88.2` que es la que voy a usar. Sin embargo en tu caso puede ser diferente.

Luego de cambiar esto necesitaremos grabar la versión cambiada del *firmware* mediante `mix firmware.burn` luego iniciar el dispositivo con una nueva tarjeta.

Cuando enciendas tu dispositivo puede usar `ping` para revisar que esté en linea.

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

Esta salida significa que el dispositivo ya es accesible mediante la red.

## Grabando firmware sobre la red

Hasta aquí hemos grabado en tarjetas SD y las hemos cargado fisicamente en nuestro hardware. Mientras que esto está bien para comenzar es preferible actualizar mediante la red. El paquete `nerves_firmware_ssh` hace justamente eso. Ya está presente en tu proyecto y está configurado para auto-detectar y encontrar llaves SSH en tu directorio.

Para usar la funcionalidad de actualización de *firmware* por red necesitarás generar y subir un script mediante `mix firmware.gen.script`. Este comando generará un nuevo script llamado `upload.sh` El cual podemos ejecutar para actualizar el *firmware*.

Si la red está funcional luego del paso previo estás listo para continuar.

Para actualizar tu configuración la forma mas simple es usar `mix firmware && ./upload.sh 192.168.88.2`: el primer comando crea el *firmware* de actualización y el segundo los sube sobre la red y reinicia el dispositivo. Ahora finalmente puede dejar de tener que cambiar tarjetas SD en tu dispositivo.

_Pista: `ssh 192.168.88.2`te da una shell IEx en el dispositivo en el contexto de la aplicación. _

_Solución de problemas: Si no tienes de una llave ssh existente en tu directorio de usuario tendrás un error `No SSH public keys found in ~/.ssh.`. En este caso neecesitarás ejecutar `ssh-keygen` y regrabar el firmware para usar la característica de actualización sobre la red._

## Configurando el control del LED

Para interactuar con LEDs necesitas tener el paquete [nerves_leds](https://github.com/nerves-project/nerves_leds) instalado lo que puedes hacer agregando `{:nerves_leds, "~> 0.8", targets: @all_targets},` al archivo `mix.exs`.

Luego de configurar la dependencia necesitas configurar la lista de LEDs para el dispositivo. Por ejemplo para todos los modelos de Raspberry hay solo un LED en la tarjeta: `led0`. Vamos a usarlo agregando la linea `config :nerves_leds, names: [green: "led0"]` al archivo `config/config.exs`.

Para otros dispositivos puedes revisar la [documentación](https://github.com/nerves-project/nerves_examples/tree/master/hello_leds/config).

Luego de configurar el LED, necesitamos controlarlo de alguna forma. Para hacer eso agregaremos un GenServer (mira los detalles acerca de GenServers en la lección de [Concurrencia OTP](../../advanced/otp-concurrency)) en `lib/network_led/blinker.ex` con este contenido:

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

Para habilitar esto también necesitas agregarlo al árbol de supervisión en `lib/network_led/application.ex`: agrega `{NetworkLed.Blinker, name: NetworkLed.Blinker}` bajo el grupo `def children(_target) do`.

Nota que Nerves tiene dos arboles de supervisión en la aplicación - uno para la máquina *host* y otro para el dispositivo en si.

Luego de esto puedes en efecto subir el *firmware* y usando una sesión IEx a través de ssh en el dispositivo usando `NetworkLed.Blinker.disable()` apagar el LED (el cual está definido en el código).

¡Tenemos control sobre el LED desde la linea de compandos!

Ahora la única pieza perdida del rompecabezas es controlar el LED mediante una interfaz web.

## Agregando un servidor web

En este paso usaremos `Plug.Router`. Si necesitas un recordatorio sientete libre de revisar la lección de [Plug](../../../lessons/specifics/plug/).

Primero agregaremos `{:plug_cowboy, "~> 2.0"},` a `mix.exs` e instalaremos las dependencias.

Luego agrega la función para procesar esa peticiones en `lib/network_led/http.ex` :

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

Y como paso final agrega `{Plug.Cowboy, scheme: :http, plug: NetworkLed.Http, options: [port: 80]}` al árbol de supervisión de la aplicación.

¡Luego de la actualización del *firmware* puedes probarlo! `http://192.168.88.2/` retornará una respuesta en texto plano y con `http://192.168.88.2/enable` y `http://192.168.88.2/disable` puedes activar y desactivar el LED.

Puedes incluso agregar una interfaz de usuario basada en Phoenix a tu aplicación Nerves sin embargo esto [requerirá algunos ajustes mas](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces).
