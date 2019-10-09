---
version: 2.0.1
title: Distillery (Basics)
---

Distillery es un manejador de releases escrito en Elixir. Permite generar releases que pueden ser desplegadas en cualquier lugar con poca o nula configuración.

## ¿Qué es un release?

Un release es un paquete que contiene tu código de Erlang/Elixir ya compilado (es decir [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) [bytecode](https://en.wikipedia.org/wiki/Bytecode)). También provee cualquier script necesario para ejecutar tu aplicación.

> Cuando has escrito una o varias aplicaciones, es posible que quieras crear un sistema completo con esas aplicaciones y con un sub-conjunto de las aplicaciones de Erlang/OTP. A eso se le llama un release. - [Erlang documentation](http://erlang.org/doc/design_principles/release_structure.html)

> Los releases permiten un despliegue simplificado: son auto-contenidos y proveen todo lo necesario para iniciar el release. Son fácilmente administrables mediante los scripts que provee que pueden abrir una consola remota, inician/detienen/reinician el release, inician en background, envían comandos remotamente y mucho más. Además son artefactos archivables, lo que significa que puedes restaurar un release anterior desde un tarball en cualquier momento en el futuro (a menos que existan incompatibilidades con el sistema operativo o librerías del sistema). Utilizar releases es también un prerrequisito para poder realizar actualizaciones en caliente, una de las caracteristicas más poderosas de la VM de Erlang. - [Distillery Documentation](https://hexdocs.pm/distillery/introduction/understanding_releases.html)

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

Para agregar Distillery a tu proyecto, agrégalo como dependencia en tu archivo `mix.exs`. *Nota* - si estás trabajando en un umbrella app debes agregarlo en el archivo mix.exs en la carpeta raíz de tu proyecto

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

Para generar un release ejecuta en la terminal `mix release`

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

Este comendo creará la base de datos por ti. Intenta volver a ejecutar tu aplicación y debería iniciar de manera correcta. Sin embargo, puedes notar que las migraciones de la base de datos no se han ejecutado. Por lo general en modo de desarrollo ejecutamos esas migraciones manualmente usando `mix.ecto migrate`. Para el release, tendremos que configurar para que las migraciones se ejecuten automáticamente.

## Ejecutando migraciones en Producción

Distillery nos permite ejecutar código en diferentes puntos del ciclo de vida del release. Estos puntos se conocen como [boot-hooks](https://hexdocs.pm/distillery/1.5.2/boot-hooks.html). Entre los hooks que provee Distillery están:

* pre_start
* post_start
* pre/post_configure
* pre/post_stop
* pre/post_upgrade


Para nuestros propósitos utilizaremos el hook `post_start` para ejecutar nuestras migraciones en producción.
Primero creemos una nueva tarea de release llamada `migrate`. Una tarea es una función en un módulo que podemos llamar desde la terminal que contiene código que esta separado de la funcionalidad interna de nuestra aplicación. Es útil para las tareas que la aplicación misma típicamente no debería ejecutarse.

```
defmodule BookAppWeb.ReleaseTasks do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:book_app)

    path = Application.app_dir(:book_app, "priv/repo/migrations")

    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)
  end
end
```

*Note* It is good practice to ensure that your applications have all started up properly before running these migrations. The [Ecto.Migrator](https://hexdocs.pm/ecto/2.2.8/Ecto.Migrator.html) allows us to run our migrations with the connected database.

Next, create a new file - `rel/hooks/post_start/migrate.sh` and add the following code:


```
echo "Running migrations"

bin/book_app rpc "Elixir.BookApp.ReleaseTasks.migrate"

```

In order for this code to run properly, we are using Erlang's `rpc` module which allows us Remote Produce Call service. Basically, this allows us to call a function on a remote node and get the answer. When running in production it is likely that our application will be running in several different nodes

Finally, in our `rel/config.exs` file we're going to add the hook to our prod configuration.

Let's replace

```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
end
```

with

```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
  set post_start_hooks: "rel/hooks/post_start"
end
```

*Note* - This hook only exists in the production release of this application. If we used the default development release it would not run.

## Custom Commands

When working with a release, you may not have access to `mix` commands as `mix` may not be installed to the machine the release is deployed to. We can solve this by creating custom commands.

> Custom commands are extensions to the boot script, and are used in the same way you use foreground or remote_console, in other words, they have the appearance of being part of the boot script. Like hooks, they have access to the boot scripts helper functions and environment - [Distillery Docs](https://hexdocs.pm/distillery/1.5.2/custom-commands.html)

Commands are similar to release tasks in that they are both method functions but are different from them in that they are executed through the terminal as opposed to being run by the release script.

Now that we can run our migrations, we may want to be able to seed our database with information through running a command. First, add a new method to our release tasks. In `BookAppWeb.ReleaseTasks`, add the following:

```
def seed do
  seed_path = Application.app_dir(:book_app_web, "priv/repo/seeds.exs")
  Code.eval_file(seed_path)
end
```

Next, create a new file `rel/commands/seed.sh` and add the following code:

```
#!/bin/sh

release_ctl eval "BookAppWeb.ReleaseTasks.seed/0"
```


*Note* - `release_ctl()` is a shell script provided by Distillery that allows us to execute commands locally or in a clean node. If you need to run this against a running node you can run `release_remote_ctl()`

See more about shell_scripts from Distillery [here](https://hexdocs.pm/distillery/extensibility/shell_scripts.html)

Finally, add the following to your `rel/config.exs` file
```
release :book_app do
  ...
  set commands: [
    seed: "rel/commands/seed.sh"
  ]
end

```

Be sure, to recreate the release by running `MIX_ENV=prod mix release`. Once this is complete, you can now run in your terminal `PORT=4001 _build/prod/rel/book_app/bin/book_app seed`.
