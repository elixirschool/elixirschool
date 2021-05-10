%{
  version: "1.0.1",
  title: "Distribución en OTP",
  excerpt: """
  ## Introducción a la distribución

Podemos ejecutar aplicaciones Elixir en un conjunto de nodos distribuidos diferentes ya sea en un único *host* o en múltiples *hosts*.
Elixir nos permite comunicarnos a través de estos nodos usando algunos mecanismos los cuales están fuera del objetivo de esta lección.
  """
}
---

## Comunicación entre nodos

Elixir corre sobre la máquina virtual de Erlang, esto significa que puede acceder a la poderosa [funcionalidad de distribución](http://erlang.org/doc/reference_manual/distributed.html) de Erlang.

> Un sistema distribuido en Erlang consiste de un número de sistemas Erlang comunicándose entre sí.
Cada sistema es llamado un nodo.

Un nodo es cualquier sistema de Erlang al que se le ha dado un nombre.
Podemos iniciar un nodo abriendo una sesión de `iex` y dándole un nombre:

```bash
iex --sname alex@localhost
iex(alex@localhost)>
```

Vamos a abrir otro nodo en otra terminal:

```bash
iex --sname kate@localhost
iex(kate@localhost)>
```

Estos dos nodos pueden enviarse mensajes entre sí usando `Node.spawn_link/2`.

### Comunicación con Node.spawn_link/2

Esta función toma dos argumentos:
* El nombre del nodo al cual te quieres conectar.
* La función a ser ejecutada por el proceso remoto corriendo en ese nodo.

Esto establece una conexión al nodo remoto y ejecuta la función dada en ese nodo, retornando el PID del proceso enlazado.

Vamos a definir un módulo `Kate`, en el nodo `kate` que sabe como presentar a Kate, la persona:

```elixir
iex(kate@localhost)> defmodule Kate do
...(kate@localhost)>   def say_name do
...(kate@localhost)>     IO.puts "Hi, my name is Kate"
...(kate@localhost)>   end
...(kate@localhost)> end
```

#### Enviando mensajes

Ahora podemos usar [`Node.spawn_link/2`](https://hexdocs.pm/elixir/Node.html#spawn_link/2) para hacer que el nodo `alex` le diga el nodo `kate` que ejecute la función `say_name/0`:

```elixir
iex(alex@localhost)> Node.spawn_link(:kate@localhost, fn -> Kate.say_name end)
Hi, my name is Kate
#PID<10507.132.0>
```

#### Una nota sobre I/O y nodos

Hay que darse cuenta que aunque `Kate.say_name/0` está siendo ejecutado en el nodo remoto, es el nodo local el que recibe la salida de `IO.puts`.
Eso es porque el nodo local es el **grupo líder**.
La máquina virtual de Erlang maneja I/O mediante procesos.
Esto nos permite ejecutar tareas de I/O como `IO.puts` a través de nodos distribuidos.
Estos procesos distribuidos son administrados por el líder de grupo de los procesos de I/O.
El grupo líder es siempre el nodo que genera el proceso.
Entonces dado que nuestro nodo `alex` es desde el que se llamó a `spawn_link/2`, ese nodo es el líder de grupo y la salida de `IO.puts` será dirigida a la salida estándar de ese nodo.

#### Respondiendo a mensajes

¿Qué tal si queremos que el nodo que reciba el mensaje envía una *respuesta* al que hizo el envío? Podemos usar las funciones `receive/1` y [`send/3`](https://hexdocs.pm/elixir/Process.html#send/3) para lograr esto.

Vamos a tener a nuestro nodo `alex` que genera un enlace con el nodo `kate` y le da una función anónima para ser ejecutada.
Esa función anónima va a esperar recibir una tupla específica la cual contiene un mensaje y el PID del nodo `alex`.
Responderá a ese mensaje enviándole otro mensaje al PID del nodo `alex`:

```elixir
iex(alex@localhost)> pid = Node.spawn_link :kate@localhost, fn ->
...(alex@localhost)>   receive do
...(alex@localhost)>     {:hi, alex_node_pid} -> send alex_node_pid, :sup?
...(alex@localhost)>   end
...(alex@localhost)> end
#PID<10467.112.0>
iex(alex@localhost)> pid
#PID<10467.112.0>
iex(alex@localhost)> send(pid, {:hi, self()})
{:hi, #PID<0.106.0>}
iex(alex@localhost)> flush()
:sup?
:ok
```

#### Una nota sobre la comunicación entre nodos de diferentes redes

Si quieres enviar mensajes entre nodos de diferentes redes necesitas empezar los nodos con una *cookie* compartida:

```bash
iex --sname alex@localhost --cookie secret_token
```

```bash
iex --sname kate@localhost --cookie secret_token
```

Solo los nodos que hayan sido iniciados con la misma `cookie` serán capaces de conectarse satisfactoriamente entre sí.

#### Limitaciones de Node.spawn_link/2

Mientras que `Node.spawn_link/2` ilustra la relación entre nodos y la manera como podemos enviar mensajes entre ellos, esta _no_ es realmente la decisión correcta para una aplicación que correrá entre nodos distribuidos.
`Node.spawn_link/2` genera procesos aislados, es decir procesos que no están supervisados.
Si solo hubiera una forma de generar procesos supervisados, asíncronos a _través de los nodos_...

## Tareas distribuidas

Las [tareas distribuidas](https://hexdocs.pm/elixir/master/Task.html#module-distributed-tasks) nos permite generar tareas supervisadas a través de nodos.
Construiremos una aplicación simple con un supervisor que aprovecha las tareas distribuidas para permitir a los usuarios *chatear* entre sí usando una sesión `iex` a través de nodos distribuidos.

### Definiendo una aplicación supervisada

Genera tu aplicación:

```
mix new chat --sup
```

### Agregando un supervisor de tareas al árbol de supervisión

Un supervisor de tareas supervisa dinámicamente tareas.
Este empieza sin hijos, frecuentemente _bajo_ otro supervisor, y puede ser usado luego para supervisar cualquier número de tareas.

Vamos a agregar un supervisor de tareas al árbol de supervisión de nuestra aplicación y llamarlo `Chat.TaskSupervisor`

```elixir
# lib/chat/application.ex
defmodule Chat.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Chat.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Ahora que sabemos que donde sea que nuestra aplicación sea iniciada en un nodo, `Chat.Supervisor` estará corriendo y listo para supervisar tareas.

### Enviando mensajes con tareas supervisadas

Empezaremos tareas supervisadas con la función [`Task.Supervisor.async/5`](https://hexdocs.pm/elixir/master/Task.Supervisor.html#async/5).

Esta función debe tomar cuatro parámetros:

* El supervisor que queremos usar para supervisar la tarea.
Este puede ser pasado como una tupla `{SupervisorName, remote_node_name}` para supervisar la tarea en un nodo remoto.
* El nombre del módulo del cual queremos ejecutar una función.
* El nombre de la función que queremos ejecutar.
* Los argumentos que sean necesarios proveer para ejecutar esa función.

Puedes pasar un quinto elemento, un argumento opcional que describe las opciones de apagado.
No nos preocuparemos acerca de eso aquí.

Nuestra aplicación de chat es bastante simple.
Envía mensajes a nodos remotos y los nodos remotos responder a estos mensajes usando `IO.puts` para enviar la respuesta a STDOUT del nodo remoto.

Primero vamos a definir una función `Chat.receive_message/1` la cual queremos que nuestra tarea ejecute en un nodo remoto.

```elixir
# lib/chat.ex
defmodule Chat do
  def receive_message(message) do
    IO.puts message
  end
end
```

Ahora vamos a enseñarle al módulo `Chat` como enviar el mensaje a un nodo remoto usando una tarea supervisada.
Definiremos una función `Chat.send_message/2` que hará este proceso:

```elixir
# lib/chat.ex
defmodule Chat do
  ...

  def send_message(recipient, message) do
    spawn_task(__MODULE__, :receive_message, recipient, [message])
  end

  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  defp remote_supervisor(recipient) do
    {Chat.TaskSupervisor, recipient}
  end
end
```

Vamos a verlo en acción.

En una terminal inicia nuestra aplicación de chat en una sesión `iex` con nombre.

```bash
iex --sname alex@localhost -S mix
```

Abre otra terminal y empieza la aplicación con un nombre de nodo diferente:

```bash
iex --sname kate@localhost -S mix
```

Ahora desde el nodo `alex` podemos enviar un mensaje al nodo `kate`:

```elixir
iex(alex@localhost)> Chat.send_message(:kate@localhost, "hi")
:ok
```

Cambia a la ventana del nodo `kate` y deberías ver el mensaje:

```elixir
iex(kate@localhost)> hi
```

El nodo `kate` puede responder al nodo `alex`:

```elixir
iex(kate@localhost)> hi
Chat.send_message(:alex@localhost, "how are you?")
:ok
iex(kate@localhost)>
```

Y esto se mostrará en la sesión `iex` del nodo `alex`:

```elixir
iex(alex@localhost)> how are you?
```

Vamos a volver a visitar nuestro código ver que es lo que está pasando aquí.

Tenemos una función `Chat.send_message/2` que toma el nombre del nodo remoto en el cual queremos ejecutar nuestra tarea supervisada y el mensaje que queremos enviar a ese nodo.

Esa función llama a nuestra función `spawn_task/4` la cual empieza una tarea asíncrona en el nodo remoto con el nombre dado, supervisada por `Chat.TaskSupervisor` en ese nodo remoto.
Sabemos que el supervisor de tareas con el nombre `Chat.TaskSupervisor` está corriendo en ese nodo porque ese nodo _también_ está corriendo una instancia de nuestra aplicación de chat y `Chat.TaskSupervisor` ha iniciado como parte del árbol de supervisión de nuestra aplicación.

Le estamos diciendo a `Chat.TaskSupervisor` que supervise una tarea que ejecuta la función `Chat.receive_message` con un argumento de cualquier mensaje que se haya pasado a `spawn_task/4` desde `send_message/2`.

Por lo que `Chat.receive_message("hi")` es llamado en el nodo remoto `kate` causando que el mensaje `"hi"` sea pasado al flujo STDOUT de ese nodo.

En este caso dado que la tarea esta siendo supervisada en el nodo remoto, ese nodo es el líder de grupo para este proceso de I/O.

### Respondiendo a los mensajes desde los nodos remotos

Vamos a hacer que nuestra aplicación de chat sea un poco mas inteligente.
Hasta aquí cualquier número de usuarios puede ejecutar la aplicación en una sesión `iex` y comenzar a *chatear*.
Pero vamos a decir que hay un perro blanco de tamaño medio llamado Moebi quien no quiere quedarse fuera.
Moebi quiere ser incluido en la aplicación de chat pero tristemente el no sabe como escribir porque es un perro.
Por lo que vamos a enseñarle a nuestro módulo `Chat` a responder a cualquier mensaje enviado al nodo llamado `moebi@localhost` en lugar de Moebi.
No importa que le digas a Moebi, el siempre responderá con `"chicken?"` porque su único deseo real es comer pollo.

Vamos a definir otra versión de nuestra función `send_message/2` que haga *pattern matching* con el argumento `recipient`.
Si el destinatario es `:moebi@localhost` vamos a:

* Tomar el nombre del nodo actual usando `Node.self()`
* Dar el nombre del nodo actual, es decir el destinatario, a una nueva función `receive_message_for_moebi/2`, de modo que podemos enviar un mensaje de _regreso_ a ese nodo.

```elixir
# lib/chat.ex
...
def send_message(:moebi@localhost, message) do
  spawn_task(__MODULE__, :receive_message_for_moebi, :moebi@localhost, [message, Node.self()])
end
```

Ahora definiremos una función `receive_message_for_moebi/2` que imprima, con `IO.puts`, el mensaje en el flujo STDOUT del nodo de `moebi` _y_ envíe un mensaje de regreso al emisor.

```elixir
# lib/chat.ex
...
def receive_message_for_moebi(message, from) do
  IO.puts message
  send_message(from, "chicken?")
end
```

Llamando a `send_message/2` con el nombre del nodo que envió el mensaje original (el nodo emisor) le estamos diciendo al nodo _remoto_ que genere una tarea supervisada en el nodo emisor.

Vamos a verlo en acción.
En tres diferentes terminales, abre tres diferentes nodos:

```bash
iex --sname alex@localhost -S mix
```

```bash
iex --sname kate@localhost -S mix
```

```bash
iex --sname moebi@localhost -S mix
```

Vamos a hacer que `alex` envié un mensaje a `moebi`:

```elixir
iex(alex@localhost)> Chat.send_message(:moebi@localhost, "hi")
chicken?
:ok
```

Podemos ver que el nodo `alex` recibe el mensaje `"chicken?"`.
Si abrimos el nodo `kate` veremos que no se ha recibido ningún mensaje dado que ni `alex` o `moebi` le enviaron uno (disculpa `kate`).
Si abrimos la terminal del nodo `moebi` veremos el mensaje que el nodo `alex` envió.

```elixir
iex(moebi@localhost)> hi
```

## Probando código distribuido

Vamos a empezar a escribir una prueba simple para nuestra función `send_message`.

```elixir
# test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

Si ejecutamos nuestras pruebas usando `mix test` veremos que fallan con el siguiente error:

```elixir
** (exit) exited in: GenServer.call({Chat.TaskSupervisor, :moebi@localhost}, {:start_task, [#PID<0.158.0>, :monitor, {:sophie@localhost, #PID<0.158.0>}, {Chat, :receive_message_for_moebi, ["hi", :sophie@localhost]}], :temporary, nil}, :infinity)
         ** (EXIT) no connection to moebi@localhost
```

Este error tiene mucho sentido, no podemos conectarnos a un nodo llamado `moebi@localhost` porque no existe tal nodo corriendo.

Podemos hacer que esta prueba pase ejecutando algunos pasos:

* Abre otra terminal y ejecuta el siguiente comando: `iex --sname moebi@localhost -S mix`.
* Ejecuta las pruebas en la primera terminal usando el nodo que ejecuta las pruebas en una sesión de `iex`: `iex --sname sophie@localhost -S mix test`.

Esto es demasiado trabajo y definitivamente nos sería considerado un proceso de pruebas automatizado.

Hay dos enfoques diferentes que podríamos usar aquí:

1.
Condicionalmente excluir las pruebas que necesitan nodos distribuidos si el nodo necesario no está corriendo.

2.
Configurar nuestra aplicación para evitar generar tareas en nodos remotos en el entorno de pruebas.

Vamos a revisar el primer enfoque.

### Excluir pruebas condicionalmente usando etiquetas

Agregaremos una etiqueta `ExUnit` a esta prueba:

```elixir
#test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  @tag :distributed
  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

Y agregaremos lógica condicional a nuestro *helper* de pruebas para excluir pruebas con tales etiquetas si las pruebas no están corriendo en un nodo con nombre.

```elixir
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
```

Vamos a revisar si el nodo está vivo, es decir
si el nodo es parte de un sistema distribuido con  [`Node.alive?`](https://hexdocs.pm/elixir/Node.html#alive?/0).
Si no, podemos llamar a `ExUnit` para omitir cualquier prueba con la etiqueta `distributed: true`.
De otra manera le diremos que no excluya las pruebas.

Ahora si ejecutamos `mix test` veremos:

```bash
mix test
Excluding tags: [distributed: true]

Finished in 0.02 seconds
1 test, 0 failures, 1 excluded
```

Si queremos ejecutar pruebas distribuidas, simplemente necesitamos hacer los pasos relatados en la sección previa: ejecutar el nodo `moebi@localhost` _y_ ejecutar las pruebas en un nodo nombrado usando `iex`.

Vamos a revisar el otro enfoque configurando la aplicación para comportarse diferente en entornos diferentes.

### Configuración específica por entorno

La parte de nuestro código que dice `Task.Supervisor` para empezar una tarea supervisada en un nodo remoto está aquí:

```elixir
# app/chat.ex
def spawn_task(module, fun, recipient, args) do
  recipient
  |> remote_supervisor()
  |> Task.Supervisor.async(module, fun, args)
  |> Task.await()
end

defp remote_supervisor(recipient) do
  {Chat.TaskSupervisor, recipient}
end
```

`Task.Supervisor.async/5` toma en un primer argumento el supervisor que queremos usar.
Si pasamos una tupla de `{SupervisorName, location}`, empezará el supervisor especificado en el nodo especificado.
Sin embargo si pasamos `Task.Supervisor` como primer argumento de nuestro nombre de supervisor iniciará ese supervisor para supervisar tareas localmente.

Vamos a hacer la función `remote_supervisor/1` configurable basada en el entorno.
En el entorno de desarrollo retornará `{Chat.TaskSupervisor, recipient}` y en el entorno de pruebas retornará `Chat.TaskSupervisor`.

Haremos esto mediante variables de aplicación.

Crea un archivo `config/dev.exs` y agrega:

```elixir
# config/dev.exs
use Mix.Config
config :chat, remote_supervisor: fn(recipient) -> {Chat.TaskSupervisor, recipient} end
```

Crea un archivo `config/test.exs` y agrega:

```elixir
# config/test.exs
use Mix.Config
config :chat, remote_supervisor: fn(_recipient) -> Chat.TaskSupervisor end
```

Recuerda descomentar esta linea en `config/config.exs`:

```elixir
import_config "#{Mix.env()}.exs"
```

Por último actualizaremos nuestra función `Chat.remote_supervisor/1` para usar la función guardada en nuestra nueva variable de aplicación:

```elixir
# lib/chat.ex
defp remote_supervisor(recipient) do
  Application.get_env(:chat, :remote_supervisor).(recipient)
end
```

## Conclusión

Las capacidades distribuidas de Elixir, las cuales son gracias al poder de la máquina virtual de Erlang, es una de las características que lo hacen una herramienta poderosa.
Podemos imaginar aprovechar la habilidad de Elixir para manejar cómputo distribuido para correr trabajos en segundo plano concurrentes, para soportar aplicaciones de gran rendimiento, para ejecutar operaciones costosas, o lo que se te pueda ocurrir.

Esta lección nos da una introducción básica del concepto de distribución en Elixir y te da las herramientas que necesitas para empezar a construir aplicaciones distribuidas.
Usando tareas supervisadas puedes enviar mensajes a través de varios nodos de una aplicación distribuida.
