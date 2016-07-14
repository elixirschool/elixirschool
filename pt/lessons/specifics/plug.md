---
layout: page
title: Plug
category: specifics
order: 1
lang: pt
---

Se você estiver familiarizado com Ruby, você pode pensar sobre Plug como o Rack com uma pitada de Sinatra, ele fornece uma especificação para componentes de aplicação web e adaptadores para servidores web. Mesmo não fazendo parte do núcleo de Elixir, Plug é um projeto oficial de Elixir.

{% include toc.html %}

## Instalação

A instalação é uma brisa se você utilizar mix. Para instalar Plug nós precisamos fazer duas pequenas alterações no nosso `mix.exs`. A primeira coisa a fazer é adicionar tanto Plug quanto um servidor web para o nosso arquivo de dependências, vamos utilizar Cowboy:

```elixir
defp deps do
  [{:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"}]
end
```

A última coisa que nós precisamos fazer é adicionar tanto o nosso servidor web quanto o Plug na nossa aplicação OTP:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## A especificação

A fim de começar a criar Plugs, nós precisamos saber e aderir a especificação Plug. Felizmente para nós, existem apenas duas funções necessárias: `init/1` e `call/2`.

A função `init/1` é usada para iniciar as opções do nosso Plug, passando como o segundo argumento para nossa função `call/2`. Além de nossas opções para inicialização da função `call/2`, a função recebe um `%Plug.Conn` como seu primeiro argumento, e é esperado que isto retorne uma conexão.

Aqui está um simples plug que retorna "Olá mundo!":

```elixir
defmodule HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end
end
```

## Criando um Plug

Para este exemplo, iremos criar um Plug para verificar se a requisição tem um conjunto de parâmetros necessários. Ao implementar a nossa validação em um Plug, podemos ter a certeza de que apenas os pedidos válidos serão gerenciados através de nosso aplicativo. Vamos esperar que o nosso Plug seja inicializado com duas opções: `:paths` e `:fields`. Estes irão representar os caminhos que aplicamos nossa lógica onde os campos são exigidos.

_Note_: Plugs são aplicadas a todas as requisições, e é por isso que nós iremos lidar com filtragem de solicitações e aplicar nossa lógica para apenas um subconjunto deles. Para ignorar um pedido simplesmente passamos a conexão através do mesmo.

Vamos começar analisando o Plug que acabamos de concluir, e em seguida, discutir como ele funciona, vamos criá-o em `lib/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

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
    verified = body_params
               |> Map.keys
               |> contains_fields?(fields)
    unless verified, do: raise IncompleteRequestError
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```
A primeira coisa a ser notada é que definimos uma nova exceção `IncompleteRequestError` e que uma de suas opções é `:plug_status`. Quando disponível esta opção é usada pelo Plug para definir o código de status do HTTP no caso de uma exceção.

A segunda parte do nosso Plug é o método `call/2`, este é o lugar onde nós lidamos quando aplicar ou não nossa lógica de verificação. Somente quando o caminho do pedido está contido em nossa opção `:paths` iremos chamar `verify_request/2`.

A última parte do nosso Plug é a função privada `verify_request!/2` no qual verifica quando os campos requeridos `:fields` estão todos presentes. No caso em que algum dos campos requeridos estiver em falta, nós acionamos `IncompleteRequestError`.

## Usando Plug.Router

Agora que temos o nosso Plug `VerifyRequest`, podemos seguir para o nosso roteador. Como estamos prestes a ver, não precisamos de uma estrutura como Sinatra em Elixir, ganhamos isso de graça com Plug.

Para iniciar vamos criar um arquivo `lib/plug/router.ex` e copiar o seguinte código dentro deste:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  match _, do: send_resp(conn, 404, "Oops!")
end
```

Este é um Router mínimo, mas o código deve ser bastante auto-explicativo. Nós incluímos alguns macros através de `use Plug.Router`, e em seguida, configuramos dois Plugs nativos: `:match` e `:dispatch`. Existem duas rotas definidas, uma para manipulação retornos de GET para a raiz e a segunda para combinar todos os outros requests para que possamos retornar uma mensagem 404.

Vamos adicionar o nosso plug ao roteador:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"],
                      paths:  ["/upload"]
  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  post "/upload", do: send_resp(conn, 201, "Uploaded")
  match _, do: send_resp(conn, 404, "Oops!")
end
```
É isso aí! Nós configuramos o nosso Plug para verificar se todas as requisições para `/upload` incluem tanto `"content"` quanto `"mimetype"`, só então o código de rota irá ser executado.

Por agora nosso endpoint `/upload` não é muito útil, mas vimos como criar e integrar o nosso Plug.


## Executando nosso Web App

Antes de podermos executar nossa aplicação nós precisamos instalar e configurar o nosso servidor web, neste caso Cowboy. Por agora vamos fazer as mudanças necessários no código para rodar tudo, e então vamos nos aprofundar em coisas específicas em lições futuras.

Vamos começar por atualizar parte de `application` do nosso `mix.exs` para especificar ao Elixir sobre a aplicação e variáveis de ambiente. Com essas alterações nosso código local deve parecer com isso:


```elixir
def application do
  [applications: [:cowboy, :plug],
   mod: {Example, []},
   env: [cowboy_port: 8080]]
end
```

Em seguida, precisamos atualizar `lib/example.ex` para iniciar o supervisor para o Cowboy:

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

Agora para executar nossa aplicação, podemos usar:

```shell
$ mix run --no-halt
```

## Testando Plugs

Testes em Plugs são bastante simples, graças ao `Plug.Test`, que inclui uma série de funções convenientes para fazer o teste ser algo fácil.

Veja se você consegue seguir o raciocínio do teste no router:


```elixir
defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Plug.Router

  @content "<html><body>Hi!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn = conn(:get, "/", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn = conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
           |> put_req_header("content-type", "application/x-www-form-urlencoded")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn = conn(:get, "/missing", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

## Plugs disponíveis

Há um número de Plugs disponíveis e fáceis de utilizar, a lista completa pode ser encontrada na documentação do Plug [neste link](https://github.com/elixir-lang/plug#available-plugs).
