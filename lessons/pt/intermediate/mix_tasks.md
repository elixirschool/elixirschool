---
version: 1.2.0
title: Tarefas Mix Customizadas
---

Criando tarefas Mix customizadas para seus projetos Elixir.

{% include toc.html %}

## Introdução

É comum querer estender as funcionalidades da sua aplicação Elixir adicionando tarefas Mix customizadas.
Antes de aprendermos como criar tarefas Mix específicas para nossos projetos, vamos dar uma olhada em uma já existente:

```shell
$ mix phx.new my_phoenix_app

* creating my_phoenix_app/config/config.exs
* creating my_phoenix_app/config/dev.exs
* creating my_phoenix_app/config/prod.exs
* creating my_phoenix_app/config/prod.secret.exs
* creating my_phoenix_app/config/test.exs
* creating my_phoenix_app/lib/my_phoenix_app.ex
* creating my_phoenix_app/lib/my_phoenix_app/endpoint.ex
* creating my_phoenix_app/test/views/error_view_test.exs
...
```

Como podemos ver no comando shell acima, o Framework Phoenix tem uma tarefa Mix customizada para criar um novo projeto.
E se quiséssemos criar algo parecido para o nosso projeto? Bem, a boa notícia é que nós podemos, e Elixir nos permite fazer isso de um modo fácil.

## Configurações

Vamos configurar uma aplicação Mix básica.

```shell
$ mix new hello

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/hello.ex
* creating test
* creating test/test_helper.exs
* creating test/hello_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

cd hello
mix test

Run "mix help" for more commands.
```

Agora, no arquivo **lib/hello.ex** que o Mix criou para nós, vamos criar uma função simples que irá imprimir "Hello, World!"

```elixir
defmodule Hello do
  @doc """
  Outputs `Hello, World!` every time.
  """
  def say do
    IO.puts("Hello, World!")
  end
end
```

## Tarefa Mix Customizada

Vamos criar nossa tarefa Mix customizada.
Crie um novo diretório e um arquivo **hello/lib/mix/tasks/hello.ex**.
Neste arquivo, vamos inserir estas 7 linhas de Elixir.

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply calls the Hello.say/0 function."
  def run(_) do
    # Chamando a função Hello.say() definida anteriormente
    Hello.say()
  end
end
```

Note que agora nós começamos o código do defmodule com `Mix.Tasks` e o nome que queremos usar para o nosso comando.
Na segunda linha, colocamos `use Mix.Task`, que traz o comportamento `Mix.Task` para o namespace.
Então, declaramos uma função `run` que ignora quaisquer argumentos por agora.
Dentro dessa função, chamamos nosso módulo `Hello` e a função `say`.

## Inicializando sua aplicação

O Mix não inicializa automaticamente nossa aplicação ou qualquer uma de suas dependências.
Não há problema nisto para muitos dos casos de uso de tarefas Mix. Mas e se precisássemos criar uma tarefa que
usa o Ecto e interage com o banco de dados?

Neste caso, precisaríamos ter certeza de que a aplicação por trás do Ecto.Repo foi inicializada.
Existem 2 maneiras de lidar com isso: explicitamente inicializando uma determinada aplicação ou inicializando toda nossa aplicação, que por sua vez inicializará as outras de sua árvore de dependências.

Vamos ver como fazer a nossa tarefa Mix inicializar nossa aplicação e suas dependências:

```elixir
defmodule Mix.Tasks.Hello do
  use Mix.Task

  @shortdoc "Simply calls the Hello.say/0 function."
  def run(_) do
    # Isso inicializará nossa aplicação
    Mix.Task.run("app.start")

    Hello.say()
  end
end
```

## Tarefas Mix em Ação

Vamos verificar nossa tarefa Mix.
Enquanto estivermos no diretório, ela deve funcionar.
Na linha de comando, digite `mix hello` e então, devemos ver o seguinte:

```shell
$ mix hello
Hello, World!
```

O Mix é bastante amigável por padrão.
Ele sabe que todos podem cometer um erro de ortografia, então ele usa uma técnica chamada "fuzzy string matching" para fazer recomendações:

```shell
$ mix hell
** (Mix) The task "hell" could not be found. Did you mean "hello"?
```

Você notou que nós introduzimos um novo atributo, `@shortdoc`, no módulo? Isto facilita quando a aplicação está pronta, como quando um usuário executa o comando `mix help` no terminal.

```shell
$ mix help

mix app.start         # Starts all registered apps
...
mix hello             # Simply calls the Hello.say/0 function.
...
```

Nota: Nosso código deve ser compilado antes que novas tarefas apareçam na saída do `mix help`.
Podemos fazer isso executando o `mix compile` diretamente ou executando a nossa tarefa como fizemos com o `mix hello`, o que acionará a compilação para nós.
