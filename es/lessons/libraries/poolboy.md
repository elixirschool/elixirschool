---
version: 1.2.0
title: Poolboy
---

Puedes acabarte los recursos de tu sistema si no limitas el número de procesos concurrentes que tu programa puede crear.
[Poolboy](https://github.com/devinus/poolboy) es una librería genérica de pooling para Erlang que es muy usada, ligera y que soluciona este problema.

{% include toc.html %}

## ¿Por qué utilizar Poolboy?

Pensemos por un momento en un ejemplo específico.
Tienes la tarea de construir una aplicación que guarde la información del perfil de un usuario en una base de datos.
Si creas un proceso por cada registro de usuario, estarías creando un número ilimitado de conexiones.
En algún momento el número de conexiones podría llegar a sobrepasar la capacidad del servidor de base de datos.
Eventualmente tu aplicación puede generar timeouts y varias excepciones.

La solución es utilizar un conjunto de workers (procesos) para limitar el número de conexiones en lugar de crear un proceso por cada registro de usuario.
Con eso fácilmente puedes evitar acabarte los recursos de tu sistema.

Ahí es donde Poolboy es útil.
Te permite crear un pool de workers gestionados por un `Supervisor` sin mucho esfuerzo.
Existen muchas librerías que utilizan Poolboy internamente.
Por ejemplo, el pool de conexiones de `postgrex` *(el cual es utilizado por Ecto cuando utiliza PostgreSQL)* y también `redis_poolex` *(un pool de conexiones de Redis)* son algunas de las librerías más populares que usan Poolboy.

## Instalación

La instalación es simple con mix.
Todo lo que necesitamos hacer es agregar Poolboy como dependencia en nuestro archivo `mix.exs`.

Creemos una aplicación primero

```shell
$ mix new poolboy_app --sup
```

Agregamos Poolboy como dependencia en nuestro archivo `mix.exs`.

```elixir
defp deps do
  [{:poolboy, "~> 1.5.1"}]
end
```

Luego descarguemos las dependencias, incluyendo Poolboy.
```shell
$ mix deps.get
```

## Opciones de configuración

Para poder comenzar a utilizar Poolboy necesitamos saber un poco sobre las varias opciones de configuración que posee.

* `:name` - el nombre del pool.
El scope puede ser `:local`, `:global`, o `:via`.
* `:worker_module` - el módulo que representa al worker.
* `:size` - el tamaño máximo del pool.
* `:max_overflow` - número máximo de workers temporales que se crearán cuando el pool esté vacío.
(opcional)
* `:strategy` - `:lifo` o `:fifo`, determina si los workers que regresan al pool deberían agregarse al inicio o al final de los workers existentes.
Por defecto es `:lifo`.
(opcional)

## Configurar Poolboy

Para este ejemplo crearemos un pool de workers responsables de manejar peticiones que calculan la raíz cuadrada de un número.
Mantendremos el ejemplo simple para mantener nuestra atención en Poolboy.

Definamos las opciones de configuración de Poolboy y agreguemos el pool de workers de Poolboy como un worker hijo de nuestra aplicación.
Modifica el archivo `lib/poolboy_app/application.ex`:

```elixir
defmodule PoolboyApp.Application do
  @moduledoc false

  use Application

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: PoolboyApp.Worker,
      size: 5,
      max_overflow: 2
    ]
  end

  def start(_type, _args) do
    children = [
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    opts = [strategy: :one_for_one, name: PoolboyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Lo primero que definimos son las opciones de configuración para el pool.
Nombramos nuestro pool `:worker` y utilizamos el `:scope` como `:local`.
Luego designamos al módulo `PoolboyApp.Worker` como el `:worker_module` que este pool debe usar.
También colocamos el `:size` del pool para que tenga un total de `5` workers.
En caso que todos los workers estén en uso, definimos que se creen `2` workers más para ayudar con la carga utilizando la opción `:max_overflow`.
*(los `overflow` workers desaparecen cuando terminan su trabajo)*

Luego, agregamos la función `:poolboy.child_spec/2` al array de hijos para que el pool de workers inicie cuando la aplicación inicie.
La función toma dos argumentos: el nombre del pool y la configuración del pool.

## Crear un Worker

El módulo para el worker será un simple `GenServer` que calcula la raíz cuadrada de un número, duerme por un segundo e imprime el pid del worker.
Crea el archivo `lib/poolboy_app/worker.ex`:

```elixir
defmodule PoolboyApp.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:square_root, x}, _from, state) do
    IO.puts("process #{inspect(self())} calculating square root of #{x}")
    Process.sleep(1000)
    {:reply, :math.sqrt(x), state}
  end
end
```

## Utilizando Poolboy

Ahora que tenemos nuestro `PoolboyApp.Worker`, podemos probar Poolboy.
Creemos un módulo simple que cree procesos concurrentes utilizando Poolboy.
`:poolboy.transaction/3` es la función que puedes usar para interactuar con el pool de workers.
Crea el archivo `lib/poolboy_app/test.ex`:

```elixir
defmodule PoolboyApp.Test do
  @timeout 60000

  def start do
    1..20
    |> Enum.map(fn i -> async_call_square_root(i) end)
    |> Enum.each(fn task -> await_and_inspect(task) end)
  end

  defp async_call_square_root(i) do
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid -> GenServer.call(pid, {:square_root, i}) end,
        @timeout
      )
    end)
  end

  defp await_and_inspect(task), do: task |> Task.await(@timeout) |> IO.inspect()
end
```

Ejecuta la function de prueba para ver el resultado.

```shell
$ iex -S mix
```

```elixir
iex> PoolboyApp.Test.start()
process #PID<0.182.0> calculating square root of 7
process #PID<0.181.0> calculating square root of 6
process #PID<0.157.0> calculating square root of 2
process #PID<0.155.0> calculating square root of 4
process #PID<0.154.0> calculating square root of 5
process #PID<0.158.0> calculating square root of 1
process #PID<0.156.0> calculating square root of 3
...
```

Si ningún worker está disponible en el pool, Poolboy dará timeout luego del período de timeout por defecto (5 segundos) y no aceptará ninguna nueva petición.
En nuestro ejemplo, hemos aumentado el período de timeout por defecto a un minuto para poder demostrar como podemos cambiar ese valor.
En el caso de esta aplicación, puedes observar el error si cambias el valor de `@timeout` a que sea menor de 1000.

A pesar que estamos intentando crear multiples procesos *(un total de veinte en el ejemplo anterior)*, la función `:poolboy.transaction/3` limitará el número máximo de procesos creados a cinco *(además de dos overflow workers en caso de ser necesario)* tal como lo definimos en nuestra configuración.
Todas las peticiones serán manejadas usando el pool de workers en lugar de crear un proceso nuevo por cada petición.
