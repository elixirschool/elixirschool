%{
  version: "1.1.1",
  title: "Supervisores OTP",
  excerpt: """
  Los supervisores son procesos especializados con un propósito: monitorear otros procesos. Estos supervisores nos permiten crear aplicaciones tolerantes a fallos que automáticamente restauren procesos hijos en caso de falla.
  """
}
---

## Configuración

La magia de los supervisores esta en la función `Supervisor.start_link/2`. Adicionalmente a iniciar nuestro supervisor e hijos esto nos permiten definir la estrategia que nuestro supervisor va a usar para administrar los procesos hijos.

Usando `SimpleQueue` de la lección [OTP Concurrency](../../advanced/otp-concurrency), vamos a empezar:

Crea un nuevo proyecto usando `mix new simple_queue --sup` para que se cree usando un árbol de supervisión. El código para el módulo `SimpleQueue` debería ir en `lib/simple_queue.ex` y el código del supervisor sera agregado en `lib/simple_queue/application.ex`.

Los hijos están definidos usando una lista, ya sea una lista con los nombres de los módulos:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      SimpleQueue
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

o una lista de tuplas si quieres agregar opciones de configuración:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleQueue, [1, 2, 3]}
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Si ejecutamos `iex -S mix` veremos que nuestra `SimpleQueue` es automáticamente iniciada:

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

Si nuestro proceso `SimpleQueue` fuera a romperse o ser terminado nuestro supervisor automáticamente los restauraría como si nada hubiera pasado.

### Estrategias

Hay actualmente 3 diferentes estrategias disponibles para los supervisores:

+ `:one_for_one` - Solo restaura el proceso hijo que haya fallado.

+ `:one_for_all` - Restaura todos los procesos hijos en el caso de una falla.

+ `:rest_for_one` - Restaura todos los procesos fallidos y cualquier proceso empezado después de este.

## Especificación de hijo

Después de que el supervisor ha comenzado este debe saber como comenzar/parar/restaurar a sus hijos. Cada módulo hijo debería tener una función `child_spec/1` que defina estos comportamientos. Los macros `use GenServer`, `use Supervisor`, y `use Agent` automáticamente definen este método por nosotros (`SimpleQueue` tiene `use Genserver`, entonces no necesitamos modificar el módulo), pero si necesitas definirlo por ti mismo `child_spec/1` debería retornar un mapa de opciones:

```elixir
def child_spec(opts) do
  %{
    id: SimpleQueue,
    start: {__MODULE__, :start_link, [opts]},
    shutdown: 5_000,
    restart: :permanent,
    type: :worker
  }
end
```

+ `id` - Llave requerida. Usada por el supervisor para identificar la especificación de los hijos.

+ `start` - Llave requerida. El módulo/función/argumentos para llamar cuando sea iniciado por el supervisor.

+ `shutdown` - Llave opcional. Define el comportamiento de los hijos durante el la terminación. Las opciones son:

  + `:brutal_kill` - Hijo es parado inmediatamente.

  + cualquier entero positivo - el tiempo en milisegundos que el supervisor esperará antes de matar a un proceso hijo. Si el proceso es de tipo `:worker` este valor será por defecto 5000.

  + `:infinity` - El supervisor esperará indefinidamente antes de matar al proceso hijo. Por defecto para el tipo `:supervisor`. No recomendado para el tipo `:worker`.

+ `restart` - Llave opcional. Hay muchos enfoques para manejar fallas en los procesos hijos:

  + `:permanent` - El proceso hijo siempre es restaurado. Por defecto para todos los procesos.

  + `:temporary` - El proceso hijo nunca es restaurado.

  + `:transient` - El proceso hijo es restaurado solo si es terminado de una forma anormal.

+ `type` - Llave opcional. Los procesos pueden ser de tipo `:worker` o `:supervisor`, Por defecto es `:worker`.

## DynamicSupervisor

Los supervisores normalmente empiezan con una lista de hijos para iniciar cuando empieza la aplicación. Como sea algunas veces los hijos supervisados no serán conocidos cuando nuestra aplicación empieza (Por ejemplo puede que tengamos una aplicación web que inicia un nuevo proceso para manejar a un usuario conectándose a nuestro sitio). Para esos casos vamos a querer un supervisor donde los hijos pueden ser iniciados a demanda. El supervidor dinámico es usado para manejar este caso.

Como no especificamos los hijos solo necesitamos definir las opciones de ejecución del supervisor. El supervidor dinámico solo soporta la estrategia `:one_for_one`:

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```

Luego para empezar un `SimpleQueue` dinámicamente usaremos `start_child/2` el cual toma un supervisor y la especificación del hijo(Como `SimpleQueue` usa `use GenServer` la especificación ya está definida):

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Supervidor de tareas

Las tareas tienen su propio supervisor especializado, `Task.Supervisor`. Diseñado para crear tareas dinámicamente, el supervisor usa `DynamicSupervisor` por debajo.

### Preparación

Incluir `Task.Supervisor` no es diferente a otros supervisores:

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

La mayor diferencia entre `Supervisor` y `Task.Supervisor` es que este tiene la estrategia por defecto `:temporary` (las tareas nunca serán restauradas).

### Tareas supervisadas

Con el supervisor iniciado podemos usar la función `start_child/2` para crear tareas supervisadas:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Si nuestra tarea falla prematuramente esto la restaurará por nosotros. Este puede ser particularmente útil cuando se trabaja con conexiones entrantes o trabajo procesado en segundo plano.
