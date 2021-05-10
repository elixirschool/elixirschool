---
version: 2.2.0
title: Plug
---

Se você estiver familiarizado com Ruby, você pode pensar sobre Plug como o Rack com uma pitada de Sinatra.
Ele fornece uma especificação para componentes de aplicação web e adaptadores para servidores web.
Mesmo não fazendo parte do núcleo de Elixir, Plug é um projeto oficial de Elixir.

Nessa lição nós vamos construir um simples servidor HTTP do zero usando a biblioteca em Elixir `PlugCowboy`.
Cowboy é um simples servidor HTTP para o Erlang e Plug vai nos disponibilizar um "connection adapter" para esse servidor web.

Depois de montar nossa mini aplicação web, nós vamos aprender as rotas do Plug e como usar vários plugs em uma única aplicação web.

{% include toc.html %}

## Pré-requisitos

Este tutorial assume que você já tenha Elixir 1.5 ou superior e o `mix` instalados.

Nós vamos começar criando um novo projeto OTP, com uma árvore de supervisão.

```shell
$ mix new example --sup
$ cd example
```

Nós precisamos que nossa aplicação Elixir inclua uma árvore de supervisão porque nós vamos usar um Supervisor para iniciar e rodar nosso servidor Cowboy2.

## Dependências

Adicionar dependência é muito fácil com o mix.
Para usar o Plug como uma "adapter interface" para o servidor web Cowboy2, nós precisamos instalar o pacote `PlugCowboy`:

Adicione o seguinte ao seu arquivo `mix.exs`:

```elixir
def deps do
  [
    {:plug_cowboy, "~> 2.0"},
  ]
end
```

No terminal, rode o seguinte comando mix para baixar as novas dependências:

```shell
$ mix deps.get
```

## A especificação Plug

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

A função `init/1` é usada para iniciar as opções do nosso Plug.
Ele é chamado pela árvore de supervisores, que é explicado na próxima seção.
Por agora, este será uma Lista vazia que será ignorada.

O valor retornado do `init/1` será eventualmente passado para `call/2` como segundo argumento.

A função `call/2` é chamada para cada nova requisição recebida pelo servidor web Cowboy.
Ela recebe um `%Plug.Conn{}` struct como seu primeiro argumento, e é esperado que isto retorne um struct   `%Plug.Conn{}`.

## Configurando o módulo do projeto

Nós precisamos dizer para a nossa aplicação iniciar e supervisionar o servidor web Cowboy quando a aplicação estiver de pé.

Nós vamos fazer isso com a função [`Plug.Cowboy.child_spec/1`](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#child_spec/1).

Essa função espera três opções:

* `:scheme` - HTTP ou HTTPS como um atom (`:http`, `:https`)
* `:plug` - O módulo plug que deve ser usado como a interface para o servidor web.
Você pode especificar o nome do módulo, como `MyPlug`, ou uma tupla com o nome do módulo e opções `{MyPlug, plug_opts}`, onde `plug_opts` é passada para a função `init/1` do seu módulo plug.
* `:options` - As opções do servidor.
Deve ser incluído o número da porta em que você deseja que servidor escute por requisições.


Nosso arquivo `lib/example/application.ex` deve implementar a child spec em sua função `start/2`:

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.HelloWorldPlug, options: [port: 8080]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
```

_Note_: Nós não temos que chamar `child_spec` aqui, essa função vai ser chamada pelo supervisor iniciando o processo.
Nós simplesmente passamos uma tupla com o módulo que nós queremos a child spec e as três opções necessárias.

Isso inicia o servidor Cowboy2 debaixo da árvore de supervisão de nossa app.
Ele inicia o Cowboy debaixo do esquema HTTP (você também pode especificar HTTPS), na porta dada, `8080`, especificando o plug, `Example.HelloWorldPlug`, como a interface para qualquer requisições web recebidas.

Agora nós estamos prontos para rodar nossa aplicação em enviar algumas requisições! Note que, porque nós geramos nosso OTP app com a parâmetro `--sup`, nossa aplicação `Example` vai iniciar automaticamente graças a função `application`.

No `mix.exs` você deve ver o seguinte:
```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example.Application, []}
  ]
end
```

Estamos prontos para testar este servidor web minimalista, baseado no Plug.
No terminal, execute:

```shell
$ mix run --no-halt
```

Quando a compilação estiver terminado, e aparecer `[info]  Starting application...`,
abra o navegador em `127.0.0.1:8080`.
Ele deve exibir:

```
Hello World!
```

## Plug.Router

Para a maioria das aplicações, como um site web ou uma API REST, você irá querer um router para orquestrar as requisições de diferentes paths e verbos HTTP, para diferentes manipuladores.
`Plug` fornece um router para fazer isso.
Como veremos, não precisamos de um framework como Sinatra em Elixir dado que nós temos isso de graça no Plug.

Para começar, vamos criar um arquivo `lib/example/router.ex` e colar o trecho a seguir nele:

```elixir
defmodule Example.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end  
end
```

Este é um mini Router, mas o código deve ser bastante auto-explicativo.
Nós incluímos alguns macros através de `use Plug.Router`, e em seguida, configuramos dois Plugs nativos: `:match` e `:dispatch`.
Existem duas rotas definidas, uma para mapear requisições GET para a raiz e a segunda para mapear todos as outras requisições, e então possamos retornar uma mensagem 404.

De volta ao `lib/example/application.ex`, precisamos adicionar o `Example.Router` na árvore de supervisores.
Troque o `Example.HelloWorldPlug` plug para o novo router:

```elixir
def start(_type, _args) do
  children = [
    {Plug.Cowboy, scheme: :http, plug: Example.Router, options: [port: 8080]}
  ]
  opts = [strategy: :one_for_one, name: Example.Supervisor]

  Logger.info("Starting application...")

  Supervisor.start_link(children, opts)
end
```

Reinicie o servidor, pare o anterior se ele estiver rodando (pressione duas vezes `Ctrl+C`).

Agora no navegador, digite <http://127.0.0.1:8080>.
Você deve ver `Welcome`.
Então, digite <http://127.0.0.1:8080/waldo>, ou qualquer outro path.
Isto deve retornar `Oops!` com uma resposta 404.

## Adicionando outro Plug

É comum usar mais de um plug em uma única aplicação web, cada uma tendo sua própria responsabilidade.
Por exemplo, nós podemos ter um plug que lida com roteamento, um plug que valida as requisições recebidas, um plug que autentica as requisições, etc.
Nessa seção, nós vamos definir um plug para verificar os parâmetros das requisições recebidas e nós vamos ensinar a nossa aplicação a usar _ambos_ os plugs - o router e o plug de validação.

Nós queremos criar um Plug para verificar se a requisição tem um conjunto de parâmetros necessários.
Ao implementar a nossa validação em um Plug, podemos ter a certeza de que apenas as requisições válidas serão processadas pela nossa aplicação.
Vamos esperar que o nosso Plug seja inicializado com duas opções: `:paths` e `:fields`.
Estes irão representar os caminhos que aplicamos nossa lógica, e onde os campos são exigidos.

_Note_: Plugs são aplicados a todas as requisições, e é por isso que nós filtraremos as requisições e aplicaremos nossa lógica para apenas um subconjunto delas.
Para ignorar uma requisição simplesmente passamos a conexão através do mesmo.

Vamos começar analisando o Plug que acabamos de concluir, e em seguida, discutir como ele funciona.
Vamos criá-lo em `lib/example/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  defmodule IncompleteRequestError do
    @moduledoc """
    Error raised when a required field is missing.
    """

    defexception message: ""
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.params, opts[:fields])
    conn
  end

  defp verify_request!(params, fields) do
    verified =
      params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

A primeira coisa a ser notada é que definimos uma nova exceção `IncompleteRequestError`  a qual iremos acionar no caso de uma requisição inválida.

A segunda parte do nosso Plug é a função `call/2`.
Este é o lugar onde nós lidamos quando aplicar ou não nossa lógica de verificação.
Somente quando o path da requisição está contido em nossa opção `:paths` iremos chamar `verify_request!/2`.

A última parte do nosso Plug é a função privada `verify_request!/2` no qual verifica se os campos requeridos `:fields` estão todos presentes.
No caso em que algum dos campos requeridos estiver em falta, nós acionamos `IncompleteRequestError`.

Configuramos o nosso Plug para verificar se todas as requisições para `/upload` incluem tanto `"content"` quanto `"mimetype"`.
Só então o código da rota irá ser executado.

Agora, precisamos notificar o roteador sobre o novo Plug.
Edite o `lib/example/router.ex` e adicione as seguintes mudanças:

```elixir
defmodule Example.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  get "/upload" do
    send_resp(conn, 201, "Uploaded")
  end

  match _ do
    send_resp(conn, 404, "Oops!\n")
  end
end
```

Com esse código, nós estamos dizendo à nossa aplicação para enviar as requisições recebidas através do plug `VerifyRequest` _antes_ de passar pelo código no router.
Através da chamada de função:

```elixir
plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
```
Nós automaticamente invocamos `VerifyRequest.init(fields: ["content", "mimetype"], paths: ["/upload"])`.
Isso por sua vez passa as opções recebidas para a função `VerifyRequest.call(conn, opts)`.

Vamos ver como esse plug funciona em ação! Vá em frente e quebre seu servidor local (lembre-se, isso pode ser feito pressionando `ctrl + c` duas vezes).
Então reinicie o servidor com (`mix run --no-halt`).
Agora acesse <http://127.0.0.1:8080/upload> no seu navegador e você vai ver como a página simplesmente não está funcionando. Você verá apenas uma página de erro padrão fornecida pelo seu navegador.

Agora vamos adicionar os parâmetros obrigatórios por acessar <http://127.0.0.1:8080/upload?content=thing1&mimetype=thing2>. Agora nós devemos ver nossa mensagem 'Uploaded'.

Não é legal não receber _nenhuma_ página caso um erro ocorra, mas nós vamos lidar com como tratar erros com plug depois.

## Deixando a porta HTTP Configurável

Quando definimos a aplicação e o módulo `Example`, a porta HTTP foi definida diretamente no código do módulo.
É considerado uma boa prática, deixar a porta configurável usando um arquivo de configuração.

Nós vamos adicionar uma variável no ambiente da aplicação em `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Depois nós precisamos atualizar `lib/example/application.ex` para ler a porta a partir da configuração e passar para o Cowboy.  
Nós vamos definir uma função privada para encapsular essa responsabilidade

```elixir
defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.Router, options: [port: cowboy_port()]}
    ]
    opts = [strategy: :one_for_one, name: Example.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end

  defp cowboy_port, do: Application.get_env(:example, :cowboy_port, 8080)
end
```

O terceiro argumento do `Application.get_env` é um valor padrão para quando a variável de configuração não estiver definida.

Agora para executar nossa aplicação, podemos usar:

```shell
$ mix run --no-halt
```

## Testando Plugs

Testes em Plugs são bastante simples, graças ao `Plug.Test`,
que inclui uma série de funções convenientes para fazer o teste ser algo fácil.

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
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      :get
      |> conn("/upload?content=#{@content}&mimetype=#{@mimetype}")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      :get
      |> conn("/missing", "")
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

## Plug.ErrorHandler

Nós notamos anteriormente que quando nós acessamos <http://127.0.0.1:8080/upload> sem os parâmetros esperados, não recebemos uma página de erro amigável ou um status HTTP sensato - apenas a página de erro padrão do nosso navegador com um `500 Internal Server Error`.

Vamos arrumar isso por adicionar [`Plug.ErrorHandler`](https://hexdocs.pm/plug/Plug.ErrorHandler.html).

Primeiro, nós abrimos `lib/example/router.ex` e então escrevemos o seguinte no arquivo.

```elixir
defmodule Example.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"], paths: ["/upload"]
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  get "/upload" do
    send_resp(conn, 201, "Uploaded")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end  

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.inspect(kind, label: :kind)
    IO.inspect(reason, label: :reason)
    IO.inspect(stack, label: :stack)
    send_resp(conn, conn.status, "Something went wrong")
  end
end
```

Nós vamos notar que no topo nós estamos adicionando `use Plug.ErrorHandler`.

Esse plug agora captura qualquer erro e então busca por uma função `handle_errors/2` para chamar.

`handle_errors/2` apenas precisa aceitar uma `conn` como seu primeiro argumento e então um mapa com três itens (`:kind`, `:reason`, e `:stack`) como segundo argumento.

Você pode ver que nós definimos um `handle_errors/2` bem simples para ver o que está acontecendo. Vamos reiniciar a nossa aplicação novamente para ver como ele funciona!

Agora, quando você navegar para <http://127.0.0.1:8080/upload>, você verá uma mensagem de erro amigável.

Se você olhar em seu terminal, vai ver mais ou menos o seguinte:

```shell
kind: :error
reason: %Example.Plug.VerifyRequest.IncompleteRequestError{message: ""}
stack: [
  {Example.Plug.VerifyRequest, :verify_request!, 2,
   [file: 'lib/example/plug/verify_request.ex', line: 23]},
  {Example.Plug.VerifyRequest, :call, 2,
   [file: 'lib/example/plug/verify_request.ex', line: 13]},
  {Example.Router, :plug_builder_call, 2,
   [file: 'lib/example/router.ex', line: 1]},
  {Example.Router, :call, 2, [file: 'lib/plug/error_handler.ex', line: 64]},
  {Plug.Cowboy.Handler, :init, 2,
   [file: 'lib/plug/cowboy/handler.ex', line: 12]},
  {:cowboy_handler, :execute, 2,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_handler.erl',
     line: 41
   ]},
  {:cowboy_stream_h, :execute, 3,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_stream_h.erl',
     line: 293
   ]},
  {:cowboy_stream_h, :request_process, 3,
   [
     file: '/path/to/project/example/deps/cowboy/src/cowboy_stream_h.erl',
     line: 271
   ]}
]
```

No momento, ainda estamos enviando um `500 Internal Server Error`. Podemos personalizar o código de status adicionando o campo `:plug_status` à nossa exceção. Abra o arquivo `lib/example/plug/verify_request.ex` e adicione o seguinte:

```elixir
defmodule IncompleteRequestError do
  defexception message: "", plug_status: 400
end
```

Reinicie seu servidor e atualize, e agora você receberá um `400 Bad Request`.

Esse plug facilita a captura das informações úteis necessárias para que os desenvolvedores corrijam os problemas, enquanto ainda podem dar ao usuário final uma boa página de erro, e então não parece que a sua aplicação quebrou totalmente!

## Plugs disponíveis

Existem inúmeros Plugs disponíveis prontos para uso.
A lista completa pode ser encontrada na documentação do Plug [neste link](https://github.com/elixir-lang/plug#available-plugs).
