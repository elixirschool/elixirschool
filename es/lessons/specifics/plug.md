---
layout: page
title: Plug
category: specifics
order: 1
lang: es
---

Si estás familiarizado con Ruby puedes imaginar que Plug es como Rack con un poquito de Sinatra, este proporciona una especificación para componentes de aplicaciones Web y adaptadores para servidores web. Si bien no forma parte del núcleo de Elixir, Plug es un proyecto Elixir oficial.

{% include toc.html %}

## Instalación

La instalación es cosa fácil con mix. Para instalar Plug tenemos que hacer dos pequeños cambios en nuestro `mix.exs`. Lo primero que se debe hacer es añadir Plug y un servidor web en nuestro archivo como dependencias, usaremos Cowboy:

```elixir
defp deps do
  [{:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"}]
end
```

La última cosa que necesitamos hacer es añadir nuestro servidor web y Plug a nuestra aplicación OTP:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## La especificación

Para comenzar a crear Plugs necesitamos saber, y adherirse a la especificación Plug. Afortunadamente para nosotros, sólo hay dos funciones necesarias: `init/1` y `call/2`.

La función `init/1` se utiliza para inicializar las opciones de nuestros Plugs, pasándose como segundo argumento a nuestra función `call/2`. Además de nuestras opciones inicializadas la función `call/2` recibe un `%Plug.Conn` ya que es el primer argumento y se espera que retorne una conexión.

Aquí hay un Plug simple que devuelve "Hello World!":

```elixir
defmodule HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end
end
```

## Creando un Plug

Para este ejemplo vamos a crear un plug que verifica si la solicitud tiene algún conjunto de parámetros requeridos. Mediante la implementación de nuestra validación en un Plug podemos estar seguros de que sólo las solicitudes válidas se hacen a través de nuestra aplicación. Esperamos que nuestro Plug sea inicializado con dos opciones: `:paths` y `:fields`. Estos representarán las rutas que aplicamos a nuestra lógica y los campos que se requieren.

_Nota_: Los Plugs son aplicados a todas las peticiones y por eso vamos a manejar solicitudes filtradas y aplicaremos nuestra lógica a sólo un subconjunto de ellas. Para ignorar una petición, simplemente la pasamos a través de la conexión.

Vamos a empezar por mirar nuestro Plug terminado y entonces discutiremos cómo funciona, lo crearemos en `lib/plug/verify_request.ex`:

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
    verified = body_params
               |> Map.keys
               |> contains_fields?(fields)
    unless verified, do: raise IncompleteRequestError
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

La primera cosa a destacar es que hemos definido una nueva excepción `IncompleteRequestError` y una de sus opciones es `:plug_status`. Cuando esté disponible esta opción sera utilizada por Plug para establecer el código de estado HTTP en el caso de una excepción.

La segunda parte de nuestro Plug es el método `call/2`, aquí es donde nos encargamos de decidir si aplicaremos nuestra lógica de verificación. Sólo cuando la ruta de la solicitud figure en nuestro `:paths` vamos a llamar `verify_request!/2`.

La última parte de nuestro plug es la función privada `verify_request!/2` que verifica si los `:fields` requeridos están todos presentes. En el caso de que falte alguno, levantamos la excepción `IncompleteRequestError`.

## Usando Plug.Router

Ahora que tenemos nuestro `VerifyRequest`, podemos pasar a nuestro router. Como estamos a punto de ver no necesitamos un framework como Sinatra en Elixir, ya que lo obtenemos de forma gratuita con Plug.

Para empezar vamos a crear un archivo en `lib/plug/router.ex` y copiaremos lo siguiente:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  match _, do: send_resp(conn, 404, "Oops!")
end
```

Este es un router simple y básico pero el código debería explicarse por sí mismo. Hemos incluido algunas macros a través de `use Plug.Router` y luego configurado dos de los Plugs incorporados:`:match` y `:dispatch`. Hay dos rutas definidas, una para el manejo de GET que retorna a la raíz y la segunda para hacer coincidir todas las demás solicitudes para que podamos devolver un mensaje 404.

Vamos a agregar nuestro Plug a el router:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"],
                      paths:  ["/upload"]
  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  post "/upload", do: send_resp(conn, 201, "Uploaded")
  match _, do: send_resp(conn, 404, "Oops!")
end
```

¡Eso es! Hemos creado el Plug para verificar que todas las peticiones a `/upload` incluyen tanto `"content"` como `"mimetype"`, sólo entonces el código del router será ejecutado.

Por ahora nuestro `/upload` no es muy útil pero hemos visto cómo crear e integrar nuestro Plug.

## Corriendo nuestra aplicación web

Antes de que podamos ejecutar nuestra aplicación tenemos que instalar y configurar nuestro servidor web, en este caso Cowboy. Por ahora sólo  haremos los cambios necesarios en el código para ejecutar todo, profundizaremos en detalles en las lecciones posteriores.

Vamos a empezar actualizando la porción `application` de nuestro `mix.exs` para decirle a Elixir sobre nuestra aplicación y establecer una variable de entorno. Con estos cambios en su lugar nuestro código debería verse como esto:

```elixir
def application do
  [applications: [:cowboy, :plug],
   mod: {Example, []},
   env: [cowboy_port: 8080]]
end
```

Lo siguiente que necesitamos es actualizar `lib/example.ex` para iniciar y supervisar Cowboy:

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

Ahora para correr nuestra aplicación podemos usar:

```shell
$ mix run --no-halt
```

## Verificando nuestros Plugs

Verificar Plug es bastante sencillo gracias a `Plug.Test`, este incluye una serie de funciones convenientes para hacer las pruebas fácilmente.

Vea si puedes seguir adelante con la prueba del router:

```elixir
defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Plug.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn = conn(:get, "/", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn = conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
           |> put_req_header("content-type", "application/x-www-form-urlencoded")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn = conn(:get, "/missing", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

## Plugs disponibles

Hay una serie Plugs disponibles por defecto, la lista completa se puede encontrar en la documentación de Plug [aquí](https://github.com/elixir-lang/plug#available-plugs).
