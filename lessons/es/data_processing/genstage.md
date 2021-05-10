%{
  version: "1.0.2",
  title: "GenStage",
  excerpt: """
  En esta lección vamos a echar un vistazo muy de cerca a `GenStage`, que rol cumple y como podemos aprovecharlo en nuestra aplicaciones.
  """
}
---

## Introducción

Entonces ¿Qué es GenStage? De la documentación oficial es una "especificación y flujo computacional para Elixir", ¿pero qué significa eso para nosotros?

Lo que significa es que `GenStage` nos provee una forma de definir un *pipeline* de trabajo para ser llevado en pasos independientes en procesos separados; Si has trabajado con *pipelines* antes entonces algunos de estos conceptos deberían ser familiares.

Para mejor entendimiento de cómo trabaja vamos a visualizar un flujo simple de productor-consumidor:

```
[A] -> [B] -> [C]
```

En este ejemplo tenemos 3 fases: `A` un productor, `B` un productor-consumidor y `C` un consumidor.
`A` produce un valor el cual es consumido por `B`, `B` realiza algo de trabajo y retorna un nuevo valor el cual es recibido por nuestro consumidor `C`; el rol de nuestra fase es importante como veremos en la siguiente sección.

Ya que nuestro ejemplo es un productor-a-consumidor 1-a-1 es posible para ambos tener múltiples consumidores y productores en cualquier fase dada.

Para ilustrar mejor estos conceptos vamos a construir un *pipeline* con `GenStage` pero primero vamos a explorar los roles sobre los que `GenStage`se basa un poco mas a fondo.

## Consumidores y productores

Como hemos leído, el rol que damos a nuestra fase es importante.
La especificación de `GenStage` reconoce tres roles:

+ `:producer` — Una fuente.
Los productores esperan por la demanda de los consumidores y responden con los eventos solicitados.

+ `:producer_consumer` — Ambos, una fuente y un sumidero.
Productor-consumidores pueden responder a la demanda de otros consumidor como también a las solicitudes de otros productores.

+ `:consumer` — Un sumidero.
Un consumidor solicita y recibe datos de los productores.

¿Notas de que nuestros productores __esperan__ por demanda? Con `GenStage` nuestros consumidores enviar demanda y procesan los datos de nuestro productor.
Esto facilita un mecanismo conocido como contra-presión(*back-pressure*).
La contra-presión pone la carga en el productor para no sobre presionar cuando los consumidores están ocupados.

Ahora que hemos cubierto los roles dentro de `GenStage` vamos a empezar nuestra aplicación.

## Comenzando

En este ejemplo estaremos construyendo una aplicación `GenStage` que emita números, ordene los números pares y finalmente los imprima.

Para nuestra aplicación usaremos los tres roles de `GenStage`.
Nuestro productor será responsable de contar y emitir los números.
Usaremos un productor-consumidor para filtrar solo los números pares y luego responder a la demanda.
Por último construiremos un consumidor que imprima los números restantes para nosotros.

Comenzaremos generando un proyecto con un árbol de supervisión:

```shell
$ mix new genstage_example --sup
$ cd genstage_example
```

Vamos a actualizar nuestras dependencias en `mix.exs` para incluir `gen_stage`:

```elixir
defp deps do
  [
    {:gen_stage, "~> 0.11"},
  ]
end
```

Deberíamos descargar nuestras dependencias y compilarlas antes de continuar:

```shell
$ mix do deps.get, compile
```

¡Ahora estamos listos para construir nuestro productor!

## Productor

El primer paso para nuestra aplicación `GenStage` es crear nuestro productor.
Como discutimos antes, queremos crear un productor que emita un flujo constante de números.
Vamos a crear nuestro archivo productor:

```shell
$ mkdir lib/genstage_example
$ touch lib/genstage_example/producer.ex
```

Ahora podemos agregamos el código:

```elixir
defmodule GenstageExample.Producer do
  use GenStage

  def start_link(initial \\ 0) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(counter), do: {:producer, counter}

  def handle_demand(demand, state) do
    events = Enum.to_list(state..(state + demand - 1))
    {:noreply, events, state + demand}
  end
end
```

Las dos partes más importantes que debemos notas aquí son `init/1` y `handle_demand/2`.
En `init/1` definimos el estado inicial tal como hemos hecho con nuestros `GenServers` pero mas importante nos nos etiquetamos como un productor.
La respuesta de nuestra función `init/1` es sobre lo que `GenStage` se va a basar para clasificar nuestro proceso.

La función `handle_demand/2` es donde la mayor parte de nuestro productor se definido.
Debe ser implementada por todos los productores `GenStage`.
Aquí retornamos el conjunto de números demandados por nuestros consumidores e incrementamos nuestro contador.
La demanda de los consumidores, `demand` en el código de arriba, es representada como un entero correspondiendo al número de eventos que pueden manejar, por defecto el valor es 1000.

## Productor Consumidor

Ahora que tenemos un productor generando números, vamos a pasar a nuestro productor-consumidor.
Vamos a querer solicitar números de nuestro productor, filtrar los impares y responder a la demanda.

```shell
$ touch lib/genstage_example/producer_consumer.ex
```

Vamos a actualizar nuestro archivo para que se parezca al código de ejemplo:

```elixir
defmodule GenstageExample.ProducerConsumer do
  use GenStage

  require Integer

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [GenstageExample.Producer]}
  end

  def handle_events(events, _from, state) do
    numbers =
      events
      |> Enum.filter(&Integer.is_even/1)

    {:noreply, numbers, state}
  end
end
```

Puede que hayas notado que en nuestro productor-consumidor hemos introducido una nueva opción en `init/1` y una nueva función: `handle_events/3`.
Con la opción `subscribe_to` le decimos a `GenStage` que nos comunique con un productor específico.

La función `handle_events/3` es nuestro caballo de carga, donde recibimos los eventos entrantes, los procesamos y devolvemos un conjunto transformado.
Como veremos, los consumidores están implementados de la misma forma pero la mas importante diferencia es que retorna nuestra función `handle_events/3` y como es usada.
Cuando etiquetamos nuestro proceso como un `producer_consumer` el segundo argumento de nuestra tupla, `numbers` en nuestro caso, es usado para saber la demanda de los consumidores.
En los consumidores este valor es descartado.

## Consumidor

Por último pero no menos importante tenemos nuestro consumidor.
Vamos a empezar:

```shell
$ touch lib/genstage_example/consumer.ex
```

Dado que los consumidores y productores-consumidores son tan similares nuestro código no va a ser muy diferente:

```elixir
defmodule GenstageExample.Consumer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [GenstageExample.ProducerConsumer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect({self(), event, state})
    end

    # As a consumer we never emit events
    {:noreply, [], state}
  end
end
```

Como cubrimos en la sección anterior, nuestro consumidor no emite eventos por lo que el segundo valor de nuestra tupla será descartado.

## Uniendo todas las partes

Ahora que tenemos nuestro productor, productor-consumidor y consumidor construidos estamos listos para unirlos todos juntos.

Vamos a empezar abriendo `lib/genstage_example/application.ex` y agregando nuestros nuevos procesos al árbol de supervisión:

```elixir
def start(_type, _args) do
  import Supervisor.Spec, warn: false

  children = [
    worker(GenstageExample.Producer, [0]),
    worker(GenstageExample.ProducerConsumer, []),
    worker(GenstageExample.Consumer, [])
  ]

  opts = [strategy: :one_for_one, name: GenstageExample.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Si todo está correcto podemos correr nuestro proyecto y deberíamos ver todo funcionando:

```shell
$ mix run --no-halt
{#PID<0.109.0>, 2, :state_doesnt_matter}
{#PID<0.109.0>, 4, :state_doesnt_matter}
{#PID<0.109.0>, 6, :state_doesnt_matter}
...
{#PID<0.109.0>, 229062, :state_doesnt_matter}
{#PID<0.109.0>, 229064, :state_doesnt_matter}
{#PID<0.109.0>, 229066, :state_doesnt_matter}
```

¡Lo hicimos! Como era de esperar nuestra aplicación solo emite número pares y lo hace __rápidamente__.

En este punto ya tenemos un *pipeline* funcionando.
Hay un productor emitiendo números, un productor-consumidor descartando números impares y un consumidor mostrando todo esto y continuando con el flujo.

## Muchos productores y consumidores 

Mencionamos en la introducción que era posible tener mas de un productor o consumidor.
Vamos a ver justo eso.

Si examinamos la salida de `IO.inspect/1` de nuestro ejemplo vemos que cada evento es manejado por un único PID.
Vamos a hacer algunos ajustes para tener múltiples *workers* modificando `lib/genstage_example/application.ex`:

```elixir
children = [
  worker(GenstageExample.Producer, [0]),
  worker(GenstageExample.ProducerConsumer, []),
  worker(GenstageExample.Consumer, [], id: 1),
  worker(GenstageExample.Consumer, [], id: 2)
]
```

Ahora que configuramos dos consumidores vamos a ver que obtenemos si ejecutamos nuestra aplicación:

```shell
$ mix run --no-halt
{#PID<0.120.0>, 2, :state_doesnt_matter}
{#PID<0.121.0>, 4, :state_doesnt_matter}
{#PID<0.120.0>, 6, :state_doesnt_matter}
{#PID<0.120.0>, 8, :state_doesnt_matter}
...
{#PID<0.120.0>, 86478, :state_doesnt_matter}
{#PID<0.121.0>, 87338, :state_doesnt_matter}
{#PID<0.120.0>, 86480, :state_doesnt_matter}
{#PID<0.120.0>, 86482, :state_doesnt_matter}
```

Como puedes ver ahora tenemos múltiples PIDs simplemente agregando una linea de código y dándole a nuestro consumidores un ID.

## Casos de uso

Ahora que hemos cubierto `GenStage` y construimos nuestra primera aplicación de ejemplo, ¿cuales son algunos de casos de uso __reales__ para `GenStage`?

+ *Pipeline* para transformación de datos - Los productores no tienen que ser simples generadores de números.
Podemos producir eventos desde una base de datos o incluso desde otra fuente como Apache's Kafka.
Con una combinación de productor-consumidor y consumidores podríamos procesar, ordenar, catalogar y guardar métricas tan pronto como estén disponibles.

+ Cola de trabajo - Dado que los eventos puedes ser cualquier cosa podríamos producir cargas de trabajo para ser completadas por una serie de consumidores.

+ Procesamiento de eventos - Similar al *pipeline* de datos, podríamos recibir, procesar, ordenar y tomar acción sobre los eventos emitidos en tiempo real desde nuestras fuentes.

Estas son solo __algunas__ de las posibilidades de `GenStage`.
