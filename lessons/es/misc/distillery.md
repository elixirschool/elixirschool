%{
  version: "2.0.1",
  title: "Distillery (Básico)",
  excerpt: """
  Distillery es un manejador de releases escrito en Elixir. Permite generar releases que pueden ser desplegados en cualquier lugar con poca o nula configuración.
  """
}
---

## ¿Qué es un release?

Un release es un paquete que contiene tu código de Erlang/Elixir ya compilado (es decir [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) [bytecode](https://en.wikipedia.org/wiki/Bytecode)). También provee cualquier script necesario para ejecutar tu aplicación.

> Cuando has escrito una o varias aplicaciones, es posible que quieras crear un sistema completo con esas aplicaciones y con un sub-conjunto de las aplicaciones de Erlang/OTP. A eso se le llama un release. - [Erlang documentation](http://erlang.org/doc/design_principles/release_structure.html)

> Los releases permiten un despliegue simplificado: son auto-contenidos y proveen todo lo necesario para iniciar el release. Son fácilmente administrables mediante los scripts que provee que pueden abrir una consola remota, iniciar/detener/reiniciar el release, iniciar en background, envíar comandos remotamente y mucho más. Además son artefactos archivables, lo que significa que puedes restaurar un release anterior desde un tarball en cualquier momento en el futuro (a menos que existan incompatibilidades con el sistema operativo o librerías del sistema). Utilizar releases es también un prerrequisito para poder realizar actualizaciones en caliente, una de las caracteristicas más poderosas de la VM de Erlang. - [Distillery Documentation](https://hexdocs.pm/distillery/introduction/understanding_releases.html)

Un release contiene lo siguiente:
* Una carpeta /bin
  * Contiene un script que será el punto de inicio para ejecutar la aplicación completa.
* Una carpeta /lib
  * Contiene el bytecode compilado de la aplicación incluyendo sus dependencias.
* Una carpeta /releases
  * Contiene metadata acerca del release además de hooks o comandos personalizados.
* Un /erts-VERSION
  * Contiene el runtime de Erlang el cual permite a la máquina ejecutar tu aplicación sin tener Erlang o Elixir instalado.


### Comenzando/Instalación

Para agregar Distillery a tu proyecto, agrégalo como dependencia en tu archivo `mix.exs`. *Nota* - si estás trabajando en un proyecto umbrella debes agregarlo en el archivo mix.exs en la carpeta raíz de tu proyecto

```
defp deps do
  [{:distillery, "~> 2.0"}]
end
```

Luego en la terminal ejecuta:

```
mix deps.get
```

```
mix compile
```


### Construye el release

En la terminal, ejecuta:

```
mix release.init
```

Este comando genera una carpeta `rel` que contiene algunos archivos de configuración.

Para generar un release ejecuta en la terminal `mix distillery.release`

Cuando se haya construido el release debes ver algunas instrucciones en la terminal

```
==> Assembling release..
==> Building release book_app:0.1.0 using environment dev
==> You have set dev_mode to true, skipping archival phase
Release successfully built!
To start the release you have built, you can use one of the following tasks:

    # start a shell, like 'iex -S mix'
    > _build/dev/rel/book_app/bin/book_app console

    # start in the foreground, like 'mix run --no-halt'
    > _build/dev/rel/book_app/bin/book_app foreground

    # start in the background, must be stopped with the 'stop' command
    > _build/dev/rel/book_app/bin/book_app start

If you started a release elsewhere, and wish to connect to it:

    # connects a local shell to the running node
    > _build/dev/rel/book_app/bin/book_app remote_console

    # connects directly to the running node's console
    > _build/dev/rel/book_app/bin/book_app attach

For a complete listing of commands and their use:

    > _build/dev/rel/book_app/bin/book_app help
```

Para iniciar tu aplicación escribe lo siguiente en tu terminal ` _build/dev/rel/MYAPP/bin/MYAPP foreground`
Reemplaza MYAPP con el nombre de tu proyecto. ¡Ahora estamos ejecutando el release construido de nuestra aplicación!


## Utilizando Distillery con Phoenix

Si quieres utilizar Distillery con Phoenix existen algunos pasos extra que debes seguir antes que pueda funcionar.

Primero, debemos editar nuestro archivo `config/prod.exs`.

Cambia las siguientes líneas de código de esto:

```
config :book_app, BookAppWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
```
A esto:

```
config :book_app, BookApp.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:book_app, :vsn)
```

Hemos hecho algunas cosas aquí:
- `server` - inicia la aplicación de endpoints http de Cowboy al iniciar la aplicación
- `root` - define la carpeta raíz de la aplicación que es de donde los archivos estáticos serán servidos
- `version` - elimina el cache de la aplicación cuando se actualice en caliente la version de la aplicación.
- `port` - cambiar el puerto para que sea definido por una variable de ambiente nos permite enviar el número del puerto cuando iniciemos la aplicación. Al iniciar la aplicación podemos pasar el puerto ejecutando `PORT=4001 _build/prod/rel/book_app/bin/book_app foreground`

Si ejecutaste el comando anterior, pudiste haber notado que tu aplicación falló porque no puede conectarse a la base de datos ya que ninguna existe actualmente. Esto puede rectificarse ejecutando un comando `mix` de Ecto. En la terminal, ejecuta lo siguiente:

```
MIX_ENV=prod mix ecto.create
```

Este comando creará la base de datos por ti. Intenta volver a ejecutar tu aplicación y debería iniciar de manera correcta. Sin embargo, puedes notar que las migraciones de la base de datos no se han ejecutado. Por lo general en modo de desarrollo ejecutamos esas migraciones manualmente usando `mix.ecto migrate`. Para el release, tendremos que configurar para que las migraciones se ejecuten automáticamente.

## Ejecutando migraciones en Producción

Distillery nos permite ejecutar código en diferentes puntos del ciclo de vida del release. Estos puntos se conocen como [boot-hooks](https://hexdocs.pm/distillery/1.5.2/boot-hooks.html). Entre los hooks que provee Distillery están:

* pre_start
* post_start
* pre/post_configure
* pre/post_stop
* pre/post_upgrade


Para nuestros propósitos utilizaremos el hook `post_start` para ejecutar nuestras migraciones en producción.
Primero creemos una nueva tarea de release llamada `migrate`. Una tarea es una función en un módulo que podemos llamar desde la terminal que contiene código que esta separado de la funcionalidad interna de nuestra aplicación. Es útil para las tareas que la aplicación misma típicamente no se ejecute.

```
defmodule BookAppWeb.ReleaseTasks do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:book_app)

    path = Application.app_dir(:book_app, "priv/repo/migrations")

    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)
  end
end
```

*Nota* Es buena práctica asegurarse que todas las aplicaciones hayan iniciado correctamente antes de ejecutar las migraciones. [Ecto.Migrator](https://hexdocs.pm/ecto/2.2.8/Ecto.Migrator.html) permite ejecutar nuestras migraciones con la conexión a la base de datos.

Luego, crea un nuevo archivo - `rel/hooks/post_start/migrate.sh` y agrega el siguiente código:

```
echo "Running migrations"

bin/book_app rpc "Elixir.BookApp.ReleaseTasks.migrate"

```

Para que ese código se ejecute de manera correcta, utilizaremos el módulo `rpc` de Erlang que nos permite hacer llamadas a procedimientos remotamente. Básicamente, podemos llamar a una función en un nodo remotamente y obtener su respuesta. Cuando estamos en producción es muy probable que nuestra aplicación esté en varios nodos.

Finalmente, en nuestro archivo `rel/config.exs` agregaremos el hook a nuestra configuración para producción.

Cambiemos esto

```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
end
```

con esto

```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
  set post_start_hooks: "rel/hooks/post_start"
end
```

*Nota* - Este hook solamente existe en el release de producción de esta aplicación. Si utilizamos el release de desarrollo que es el por defecto, el hook no se ejecutará.

## Comandos personalizados

Cuando trabajamos con un release, puede ser que no tengas acceso a comandos de `mix` ya que `mix` talvez no este instalado en la máquina donde esta desplegado el release. Podemos resolver este problema creando comandos personalizados.

> Los comandos personalizados son extensiones al script de inicio y son usados de la misma manera que utilizamos foreground o remote_console, en otras palabras, tienen la apariencia de ser parte del script de inicio. Así como los hooks, estos comandos tienen acceso a las funcionex auxiliares y al ambiente - [Distillery Docs](https://hexdocs.pm/distillery/1.5.2/custom-commands.html)

Estos comandos son similares a las tareas de release en cuanto a que ambas son funciones pero son diferentes de ellas porque son ejecutados usando la terminal en lugar del release script.

Ahora que podemos ejecutar nuestras migraciones, podríamos necesitar llenar nuestra base de datos con información inicial a través de un comando. Primero, agrega un nuevo método a nuestra tarea de release. En `BookAppWeb.ReleaseTasks`, agrega lo siguiente:

```
def seed do
  seed_path = Application.app_dir(:book_app_web, "priv/repo/seeds.exs")
  Code.eval_file(seed_path)
end
```

Luego, crea un nuevo archivo `rel/commands/seed.sh` y agrega el siguiente código:

```
#!/bin/sh

release_ctl eval "BookAppWeb.ReleaseTasks.seed/0"
```

*Nota* - `release_ctl()` es un script de terminal que Distillery provee que nos permite ejecutar comandos localmente o en un nodo limpio. Si necesitas ejecutar esto en un nodo corriendo puedes correr `release_remote_ctl()`

Puedes ver más sobre los shell_scripts de Distillery [aquí](https://hexdocs.pm/distillery/extensibility/shell_scripts.html)

Finalmente, agrega lo siguiente a tu archivo `rel/config.exs`
```
release :book_app do
  ...
  set commands: [
    seed: "rel/commands/seed.sh"
  ]
end

```

Asegurate de recrear el release ejecutando `MIX_ENV=prod mix release`. Cuando termine, puede ejecutar en tu terminal `PORT=4001 _build/prod/rel/book_app/bin/book_app seed`.
