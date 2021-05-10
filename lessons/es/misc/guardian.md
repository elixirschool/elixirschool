---
version: 1.2.0
title: Guardian (Básico)
---

[Guardian](https://github.com/ueberauth/guardian) es una librería de autenticación ampliamente utilizada, basada en [JWT](https://jwt.io/) (JSON Web Tokens).

{% include toc.html %}

## JWTs

Un JWT puede proporcionar un token completo para autenticación.
Cuando muchos sistemas de autenticación proporcionan acceso únicamente a un identificador del sujeto para el recurso, JTW lo proporciona junto con otra información como:

* Quién emitió el token
* ¿Para quién es el token?
* Que sistema debe usar el token
* ¿En qué momento se emitió el token?
* ¿En qué momento caduca el token?

Además de estos campos, Guardian proporciona algunos otros campos para facilitar funcionalidad adicional:

* ¿De qué tipo es el token?
* ¿Qué permisos tiene el portador?

Estos son solo algunos campos básicos en un JWT.
Eres libre de agregar cualquier información adicional que tu aplicación requiera.
Solo recuerde mantenerlo corto, ya que el JWT tiene que encajar en el encabezado HTTP.

Esta riqueza significa que puede pasar JWT en su sistema como una unidad de credenciales totalmente contenida.

### Donde usarlos

Los tokens JWT pueden ser utilizados para autenticar cualquier parte de tu aplicación.

* Aplicaciones de una pagina
* Controladores (via sesión del navegador)
* Controladores (via encabezados de autorización - API)
* Canales de Phoenix
* Peticiones de servicio a servicio
* Entre procesos
* Acceso de terceros (OAuth)
* Funcionalidad recuérdame
* Otras interfaces - TCP bruto, UDP, CLI, etc

Los tokens JWT pueden ser usados en cualquier parte de su aplicación donde necesite proveer autenticación verificable.

### ¿Tengo que usar una base de datos?

No necesita rastrear JWT a través de una base de datos.
Simplemente puede confiar en las marcas de tiempo emitidas y de vencimiento para controlar el acceso.
A menudo terminará usando una base de datos para buscar su recurso de usuario pero el JWT en si no lo requiere.

Por ejemplo, si fuera a usar JWT para autenticar la comunicación en un socket UDP, probablemente no usaría una base de datos.
Codifique toda la información que necesite directamente en el token cuando lo emita.
Una vez que lo verifique (revisa que esté firmado correctamente) estará listo.

Sin embargo, puede utilizar una base de datos para rastrear JWT
Si lo hace, obtiene la habilidad de verificar que el token sigue siendo valido
O podrías usar los registros en la base de datos para forzar un cierre de sesión de todos los tokens para el usuario.
Esto se simplifica en Guardian usando [GuardianDb](https://github.com/hassox/guardian_db).
GuardiaDb usa los 'Hooks' de Guardian para realizar verificaciones de validación, guardar y eliminar de la base de datos.

Lo cubriremos más tarde.

## Instalación

Hay varias opciones para configurar Guardian. Las cubriremos en algún momento pero comencemos con una configuración simple.

### Configuración mínima

Para comenzar, hay un puñado de cosas que necesitará.

`mix.exs`

```elixir
def application do
  [
    mod: {MyApp, []},
    applications: [:guardian, ...]
  ]
end

def deps do
  [
    {guardian: "~> x.x"},
    ...
  ]
end
```

`config/config.exs`

```elixir
# en cada archivo de configuración del entorno, debe sobrescribir esto si es externo
config :my_app, MyApp.Guardian,
       issuer: "my_app",
       secret_key: "Secret key. Puede usar `mix guardian.gen.secret` para obtener una"
```


Este es el conjunto mínimo de información que necesita proporcionar a Guardian para operar.
No debe codificar su clave secreta directamente en su configuración de nivel superior
En cambio, cada entorno debe tener su propia clave.
Es común usar el entorno de Mix para secretos en desarrollo y pruebas.
En staging y producción, sin embargo, debe usar secretos fuertes.
(por ejemplo, generado con `mix phoenix.gen.secret`)

Guardian requiere que cree un "Módulo de Implementación". Este módulo es la implementación de sus aplicaciones para un tipo/configuración particular de token. Para ello, use Guardian en su módulo y agregue la configuración relevante.

Cree un modulo que utilice `Guardian`

`lib/my_app/guardian.ex`

```elixir
defmodule MyApp.Guardian do
  use Guardian, otp_app: :my_app

  def subject_for_token(resource, _claims) do

    # Puede usar cualquier valor para el subject de su token pero
    # debería ser útil para recuperar el recurso más adelante, ver
    # cómo se usa en la función `resource_from_claims / 1`.
    # Un 'id' único es un buen subject, una dirección de correo electrónico no única
    # es un subject pobre.
    sub = to_string(resource.id)
    {:ok, sub}
  end
  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(claims) do
    # Aquí buscaremos nuestro recurso de las reclamaciones, el subject puede ser
    # encontrado en la tecla `" sub "`. En `above subject_for_token/2` regresamos
    # la identificación del recurso, así que aquí confiaremos en eso para buscarlo.
    id = claims["sub"]
    resource = MyApp.get_resource_by_id(id)
    {:ok,  resource}
  end
  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
```

Esta es la configuración mínima.
Hay mucho más que puede hacer si lo necesita, pero para comenzar es suficiente.

#### Uso de la aplicación

Ahora que tenemos la configuración para usar Guardian, necesitamos integrarla en la aplicación.
Como esta es la configuración mínima, primero consideremos las peticiones HTTP.

## Peticiones HTTP

Guardian proporciona varios `Plugs` para facilitar la integración con las peticiones HTTP.
Puedes aprender acerca de Plug en una [lección separada](../../specifics/plug/).
Guardian no requiere Phoenix, pero si esta usando Phoenix en los siguientes ejemplos sera más fácil de mostrar.

La forma más fácil de integrarse en HTTP es a través del router
Como la integración de Guardian con HTTP esta basada en plugs, puedes utilizarlos en cualquier lugar donde un plug pueda ser usado.

El flujo general del plug Guardian es:

1. Encuentre un token en la petición (en algún lugar) y verificarlo: `Verify*` plugs
2. Opcionalmente, cargue el recurso identificado en el token: `LoadResource` plug
3. Asegúrese de que haya un token válido para la solicitud y rechace el acceso si no: `EnsureAuthenticated` plug

Para satisfacer todas las necesidades de los desarrolladores de aplicaciones, Guardian implementa estas fases por separado.

Para encontrar el token, use los complementos `Verify *`.

Un `pipeline` es una forma de reunir los diversos plugs para un esquema de autenticación particular.

Vamos a crear algunos `pipelines`.

`lib/my_app/auth_access_pipeline.ex`

```elixir
defmodule MyApp.AuthAccessPipeline do
  use Guardian.Plug.Pipeline, otp_app: :my_app

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
end

```

De forma predeterminada, el plug `LoadResource` devolverá un error si no se puede encontrar ningún recurso. Puede anular este comportamiento utilizando la opción `allow_blank: true`.

Ahora implementamos el `pipeline` que creamos:

```elixir
pipeline :maybe_browser_auth do
  plug MyApp.AuthAccessPipeline
end
```

Estos `pipelines` se pueden usar para componer diferentes requisitos de autenticación.
El primer `pipeline` intenta encontrar un token primero en la sesión y luego vuelve a un encabezado.
Si encuentra uno, cargará el recurso por ti.

El segundo `pipeline` requiere que haya un token válido y verificado presente y que sea del tipo "access".

Para usarlos, agréguelos a su scope.

```elixir
scope "/", MyApp do
  get("/login", LoginController, :new)
  post("/login", LoginController, :create)
  delete("/login", LoginController, :delete)
end

scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth])

  resource("/protected/things", ProtectedController)
end
```

El segundo `scope` garantiza que se pase un token válido para todas las acciones.
No _tiene_ que ponerlos en `pipelines`, podría ponerlos en sus controladores para una personalización súper flexible, pero estamos haciendo una configuración mínima.

Nos falta una pieza hasta ahora.
El plug manipulador de errores es un módulo que implementa una función `auth_error`.

`my_app/auth_error_handler.ex`

```elixir
defmodule MyApp.AuthErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, _opts) do
    body = Jason.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end
```

Agregue su módulo de implementación y controlador de errores a su configuración:

`config/config.exs`

```elixir
config :my_app, MyApp.AuthAccessPipeline,
  module: MyApp.Guardian,
  error_handler: MyApp.AuthErrorHandler
```


#### Básicos

Dentro del controlador, hay un par de opciones sobre cómo acceder al usuario actualmente conectado.
Comencemos con lo más simple.

```elixir
# codificar un token para un recurso
{:ok, token, claims} = MyApp.Guardian.encode_and_sign(resource)

# decodificar y verificar un token
{:ok, claims} = MyApp.Guardian.decode_and_verify(token)

# revocar un token (use GuardianDb o algo similar si necesita revocar para rastrear realmente un token)
{:ok, claims} = MyApp.Guardian.revoke(token)

# Actualizar un token antes de que caduque
{:ok, _old_stuff, {new_token, new_claims}} = MyApp.Guardian.refresh(token)

# Cambie un token de tipo "actualizar" por un nuevo token de tipo "acceso"
{:ok, _old_stuff, {new_token, new_claims}} = MyApp.Guardian.exchange(token, "refresh", "access")

# Buscar un recurso directamente desde un token
{:ok, resource, claims} = MyApp.Guardian.resource_from_token(token)
```

Con plug

```elixir
# Si se carga una sesión, el token/recurso/reclamos se colocará en la sesión y la conexión
# Si no se carga ninguna sesión, el token/recurso/reclamos solo se conecta a la conexión
conn = MyApp.Guardian.Plug.sign_in(conn, resource)

# Opcionalmente con reclamos y opciones
conn = MyApp.Guardian.Plug.sign_in(conn, resource, %{some: "claim"}, ttl: {1, :minute})

# eliminar de la sesión (si se obtiene) y revocar el token
# también puede borrar el token recordarme, si la opción `:clear_remember_me` esta establecida
conn = MyApp.Guardian.Plug.sign_out(conn)

# Establecer un token de "actualización" directamente en una cookie.
# Se puede usar junto con `Guardian.Plug.VerifyCookie`
conn = MyApp.Guardian.Plug.remember_me(conn, resource)

# Obtener la información de la conexión actual
token = MyApp.Guardian.Plug.current_token(conn)
claims = MyApp.Guardian.Plug.current_claims(conn)
resource = MyApp.Guardian.Plug.current_resource(conn)
```

#### Login/Logout

Iniciar y cerrar sesión en una sesión del navegador es muy simple.
En su controlador de inicio de sesión:

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
    	# Usar tokens de acceso.
      # Use access tokens.
      # Se pueden usar otros tokens, como: :refresh etc.
      # Other tokens can be used, like :refresh etc
      conn
      |> MyApp.Guardian.Plug.sign_in(user)
      |> respond_somehow()

    {:error, reason} ->
      nil
      # handle not verifying the user's credentials
  end
end

def delete(conn, params) do
  conn
  |> MyApp.Guardian.Plug.sign_out()
  |> respond_somehow()
end
```

Cuando se utiliza el inicio de sesión de API, es ligeramente diferente porque no hay sesión y debe devolver el token sin procesar al cliente.
Para iniciar sesión en la API, es probable que use el encabezado `Authorization` para proporcionar el token a su aplicación.
Este método es útil cuando no tiene intención de usar una sesión.

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      {:ok, jwt, _claims} = MyApp.Guardian.encode_and_sign(user)
      conn |> respond_somehow(%{token: jwt})

    {:error, reason} ->
  end
end

def delete(conn, params) do
  jwt = MyApp.Guardian.Plug.current_token(conn)
  MyApp.Guardian.revoke(jwt)
  respond_somehow(conn)
end
```

El inicio de sesión de la sesión del navegador llama a `encode_and_sign` debajo del capó para que pueda usarlos de la misma manera.
