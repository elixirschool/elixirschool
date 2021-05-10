%{
  version: "1.0.1",
  title: "Proyectos Umbrella",
  excerpt: """
  Algunas veces un proyecto puede ser grande, demasiado grande incluso.
Mix nos permite separar nuestro código en varias aplicaciones y hacer que nuestros proyectos de Elixir sean más manejables a medida que van creciendo.
  """
}
---

## Introducción

Para crear un proyecto umbrella podemos iniciar un proyecto como cualquier proyecto usando Mix pero usando la opción `--umbrella`.
Para este ejemplo, crearemos *el esqueleto* de una herramienta de machine learning.
¿Por qué una herramienta de machine learning? ¿Por qué no? Contiene varios algoritmos de aprendizaje y funciones útiles.

```shell
$ mix new machine_learning_toolkit --umbrella

* creating .gitignore
* creating README.md
* creating mix.exs
* creating apps
* creating config
* creating config/config.exs

Your umbrella project was created successfully.
Inside your project, you will find an apps/ directory
where you can create and host many apps:

    cd machine_learning_toolkit
    cd apps
    mix new my_app

Commands like "mix compile" and "mix test" when executed
in the umbrella project root will automatically run
for each application in the apps/ directory.
```

Como puedes ver por la salida del comando, Mix creó un pequeño esqueleto con dos carpetas:

  - `apps/` - donde estarán los sub-proyectos o proyectos hijos
  - `config/` - donde estarán las configuraciones de nuestro proyecto umbrella


## Proyectos hijos

Cambiemos a la carpeta `machine_learning_toolkit/apps` y creemos 3 aplicaciones usando Mix de la siguiente manera:

```shell
$ mix new utilities

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/utilities.ex
* creating test
* creating test/test_helper.exs
* creating test/utilities_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd utilities
    mix test

Run "mix help" for more commands.


$ mix new datasets

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/datasets.ex
* creating test
* creating test/test_helper.exs
* creating test/datasets_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd datasets
    mix test

Run "mix help" for more commands.

$ mix new svm

* creating README.md
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/svm.ex
* creating test
* creating test/test_helper.exs
* creating test/svm_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd svm
    mix test

Run "mix help" for more commands.
```

Ahora el proyecto debería tener una estructura como la siguente:

```shell
$ tree
.
├── README.md
├── apps
│   ├── datasets
│   │   ├── README.md
│   │   ├── config
│   │   │   └── config.exs
│   │   ├── lib
│   │   │   └── datasets.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── datasets_test.exs
│   │       └── test_helper.exs
│   ├── svm
│   │   ├── README.md
│   │   ├── config
│   │   │   └── config.exs
│   │   ├── lib
│   │   │   └── svm.ex
│   │   ├── mix.exs
│   │   └── test
│   │       ├── svm_test.exs
│   │       └── test_helper.exs
│   └── utilities
│       ├── README.md
│       ├── config
│       │   └── config.exs
│       ├── lib
│       │   └── utilities.ex
│       ├── mix.exs
│       └── test
│           ├── test_helper.exs
│           └── utilities_test.exs
├── config
│   └── config.exs
└── mix.exs
```

Si regresamos a la raíz de nuestro proyecto umbrella, podremos ver que podemos usar todos los comandos típicos como compile.
Como los sub-proyectos son aplicaciones normales, puedes cambiarte a esas carpetas y hacer todo lo que Mix te permite normalmente.

```bash
$ mix compile

==> svm
Compiled lib/svm.ex
Generated svm app

==> datasets
Compiled lib/datasets.ex
Generated datasets app

==> utilities
Compiled lib/utilities.ex
Generated utilities app

Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
```

## IEx

Podrías pensar que interactuar con las apps es diferente en un proyecto umbrella.
Lo creas o no, ¡estás equivocado! Si cambiamos a la carpeta principal e iniciamos IEx con `iex -S mix` podemos interactuar con todas las aplicaciones normalmente.
Cambiemos el contenido de `apps/datasets/lib/datasets.ex` para este ejemplo simple..

```elixir
defmodule Datasets do
  def hello do
    IO.puts("Hello, I'm the datasets")
  end
end
```

```shell
$ iex -S mix
Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

==> datasets
Compiled lib/datasets.ex
Consolidated List.Chars
Consolidated Collectable
Consolidated String.Chars
Consolidated Enumerable
Consolidated IEx.Info
Consolidated Inspect
Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)

iex> Datasets.hello
:world
```
