---
version: 1.0.0
title: Bypass
---

Cuando estamos probando nuestras aplicaciones, muchas veces necesitamos hacer requests a servicios externos. Incluso igual y queremos simular distintas situaciones como errores no esperados del servidor. Manejar estos casos de manera eficiente no es fácil en Elixir sin un poco de ayuda.

En esta lección vamos a explorar cómo [bypass](https://github.com/PSPDFKit-labs/bypass) nos puede ayudar a rápida y fácilmente manejar esos requests en nuestras pruebas.

{% include toc.html %}

## ¿Qué es Bypass?

[Bypass](https://github.com/PSPDFKit-labs/bypass) está descrito como "una manera rápida de crear un conector que puede ponerse en lugar de un servidor HTTP real que responda respuestas prehechas a requests de cliente."

¿Qué significa eso?
Debajo del capó, Bypass es una aplicación OTP que se hace pasar por un servidor externo escuchando y respondiendo a requests.
Al responder con respuestas pre-definidas podemos probar cualquier cantidad de posibilidades como cortes en servicio y errores, así como los escenarios que sí esperamos. Todo sin hacer un sólo request externo.

## Cómo usar Bypass

Para ilustrar mejor las funcionalidades de Bypass, construiremos una aplicación de utilería simple que haga ping a una lista de dominios para revisar que estén online.
Para hacer esto, crearemos un nuevo proyecto supervisor y un GenServer para revisar los dominios en un intervalo configurable.
Usando Bypass en nuestras pruebas podremos verificar que nuestra aplicación funcione en muchos escenarios diferentes.

_Nota_: Si quieres saltarte todo hasta el código final, ve al repo de Elixir School [Clinic](https://github.com/elixirschool/clinic) y revísalo.

En este punto deberíamos estar cómodos creando proyectos nuevos de Mix y agregando nuestras dependencias, así nos enfocaremos en los pedazos de código específico que estaremos probando.
Si necesitas acordarte rápido de algo, ve a la sección de [Nuevos Proyectos](https://elixirschool.com/es/lessons/basics/mix#nuevo-proyecto) de nuestra lección [Mix](https://elixirschool.com/es/lessons/basics/mix).

Empecemos por crear un módulo nuevo que se encargará de hacer los requests a nuestros dominios.
Creemos una función `ping/1` con [HTTPoison](https://github.com/edgurgel/httpoison) que tome una URL y regrese `{:ok, body}` para requests HTTP 200 y `{:error, reason}` para cualquier otro:

```elixir
defmodule Clinic.HealthCheck do
  def ping(urls) when is_list(urls), do: Enum.map(urls, &ping/1)

  def ping(url) do
    url
    |> HTTPoison.get()
    |> response()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, body}
  defp response({:ok, %{status_code: status_code}}), do: {:error, "HTTP Status #{status_code}"}
  defp response({:error, %{reason: reason}}), do: {:error, reason}
end
```

Habrás notado que _no_ estamos haciendo un GenServer y es por una buena razón:
Al separar nuestra funcionalidad (y dependencias) del GenServer, podemos probar nuestro código sin la complejidad añadida de concurrencia.

Ya con este código escrito, necesitamos empezar las pruebas.
Antes de que podamos usar Bypass, tenemos que cerciorarnos de que esté corriendo.
Para hacer eso, actualicemos `text/test_helper.exs` para que se vea así:

```elixir
ExUnit.start()
Application.ensure_all_started(:bypass)
```

Ahora que sabemos que Bypass estará corriendo durante nuestras pruebas, vayamos a `test/clinic/health_check_test.exs` y terminemos el setup.
Para preparar a Bypass a que acepte requests, necesitamos abrir la conección con `Bypass.open/1`, lo cual podemos hacer en nuestro setup de callbacks de pruebas:

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end
end
```

Por ahora, nos apoyaremos en que Bypass use su puerto default, pero si necesitamos cambiarlo (que sí lo haremos en una sección más adelante), podemos pasar la opción `:port` a `Bypass.open/1` y un valor como `Bypass.open(port: 1337)`.
Ahora estamos listos para poner a Bypass a trabajar.
Empezaremos con un request exitoso primero:

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  alias Clinic.HealthCheck

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "request with HTTP 200 response", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}")
  end
end
```

Nuestra prueba es suficientemente simple y si la corremos veremos que sí pasa, pero revisemos y veamos qué hace cada pedazo.
Lo primero que vemos en nuestra prueba es la función `Bypass.expect/2`:

```elixir
Bypass.expect(bypass, fn conn ->
  Plug.Conn.resp(conn, 200, "pong")
end)
```
`Bypass.expect/2` toma nuestra conección de Bypass y una función de aridad singular que espera modificar una conección y regresarla. Esta es también una oportunidad para hacer aseveraciones sobre ese request para verificar que está como esperamos.
Actualicemos nuestra url de pruebas para que incluya `/ping` y aseverar tanto la ruta del request como el método HTTP:

```elixir
test "request with HTTP 200 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    assert "GET" == conn.method
    assert "/ping" == conn.request_path
    Plug.Conn.resp(conn, 200, "pong")
  end)

  assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}/ping")
end
```

En la última parte de nuestra prueba usamos `HealthCheck.ping/1` y nos aseguramos que la respuesta sea como esperamos, pero ¿qué hace `bypass.port`?
Bypass está escuchando un puerto local e interceptando esos requests y estamos usando `bypass.port` para encontrar el puerto default, ya que no pasamos uno en `Bypass.open/1`.

Lo siguiente es agregar casos de prueba para errores.
Podemos empezar con una prueba muy similar a la primera pero con algunos cambios menores: regresar un 500 como el código de estatus y aseverar que la tupla `{:error, reason}` fue regresada:

```elixir
test "request with HTTP 500 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    Plug.Conn.resp(conn, 500, "Server Error")
  end)

  assert {:error, "HTTP Status 500"} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

Esta prueba no tiene nada de especial así que continuemos con la siguiente: caídas inesperadas del servidor. Estos son los requests que más nos interesan.
Para lograr esto, no estaremos usando `Bypass.expect/2`, mejor nos vamos a apoyar en `Bypass.down/1` para apagar la conección:

```elixir
test "request with unexpected outage", %{bypass: bypass} do
  Bypass.down(bypass)

  assert {:error, :econnrefused} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

Si corremos nuestras pruebas nuevas veremos que todo pasa, ¡tal como lo esperábamos!
Con nuestro módulo `HealthCheck` probado, podemos avanzar a probarlo en conjunto con nuestro agendador basado en GenServer.

## Múltiples hosts externos

Para nuestro proyecto, mantendremos el agendador muy escueto y dependeremos de `Process.send_after/3` para hacer nuestras revisiones periódicas. Para más información del módulo `Process`, échale un ojo a la [documentación](https://hexdocs.pm/elixir/Process.html).
Nuestro agendador requiere tres parámetros: la colección de sitios, el intervalo de nuestras revisiones, y el módulo que implementa `ping/1`.
Al pasar nuestro módulo como argumento, desacomplamos aún más la funcionalidad de nuestro GenServer, permitiéndonos probar mejor cada cosa en aislamiento:

```elixir
def init(opts) do
  sites = Keyword.fetch!(opts, :sites)
  interval = Keyword.fetch!(opts, :interval)
  health_check = Keyword.get(opts, :health_check, HealthCheck)

  Process.send_after(self(), :check, interval)

  {:ok, {health_check, sites}}
end
```

Ahora tenemos que definir la función `handle_info/2` para el mensaje `:check` enviado por `send_after/2`.
Para mantener esto simple, pasaremos nuestros sitios a `HealthCheck.ping/1` y registraremos los resultados a `Logger.info` ó a `Logger.error` en caso de errores.
Montaremos nuestro código de tal manera que nos permita mejorar las capacidades de reporteo más adelante:

```elixir
def handle_info(:check, {health_check, sites}) do
  sites
  |> health_check.ping()
  |> Enum.each(&report/1)

  {:noreply, {health_check, sites}}
end

defp report({:ok, body}), do: Logger.info(body)
defp report({:error, reason}) do
  reason
  |> to_string()
  |> Logger.error()
end
```
Como dijimos antes, pasaremos los sitios a `HealthCheck.ping/1` y luego iteraremos los resultados con `Enum.each/2` y aplicaremos nuestra función `report/1` contra cada uno.
Con estas funciones puestas, nuestro agendador está listo y nos podemos concentrar en probarlo.

No nos enfocaremos mucho en pruebas unitaris para el agendador, ya que esas no requerirán Bypass. Así que nos podemos saltar al código final:

```elixir
defmodule Clinic.SchedulerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  defmodule TestCheck do
    def ping(_sites), do: [{:ok, "pong"}, {:error, "HTTP Status 404"}]
  end

  test "health checks are run and results logged" do
    opts = [health_check: TestCheck, interval: 1, sites: ["http://example.com", "http://example.org"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "pong"
    assert output =~ "HTTP Status 404"
  end
end
```

Dependemos de una implementación de prueba de cada uno de nuestros chequeos de salud con `TestCheck` junto a `CaptureLog.capture_log/1` para aseverar que los mensajes apropiados fueron registrados.

Ahora que tenemos módulos de `Scheduler` y `HealthCheck` funcionales, escribamos una prueba de integración que verifique que todo funciona bien.
Necesitaremos Bypass para esta prueba y tendremos que manejar múltiples requests Bypass por prueba. Veamos cómo hacemos eso.

Recuerdas el `bypass.port` de hace rato? Cuando necesitamos simular múltiples sitios, la opción `:port` es muy útil.
Como probablemente adivinaste, podemos crear múltiples conecciones Bypass, cada una con un puerto diferente y así simularemos múltiples sitios independientes.
Comenzaremos por revisar nuestro archivo actualizado de `test/clinic_test.exs`:

```elixir
defmodule ClinicTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  test "sites are checked and results logged" do
    bypass_one = Bypass.open(port: 1234)
    bypass_two = Bypass.open(port: 1337)

    Bypass.expect(bypass_one, fn conn ->
      Plug.Conn.resp(conn, 500, "Server Error")
    end)

    Bypass.expect(bypass_two, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    opts = [interval: 1, sites: ["http://localhost:1234", "http://localhost:1337"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "[info]  pong"
    assert output =~ "[error] HTTP Status 500"
  end
end
```
No debería haber nada sorprendente en la prueba de arriba.
En lugar de crear una sola conección en `setup`, creamos dos en nuestra prueba y especificamos sus puertos como 1234 y 1337.
Después vemos nuestras llamadas `Bypass.expect/2` y finalmente el mismo código que tenemos en `SchedulerTest` para iniciar el agendador y aseverar que registramos los mensajes apropiados.

¡Eso es todo! Hemos construido una utilería para mantenernos informados de si hay algún problema con nuestros dominios y hemos aprendido cómo usar Bypass para escribir mejores pruebas con servicios externos.
