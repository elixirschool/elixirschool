---
version: 1.1.2
title: Plug
---

Se você estiver familiarizado com Ruby, você pode pensar sobre Plug como o Rack com uma pitada de Sinatra. Ele fornece uma especificação para componentes de aplicação web e adaptadores para servidores web. Mesmo não fazendo parte do núcleo de Elixir, Plug é um projeto oficial de Elixir.

Nós iremos começar criando uma mini aplicação web baseada no Plug. Depois, iremos aprender sobre as rotas do Plug e como adicionar um Plug à uma aplicação web existente.

{% include toc.html %}

## Pré-requisitos

Este tutorial assume que você já tenha Elixir 1.4 ou superior e o `mix` instalados.

Se você não tem um projeto iniciado, crie um:

```shell
$ mix new example
$ cd example
```

## Dependências

Adicionar dependências é uma facilidade com mix. Para instalar Plug nós precisamos fazer duas pequenas alterações no nosso `mix.exs`.
A primeira coisa a fazer é adicionar tanto Plug quanto um servidor web(vamos utilizar o Cowboy) no nosso arquivo de dependências:

```elixir
defp deps do
  [
    {:cowboy, "~> 1.1.2"},
    {:plug, "~> 1.3.4"}
  ]
end
```

No terminal, rode o seguinte comando mix para baixar as novas dependências:

```shell
$ mix deps.get
```

## A especificação

A fim de começar a criar Plugs, nós precisamos saber e aderir a especificação Plug.
Felizmente para nós, existem apenas duas funções necessárias: `init/1` e `call/2`.

Aqui está um Plug simples que retorna "Hello World!":

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!\n")
  end
end
```

Salve o arquivo como `lib/example/hello_world_plug.ex`.

A função `init/1` é usada para iniciar as opções do nosso Plug. Ele é chamado pela árvore de supervisores, que é explicado na próxima seção. Por agora, este será uma Lista vazia que será ignorada.

O valor retornado do `init/1` será eventualmente passado para `call/2` como segundo argumento.

A função `call/2` é chamada para cada nova requisição recebida pelo servidor web Cowboy.
Ela recebe um `%Plug.Conn{}` struct como seu primeiro argumento, e é esperado que isto retorne um struct   `%Plug.Conn{}`.

## Configurando o módulo do projeto

Dado que estamos criando uma aplicação Plug do zero, precisamos definir o módulo da aplicação.
Atualize `lib/example.ex` para iniciar e superviosionar o Cowboy.

```elixir
defmodule Example do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.HelloWorldPlug, [], port: 8080)
    ]

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Ele supervisiona o Cowboy, que por sua vez, supervisiona nosso `HelloWorldPlug`.

Na chamada `Plug.Adapters.Cowboy.child_spec/4`, o terceiro argumento será passado para `Example.HelloWorldPlug.init/1`.

Nós não terminamos ainda. Abra o `mix.exs` novamente, e encontre o método `applications`.
Precisamos adicionar uma configuração para nossa aplicação, o que fará com que ele inicie automaticamente.

Vamos atualizar para fazer isso:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []}
  ]
end
```

Estamos prontos para testar este servidor web minimalista, baseado no Plug.
No terminal, execute:

```shell
$ mix run --no-halt
```

Quando a compilação estiver terminado, e aparecer `[info]  Started app`, abra o navegador em `127.0.0.1:8080`. Ele deve exibir:

```
Hello World!
```

## Plug.Router

Para a maioria das aplicações, como um site web ou uma API REST, você irá querer um router para orquestrar as requisições de diferentes paths e verbos HTTP, para diferentes manipuladores. `Plug` fornece um router para fazer isso. Como veremos, não precisamos de um framework como Sinatra em Elixir dado que nós temos isso de graça no Plug.

Para começar, vamos criar um arquivo `lib/example/router.ex` e colar o trecho a seguir nele:

```elixir
defmodule Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

Este é um mini Router, mas o código deve ser bastante auto-explicativo.
Nós incluímos alguns macros através de `use Plug.Router`, e em seguida, configuramos dois Plugs nativos: `:match` e `:dispatch`.
Existem duas rotas definidas, uma para mapear requisições GET para a raiz e a segunda para mapear todos as outras requisições, e então possamos retornar uma mensagem 404.

De volta ao `lib/example.ex`, precisamos adicionar o `Example.Router` na árvode de supervisores.
Troque o `Example.HelloWorldPlug` plug para o novo router:

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]

  Logger.info("Started application")
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Reinicie o servidor, pare o anterior se ele estiver rodando (pressione duas vezes `Ctrl+C`).

Agora no navegador, digite `127.0.0.1:8080`.
Você deve ver `Welcome`.
Então, digite `127.0.0.1:8080/waldo`, ou qualquer outro path. Isto deve retornar `Oops!` com uma resposta 404.

## Adicionando outro Plug

É comum criar Plugs para interceptar todas as requisições ou um subconjunto delas, para manipular lógicas comuns às requisições.

Para este exemplo, iremos criar um Plug para verificar se a requisição tem um conjunto de parâmetros necessários. Ao implementar a nossa validação em um Plug, podemos ter a certeza de que apenas as requisições válidas serão processadas pela nossa aplicação.
Vamos esperar que o nosso Plug seja inicializado com duas opções: `:paths` e `:fields`. Estes irão representar os caminhos que aplicamos nossa lógica, e onde os campos são exigidos.

_Note_: Plugs são aplicados a todas as requisições, e é por isso que nós filtraremos as requisições e aplicararemos nossa lógica para apenas um subconjunto delas.
Para ignorar uma requisição simplesmente passamos a conexão através do mesmo.

Vamos começar analisando o Plug que acabamos de concluir, e em seguida, discutir como ele funciona, vamos criá-lo em `lib/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified =
      body_params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

A primeira coisa a ser notada é que definimos uma nova exceção `IncompleteRequestError` e que uma de suas opções é `:plug_status`. Quando disponível esta opção é usada pelo Plug para definir o código do status HTTP no caso de uma exceção.

A segunda parte do nosso Plug é a função `call/2`. Este é o lugar onde nós lidamos quando aplicar ou não nossa lógica de verificação. Somente quando o path da requisição está contido em nossa opção `:paths` iremos chamar `verify_request/2`.

A última parte do nosso Plug é a função privada `verify_request!/2` no qual verifica se os campos requeridos `:fields` estão todos presentes. No caso em que algum dos campos requeridos estiver em falta, nós acionamos `IncompleteRequestError`.

Configuramos o nosso Plug para verificar se todas as requisições para `/upload` incluem tanto `"content"` quanto `"mimetype"`, só então o código da rota irá ser executado.

Agora, precisamos notificar o roteador sobre o novo Plug.
Edite o `lib/example/router.ex` e adicione as seguintes mudanças:

```elixir
defmodule Example.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome\n"))
  post("/upload", do: send_resp(conn, 201, "Uploaded\n"))
  match(_, do: send_resp(conn, 404, "Oops!\n"))
end
```

## Deixando a porta HTTP Configurável

Quando definimos a aplicação e o módulo `Example`, a porta HTTP foi definida diretamente no código do módulo.
É considerado uma boa prática, deixar a porta configurável usando um arquivo de configuração.

Vamos começar por atualizar o método `application` do nosso `mix.exs` para especificar ao Elixir sobre a aplicação e variáveis de ambiente. Com essas alterações nosso código local deve parecer com isso:


```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []},
    env: [cowboy_port: 8080]
  ]
end
```

Nossa aplicação está configurada na linha `mod: {Example, []}`.
Observe que também estamos inicializando as aplicações   `cowboy`, `logger` e `plug`.

Em seguida, precisamos atualizar `lib/example.ex` para ler a porta do arquivo de configuração, e passar para o Cowboy:

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Plug.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

O terceiro argumento do `Application.get_env` é um valor padrão para quando a variável de configuração não estiver definida.

> (Optional) add `:cowboy_port` in `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Agora para executar nossa aplicação, podemos usar:

```shell
$ mix run --no-halt
```

## Testando Plugs

Testes em Plugs são bastante simples, graças ao `Plug.Test`, que inclui uma série de funções convenientes para fazer o teste ser algo fácil.

Escreva o código de teste a seguir em `test/example/router_test.exs`:

```elixir
defmodule Example.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn =
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      conn(:get, "/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

Execute com o comando:

```shell
$ mix test test/example/router_test.exs
```

## Plugs disponíveis

Existem inúmeros Plugs disponíveis e fáceis de utilizar, a lista completa pode ser encontrada na documentação do Plug [neste link](https://github.com/elixir-lang/plug#available-plugs).
