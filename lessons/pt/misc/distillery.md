%{
  version: "2.0.4",
  title: "Distillery (Básico)",
  excerpt: """
  Distillery é um gerenciador de releases escrito em Elixir puro.
Ele permite que você produza releases que podem ser deployed em outros lugares com pouca ou nenhuma configuração.
  """
}
---

## O que é uma release?

Uma release é um pacote contendo o seu código Erlang/Elixir compilado (ex [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) [bytecode](https://en.wikipedia.org/wiki/Bytecode)).
Ela também provê quaisquer scripts necessários para rodar a sua aplicação.

> Quando você escrever uma ou mais aplicações, você talvez queira criar um sistema completo com estas aplicações e um subconjunto das aplicações Erlang/OTP. Isto é chamado de release. - [Documentação do Erlang](http://erlang.org/doc/design_principles/release_structure.html)

> Releases permitem deployment simplificados: elas são auto-contidas, e provêm tudo o que for necessário para iniciar a release; elas são facilmente administradas via o shell script provido para abrir um console remoto, iniciar/parar/reiniciar a release, iniciar no background, enviar comandos remotos, e mais. Além disso, elas são artefatos arquiváveis, o que significa que você pode restaurar uma release antiga do seu tarball em qualquer momento no futuro (salvo incompatibilidades com o SO ou bibliotecas do sistema). O uso de releases também é um pré-requisito para realizar hot upgrades e downgrades, um dos recursos mais poderosos da VM do Erlang. - [Documentação do Distillery](https://hexdocs.pm/distillery/introduction/understanding_releases.html)

Uma release irá conter o seguinte:
* uma pasta /bin
  * Esta contém um script que é o ponto de início para rodar a sua aplicação inteira.
* uma pasta /lib
  * Esta contém o bytecode compilado da aplicação junto com quaisquer dependências.
* uma pasta /releases
  * Esta contém metadados sobre a release assim como também hooks e comandos customizados.
* Um /erts-VERSION
  * Este contém o runtime do Erlang que irá permitir que uma máquina execute a sua aplicação sem necessitar ter o Erlang ou Elixir instalados.


### Iniciando/instalação

Para adicionar o Distillery no seu projeto, adicione-o como uma dependência no seu arquivo `mix.exs`.
*Nota* - se você estiver trabalhando numa aplicação umbrella isto deve estar no mix.exs na raiz do seu projeto

```elixir
defp deps do
  [{:distillery, "~> 2.0"}]
end
```

Então no seu terminal execute:

```shell
mix deps.get
```

```shell
mix compile
```


### Construindo a sua release

No seu terminal, execute

```shell
mix release.init
```

Este comando gera um diretório `rel` com alguns arquivos de configuração nele.

Para gerar uma release no terminal execute `mix release`

Quando a release for produzida, você deve ver algumas instruções no seu terminal

```shell
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

Para executar sua aplicação, digite o seguinte no seu terminal ` _build/dev/rel/MYAPP/bin/MYAPP foreground`
No seu caso substitua MYAPP com o nome do seu projeto.
Agora nós estamos rodando o build da release da nossa aplicação!


## Utilizando Distillery com o Phoenix

Se você estiver usando o Distillery com o Phoenix há alguns passos extras que você precisa seguir disto de funcionar.

Primeiro, precisamos editar o nosso arquivo `config/prod.exs`.

Altere a seguinte linha disto:

```elixir
config :book_app, BookAppWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
```
para isto:

```elixir
config :book_app, BookAppWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:book_app, :vsn)
```

Nós fizemos algumas coisas aqui:
- `server` - inicia o endpoint HTTP da aplicação Cowboy no início do aplicação
- `root` - define a raiz da aplicação que é onde os arquivos estáticos são servidos
- `version` - quebra o cache da aplicação quando a versão da mesma sofre um hot upgrade
- `port` - alterar a porta para ser setada por uma variável de ambiente permite que passamos o número da porta quando estivermos iniciando a aplicação.
Quando iniciamos a aplicação, podemos suprir a porta executando `PORT=4001 _build/prod/rel/book_app/bin/book_app foreground`

Se você executou o comando acima, você talvez tenha notado que a sua aplicação crashou porquê é incapaz de conectar ao banco de dados já que nenhum banco de dados atualmente existe.
Isto pode ser retificado executando um comando `mix` do Ecto.
No seu terminal, digite o seguinte:

```shell
MIX_ENV=prod mix ecto.create
```

Este comando irá criar o seu banco de dados para você.
Tente executar novamente a aplicação e ela deve iniciar com sucesso.
Entretanto, você irá notar que a suas migrations para o seu banco de dados não foram executadas.
Normalmente em desenvolvimento executamos essas migrations manualmente chamando `mix.ecto.migrate`.
Para a release, nós teremos que configurar isto para que ela possa rodar as migrations por si própria.


## Executando Migrations em Produção

O Distillery nos provê a habilidade de executar código em diferentes pontos do ciclo de vida da release. Estes pontos são conhecidos como  [boot-hooks](https://hexdocs.pm/distillery/1.5.2/boot-hooks.html). Os hooks fornecidos pelo Distillery incluem:

* pre_start
* post_start
* pre/post_configure
* pre/post_stop
* pre/post_upgrade


Para o nosso propósito, iremos estar utilizando o hook `post_start` para executar as migrações da nossa aplicação em produção.
Primeiro vamos criar uma nova tarefa da release chamada `migrate`.
Uma tarefa de release é um módulo que podemos chamar pelo terminal e que contém código que é separado do funcionamento interno da nossa aplicação.
Isto é útil para tarefas que a aplicação em si não precisa tipicamente executar.

```elixir
defmodule BookAppWeb.ReleaseTasks do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:book_app)

    path = Application.app_dir(:book_app, "priv/repo/migrations")

    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)
  end
end
```

*Nota* É uma boa prática garantir que a sua aplicação iniciou devidamente antes de rodar estas migrations.
O [Ecto.Migrator](https://hexdocs.pm/ecto/2.2.8/Ecto.Migrator.html) nos permite executar nossas migrations com o banco de dados conectado.

Depois, crie um novo arquivo - `rel/hooks/post_start/migrate.sh` e adicione o seguinte código:


```shell
echo "Running migrations"

bin/book_app rpc "Elixir.BookApp.ReleaseTasks.migrate"

```

Para que este código execute devidamente, estamos usando o módulo `rpc` do Erlang que fornece o serviço de Produzir Chamada Remota (Remote Produce Call).
Basicamente, isto nos permite chamar uma função em um nó remoto e obter a resposta.
Quando estiver rodando em produção é provável que a nossa aplicação estará rodando em vários nós diferentes.

Por último, em nosso arquivo `rel/config.exs` iremos adicionar o hook para a nossa configuração de prod.

Vamos substituir

```elixir
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
end
```

por

```elixir
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
  set post_start_hooks: "rel/hooks/post_start"
end
```

*Nota* - Este hook apenas existe na release de produção desta aplicação.
Se usarmos a release padrão de desenvolvimento ele não irá executar.

## Comandos Customizados

Quando estiver trabalhando com uma release, você talvez não tenha acesso aos comandos `mix` pois o `mix` talvez não esteja instalado onde a release foi deployed.
Nós podemos resolver isso criando comandos customizados.

> Comandos customizados são estensões do script de inicialização, e são utilizados da mesma maneira que você utiliza foreground ou remote_console, em outras palavras, eles aparentam ser parte do script de inicialização. Assim como hooks, eles tem acesso as helper functions e o ambiente dos scripts de inicialização - [Documentação do Distillery](https://hexdocs.pm/distillery/1.5.2/custom-commands.html)

Comandos são similares a tarefas de release no sentido de que são ambos funções de método mas são diferentes deles no sentido de que eles são executados através do terminal no lugar de serem executados pelo script da release.

Agora que podemos executar nossas migrations, nós talvez queiramos sermos capazes de popular nosso banco de dados com informação através de um comando.
Primeiro, adicione um novo método as nossas tarefas da release. Em `BookAppWeb.ReleaseTasks`, adicione o seguinte:

```elixir
def seed do
  seed_path = Application.app_dir(:book_app_web, "priv/repo/seeds.exs")
  Code.eval_file(seed_path)
end
```

Depois, crie um novo arquivo `rel/commands/seed.sh` e adicione o seguinte código:

```bash
#!/bin/sh

release_ctl eval "BookAppWeb.ReleaseTasks.seed/0"
```


*Nota* - `release_ctl()` é um shell script fornecido pelo Distillery que nos permite executar comandos localmente ou em um nó limpo.
Se você precisa rodar isto em um nó já em execução você pode executar `release_remote_ctl()`

Veja mais sobre shell_scripts do Distillery [aqui](https://hexdocs.pm/distillery/extensibility/shell_scripts.html)

Por último, adicione o seguinte ao seu arquivo `rel/config.exs`
```elixir
release :book_app do
  ...
  set commands: [
    seed: "rel/commands/seed.sh"
  ]
end

```

Certifique-se de recriar a release executando `MIX_ENV=prod mix release`.
Uma vez que este processo for concluído, você agora pode executar no seu terminal `PORT=4001 _build/prod/rel/book_app/bin/book_app seed`.
