%{
  version: "1.0.4",
  title: "Guardian (Basics)",
  excerpt: """
  [Guardian](https://github.com/ueberauth/guardian) é uma biblioteca de autenticação amplamente utilizada tendo como base o [JWT](https://jwt.io/) (JSON Web Tokens).
  """
}
---

## JWTs

Um JWT pode fornecer um token rico para autenticação.
Onde muitos sistemas de autenticação fornecem acesso à apenas o identificador do sujeito para o recurso, JWTs fornecem isto junto com outras informações como:

* Quem emitiu o token
* Para quem é o token
* Que sistema deve usar o token
* Quando ele foi emitido
* Quando o token expira

Além desses campos o Guardian fornece outros campos para facilitar funcionalidades adicionais:

* Qual é o tipo do token
* Que permissões o portador tem

Esses são apenas alguns campos básico em um JWT.
Você é livre para acrescentar qualquer informação adicional que a sua aplicação necessite.
Apenas lembre de mantê-lo pequeno, porque o JWT tem que caber em um header HTTP.

Essa riqueza significa que você pode passar JWTs pelo seu sistema como uma unidade totalmente contida de credenciais.

### Onde usá-los

JWT tokens podem ser usados para autenticar qualquer parte da sua aplicação.

* Single page applications
* Controllers (via browser session)
* Controllers (via authorization headers - API)
* Phoenix Channels
* Service to Service requests
* Inter-process
* 3rd Party access (OAuth)
* Funcionalidade lembre-me
* Outras interface - TCP puro, UDP, CLI, etc

JWT tokens podem ser usados em todos os lugares da sua aplicação onde você precisa fornecer autenticação verificável.

### Eu preciso usar um banco de dados?

Você não precisa rastrear um JWT através de um banco de dados.
Você pode simplesmente contar com os timestamps de emissão e expiração para controlar o acesso.
Frequentemente você acabará usando um banco de dados para procurar por seu registro de usuário mas o JWT em si não necessita disso.

Por exemplo, se você fosse usar JWT para autenticar comunicação em um socket UDP você provavelmente não iria usar um banco de dados.
Codifique toda a informação que você precisa diretamente no token quando você emiti-lo.
Uma vez que você verificá-lo (verificar se ele está assinado corretamente), você está pronto para continuar.

Você _pode_ no entanto usar um banco de dados para salvar um JWT.
Se você fizer isso, você ganha a habilidade de verificar se o token ainda é válido - isto é - se ele não foi revogado.
Ou você pode usar os registros do banco para forçar um logout do usuário.
Isso é bem simples de fazer no Guardian por usar o [GuardianDb](https://github.com/hassox/guardian_db).
GuardianDb usa 'Hooks' do Guardian para realizar verificações, salvar e deletar do banco.
Nós vamos abordar isso depois.

## Instalação

Há muitas opções para configurar o Guardian. Nós vamos abordar elas em um certo ponto mas vamos começar com uma instalação muito simples.

### Instalação mínima

Para começar há algumas coisas que você vai precisar.

#### Configuração

`mix.exs`

```elixir
def application do
  [
    mod: {MyApp, []},
    applications: [:guardian, ...]
  ]
end

def deps do
  [
    {:guardian, "~> x.x"},
    ...
  ]
end
```

`config/config.exs`

```elixir
# no arquivo de configuração de cada ambiente você deve sobrescrever isto se é externo
config :guardian, Guardian,
  issuer: "MyAppId",
  secret_key: Mix.env(),
  serializer: MyApp.GuardianSerializer
```

Esse é o conjunto mínimo de informações que você precisa fornecer ao Guardian para ele operar.
Você não deve codificar a sua chave privada diretamente em sua configuração geral.
Em vez disso, cada ambiente deve ter sua própria chave privada.
É comum usar o ambiente do Mix para chaves em desenvolvimento e teste.
Mas em staging e produção, você deve usar chaves fortes.
(e.g.
gerados com `mix phoenix.gen.secret`)

`lib/my_app/guardian_serializer.ex`

```elixir
defmodule MyApp.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias MyApp.Repo
  alias MyApp.User

  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, "Unknown resource type"}
end
```
O seu serializer é responsável por encontrar o recurso no campo `sub` (sujeito).
Isso pode ser uma busca em banco de dados, em uma API, ou até uma simples string.
Ele ainda é responsável por serializar o recurso em um campo `sub`.

Isso é para a configuração inicial.
Há ainda muito mais que você pode fazer se você precisar mas para iniciar é o suficiente.

#### Uso na Aplicação

Agora que nós temos uma configuração feita para usar o Guardian, nós precisamos integrá-lo na aplicação.
Visto que essa é uma configuração mínima, vamos primeiro considerar requisições HTTP.

## HTTP requests

O Guardian fornece vários Plugs para facilitar a integração em requisições HTTP.
Você pode aprender sobre o Plug em uma [outra lição](../../specifics/plug/).
O Guardian não precisa do Phoenix, mas usar o Phoenix nos exemplos a seguir será mais fácil para demonstrar o uso.

A maneira mais fácil de integrar com o HTTP é através de um router.
Já que as integrações do Guardian com o HTTP são todas baseadas em plugs, você pode usá-las em qualquer lugar que um plug pode ser usado.

O fluxo geral do plug do Guardian é:

1. Encontra um token na requisição (em algum lugar) e verifica ele: `Verify*` plugs
2. Opcionalmente carrega o recurso indentificado no token: `LoadResource` plug
3. Garante que há um token válido para a requisição e recusa o acesso se não há. `EnsureAuthenticated` plug

Para atender as necessidades de todos os desenvolvedores, o Guardian implementa essa fase separadamente.
Para encontrar o token use os plugs `Verify*`

Vamos criar alguns pipelines.

```elixir
pipeline :maybe_browser_auth do
  plug(Guardian.Plug.VerifySession)
  plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
  plug(Guardian.Plug.LoadResource)
end

pipeline :ensure_authed_access do
  plug(Guardian.Plug.EnsureAuthenticated, %{"typ" => "access", handler: MyApp.HttpErrorHandler})
end
```

Esses pipelines podem ser usados para compor diferentes requisitos de autenticação.
O primeiro pipeline tenta encontrar um token primeiro na sessão e então tenta em um header.
Se um é encontrado, ele vai carregar o recurso para você.

O segundo pipeline exige que um token válido e verificado esteja presente e que seja do tipo "access".
Para usar esses pipelines, adicione eles ao seu scope.

```elixir
scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth])

  get("/login", LoginController, :new)
  post("/login", LoginController, :create)
  delete("/login", LoginController, :delete)
end

scope "/", MyApp do
  pipe_through([:browser, :maybe_browser_auth, :ensure_authed_access])

  resource("/protected/things", ProtectedController)
end
```

As rotas de login acima vão ter o usuário autenticado se existir um.
O segundo scope acima garante que um token válido é passado para todas as ações.
Você não _precisa_ colocar eles em pipelines, você poderia colocá-los em seus controllers para uma customização super flexível mas nós estamos fazendo uma configuração mínima.

Nós estamos esquecendo de algo até agora.
O manipulador de erro adicionado no plug `EnsureAuthenticated`.
Esse é um módulo muito simples que responde a

* `unauthenticated/2`
* `unauthorized/2`

As duas funções recebem uma struct Plug.Conn e um map com parâmetros e deve lidar com os seus respectivos erros.
Você pode até usar um controller do Phoenix!

#### No controller

Dentro do controller, há algumas opções de como acessar o usuário atualmente logado.
Vamos começar com o mais simples.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller
  use Guardian.Phoenix.Controller

  def some_action(conn, params, user, claims) do
    # do stuff
  end
end
```

Ao usar o módulo `Guardian.Phoenix.Controller`, as suas ações vão receber dois argumentos adicionais que você pode usar pattern matching.
Lembre, se você não usar `EnsureAuthenticated` você pode ter user e claims nulos.

A outra versão - a mais flexível/verbosa - é usar plug helpers.

```elixir
defmodule MyApp.MyController do
  use MyApp.Web, :controller

  def some_action(conn, params) do
    if Guardian.Plug.authenticated?(conn) do
      user = Guardian.Plug.current_resource(conn)
    else
      # No user
    end
  end
end
```

#### Login/Logout

Fazer o login e logout de uma sessão do browser é muito simples.
No controller de login:

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      # Use access tokens.
      # Other tokens can be used, like :refresh etc
      conn
      |> Guardian.Plug.sign_in(user, :access)
      |> respond_somehow()

    {:error, reason} ->
      nil
      # handle not verifying the user's credentials
  end
end

def delete(conn, params) do
  conn
  |> Guardian.Plug.sign_out()
  |> respond_somehow()
end
```

Quando usado para fazer o login de uma API, é levemente diferente porque não há sessão e você precisa fornecer o token puro de volta para o cliente.
Para login de uma API você provavelmente usará o header `Authorization` para fornecer o token para a sua aplicação.
Esse método é útil quando você não pretende usar uma sessão.

```elixir
def create(conn, params) do
  case find_the_user_and_verify_them_from_params(params) do
    {:ok, user} ->
      {:ok, jwt, _claims} = Guardian.encode_and_sign(user, :access)
      conn |> respond_somehow(%{token: jwt})

    {:error, reason} ->
      # handle not verifying the user's credentials
  end
end

def delete(conn, params) do
  jwt = Guardian.Plug.current_token(conn)
  Guardian.revoke!(jwt)
  respond_somehow(conn)
end
```

O login usando a sessão do browser executa `encode_and_sign` debaixo dos panos então pode usá-lo da mesma forma.
