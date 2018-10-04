---
version: 1.2.0
title: Plug
---

Si estás familiarizado con Ruby puedes imaginar que Plug es como Rack con un poquito de Sinatra.
Este proporciona una especificación para componentes de aplicaciones web y adaptadores para servidores web.
Si bien no forma parte del núcleo de Elixir, Plug es un proyecto oficial de Elixir.

Empezaremos creando una aplicación web mínima basada en Plug.
Despues de eso, aprenderemos acerca del enrutador de Plug y como agregar Plug a una aplicación web existente.

{% include toc.html %}

## Prerrequisitos

Este tutorial asume que ya tienes Elixir y `mix` instalado.

Si no has iniciado un proyecto, crea uno de la siguiente manera:

```shell
$ mix new example
$ cd example
```


## Instalación

La instalación es cosa fácil con mix.
Para instalar Plug tenemos que hacer dos pequeños cambios en nuestro `mix.exs`.
Lo primero que se debe hacer es añadir Plug y un servidor web (usaremos Cowboy) en nuestro archivo como dependencias:

```elixir
defp deps do
  [{:cowboy, "~> 1.1.2"}, {:plug, "~> 1.3.4"}]
end
```

En la línea de comando, ejecuta la siguiente tarea de mix para actualizar estas nuevas dependencias:

```shell
$ mix deps.get
```

## La especificación

Para comenzar a crear Plugs, necesitamos conocer, y adherirse a la especificación Plug. 
Afortunadamente para nosotros, sólo hay dos funciones necesarias: `init/1` y `call/2`.

Aquí hay un Plug simple que devuelve "Hello World!":

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end
end
```

Guarda el archivo en `lib/example/hello_world_plug.ex`.

La función `init/1` se utiliza para inicializar las opciones de nuestros Plugs. Esta es llamada por el árbol de supervisión, el cual se explica en la siguiente sección. De momento, está será una lista vacía que es ignorada.

El valor retornado por la función `init/1` eventualmente será pasado a `call/2` como su segundo argumento.

La función `call/2` es ejecutada por cada petición que viene desde el servidor web, Cowboy. Esta recibe una estructura de conexión `%Plug.Conn{}` como su primer argumento y se espera que retorne una estructura de conexión `%Plug.Conn{}`.

## Configurando el Módulo de Aplicación del proyecto

Debido a que estamos iniciando nuestra aplicación plug desde cero, necesitamos definir el módulo de la aplicación.
Actualiza `lib/example.ex` para iniciar y supervisar Cowboy:

```elixir
defmodule Example do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.HelloWorldPlug, [], port: 8080)
    ]

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Esto supervisa Cowboy, y a su vez, supervisa nuestro  `HelloWorldPlug`.

En la petición a `Plug.Adapters.Cowboy.child_spec/4`, el tercer argumento será pasado a  `Example.HelloWorldPlug.init/1`.

Aún no hemos terminado. Abre `mix.exs` de nuevo, y busca la función `applications`.
De momento la parte de `aplication` en `mix.exs` necesita dos cosas:

1) Una lista de aplicaciones de dependencia  (`cowboy`, `logger`, and `plug`) que necesintan iniciar, y
2) Configuración para nuestra aplicación, la cual también deberá iniciar automáticamente.
Vamos a actualizarla para hacerlo:

```elixir
def application do
  [
    extra_applications: [:cowboy, :logger, :plug],
    mod: {Example, []}
  ]
end
```

Estamos listos para probar este servidor web, minimalístico basado en Plug.
En la línea de comando ejecuta:

```shell
$ mix run --no-halt
```

Cuando todo termine de compilar, y el mensaje `[info]  Started app` aparece, abre el explorador web en `127.0.0.1:8080`. Este debera de desplegar:

```
Hello World!
```

## Plug.Router

Para la mayorìa de aplicaciones, como un sitio web o un API REST, necesitaras un enrutador que enrute las solicitudes para las distintas rutas y verbos HTTP hacia los distintos manejadores.
`Plug` provee un enrutador para hacer esto. Como estamos a punto de ver, no necesitamos un framework como Sinatra en Elix ya que lo conseguimos fácilmente con Plug.

Para empezar vamos a crear un archivo en `lib/example/router.ex` y copia lo siguiente en el mismo:

```elixir
defmodule Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

Este es un router simple y básico pero el código debería explicarse por sí mismo.
Hemos incluido algunas macros a través de `use Plug.Router` y luego configurado dos de los Plugs incorporados:`:match` y `:dispatch`.
Hay dos rutas definidas, una para el manejo de GET que retorna a la raíz y la segunda para hacer coincidir todas las demás solicitudes para que podamos devolver un mensaje 404.

De vuelta en `lib/example.ex`, necesitamos agregar `Example.Router` en el árbol de supervisión del servidor web.
Cambia el plug `Example.HelloWorldPlug` al nuevo enrutador:

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]

  Logger.info("Started application")
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Inicia el servidor de nuevo, detén el anterior si aún sigue corriendo.(Presiona `Ctrl+C` dos veces).


Ahora en un navegador web ve a `127.0.0.1:8080`.
Deberá de mostrar `Welcome`.
Ahora, ve a `127.0.0.1:8080/waldo`, o cualquier otra ruta.
Esta deberá de mostrar `Oops!` con una repuesta 404.

## Agregando otro Plug

Es muy común crear Plugs que intercepten todas las peticiones o un conjunto de estas, para controlar la lógica de manejo de peticiones comunes.

Para este ejemplo vamos a crear un plug que verifica si la solicitud tiene algún conjunto de parámetros requeridos.
Mediante la implementación de nuestra validación en un Plug podemos estar seguros de que sólo las solicitudes válidas se hacen a través de nuestra aplicación.
Esperamos que nuestro Plug sea inicializado con dos opciones: `:paths` y `:fields`. Estas representarán las rutas que aplicamos a nuestra lógica y los campos que se requieren.

_Nota_: Los Plugs son aplicados a todas las peticiones y por eso vamos a manejar solicitudes filtradas y aplicaremos nuestra lógica a sólo un subconjunto de ellas.
Para ignorar una petición, simplemente la pasamos a través de la conexión.

Vamos a empezar por mirar nuestro Plug terminado y entonces discutiremos cómo funciona, lo crearemos en `lib/example/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified =
      body_params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

La primera cosa a destacar es que hemos definido una nueva excepción `IncompleteRequestError` y una de sus opciones es `:plug_status`.
Cuando esté disponible esta opción será utilizada por Plug para establecer el código de estado HTTP en el caso de una excepción.

La segunda parte de nuestro Plug es la función `call/2`.
Aquí es donde nos encargamos de decidir si aplicaremos nuestra lógica de verificación.
Sólo cuando la ruta de la solicitud figure en nuestro `:paths` vamos a llamar `verify_request!/2`.

La última parte de nuestro plug es la función privada `verify_request!/2` que verifica si los `:fields` requeridos están todos presentes.
En el caso de que falte alguno, levantamos la excepción `IncompleteRequestError`.

Hemos configurado nuestro Plug para verficar que todas las peticiones a `/upload` incluyan tanto `"content"` como `"mimetype"`.
Solo en estos casos el código del router será ejecutado.

Ahora, le indicamos al router del nuevo Plug.
Edita `lib/example/router.ex` y realiza los siguientes cambios:

```elixir
defmodule Example.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  post("/upload", do: send_resp(conn, 201, "Uploaded"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

## Haciendo que el Puerto HTTP sea Configurable

De vuelta cuando definimos el modulo y la aplicación `Example`, el puerto estaba quemado en el módulo.
Se considera una buena práctica hacer que el puerto sea configurado incluyéndolo en el archivo de configuración.

Empecemos actualizando la porción de `application` en `mix.exs` para indicar a Elixir acerca de nuestra aplicación y especificar una variable de entorno de aplicación.
Con esos cambios listos nuestro código debe de verse similar a este:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug], mod: {Example, []}, env: [cowboy_port: 8080]]
end
```

Nuestra aplicación es configurada con la línea `mod: {Example, []}`.
Debes de notar que tambien estamos inicializando las aplicaciones `cowboy`, `logger` y `plug`.

Ahora necesitamos actualizar `lib/example.ex` para la lectura del valor de configuración del puerto, y pasarlo a Cowboy.

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Plug.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

El tercer argumento the `Application.get_env` es el valor predeterminado, para cuando la directiva de configuración no esté definida.

> (Opcional) agregar `:cowboy_port` en `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Ahora para correr nuestra aplicación podemos utilizar:
```shell
$ mix run --no-halt
```

## Probando un Plug

Probar un plug es muy sencillo gracias a `Plug.test`.
Este incluye un número de funciones convenientes que facilitan las pruebas.

Comprueba si puedes darle seguimiento a la pueba del router:

```elixir
defmodule Example.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn =
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      conn(:get, "/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```


## Plugs disponibles

Hay una serie Plugs disponibles por defecto.
La lista completa se puede encontrar en la documentación de Plug [aquí](https://github.com/elixir-lang/plug#available-plugs).
