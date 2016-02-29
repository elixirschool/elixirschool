---
layout: page
title: Ecto
category: specifics
order: 2
lang: pt
---

Ecto é um projecto oficial do Elixir que fornece um invólucro de base de dados e
linguagem integrada de consulta. Com Ecto podemos criar *migrations*, definir
modelos, inserir e actualizar registos, e consultá-los.

## Tabela de Conteúdos

- [Instalação](#setup)
  - [Repositório](#repository)
  - [Supervisor](#supervisor)
  - [Configuração](#configuration)ß
- [Tarefas Mix](#mix-tasks)
- [Migrations](#migrations)
- [Modelos](#models)
- [Consultas](#querying)
  - [O básico](#basics)
  - [Count](#count)
  - [Group By](#group-by)
  - [Order By](#order-by)
  - [Joins](#joins)
  - [Fragmentos](#fragments)
- [Changesets](#changesets)

## <a name="setup"></a>Instalação

Para começar precisamos incluir Ecto e um adaptador de base de dados no `mix.exs`
do nosso projecto. Você pode encontrar uma lista de adaptadores de base de dados
suportados na secção [*Usage*](https://github.com/elixir-lang/ecto/blob/master/README.md#usage)
do README do Ecto. Para o nosso exemplo iremos usar o PostgreSQL:

```elixir
defp deps do
  [{:ecto, "~> 1.0"},
   {:postgrex, ">= 0.0.0"}]
end
```

Agora podemos adicionar o Ecto e o nosso adaptador na lista da aplicações:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### <a name="setup"></a>Repositório

Finalmente precisamos criar o repositório do nosso projecto, o invólucro da base
de dados. Isto pode ser feito rodando a tarefa `mix ecto.gen.repo`, falaremos sobre
tarefas mix no Ecto mais para frente. O Repositório pode ser encontrado no arquivo
`lib/<nome_do_projecto>/repo.ex`:

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo,
    otp_app: :example_app
end
```

### <a name="supervisor"></a>Supervisor

Uma vez criado o nosso Repositório, precisamos configurar nossa árvore de supervisor,
que normalmente é encontrada em `lib/<nome_do_projecto>.ex`.

É importante notar que configuramos o Repositório como um supervisor usando `supervisor/3`
e _não_ `worker/3`. Se você gerou sua aplicação usando a flag `--sup` muito disso já existe:

```elixir
defmodule ExampleApp.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(ExampleApp.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Para mais informações sobre supervisores, consulte a lição [Supervisores OTP](/lessons/advanced/otp-supervisors).

### <a name="configuration"></a>Configuração

Para configurar o Ecto precisamos adicionar uma secção no nosso `config/config.exs`.
Aqui iremos especificar o repositório, o adaptador, a base de dados e informações
de acesso à base de dados:

```elixir
config :example_app, ExampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Tarefas Mix

Ecto inclui uma série de tarefas mix úteis para trabalhar com a nossa base de dados:

```shell
mix ecto.create         # Cria a base de dados para o Repositório
mix ecto.drop           # Elimina a base de dados do Repositório
mix ecto.gen.migration  # Gera uma nova *migration* para o repositório
mix ecto.gen.repo       # Gera um novo repositório
mix ecto.migrate        # Roda as migrations em cima do repositório
mix ecto.rollback       # Reverte migrations a partir de um repositório
```

## <a name="migrations"></a>Migrations

A melhor forma de criar migrations é usando a tarefa `mix ecto.gen.migration <nome_da_migration>`.
Se você está familiarizado com ActiveRecord, isto irá parecer familiar.

Vamos começar dando uma olhada numa migration para uma tabela *users*:

```elixir
defmodule ExampleApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, unique: true
      add :encrypted_password, :string, null: false
      add :email, :string
      add :confirmed, :boolean, default: false

      timestamps
    end

    create unique_index(:users, [:username], name: :unique_usernames)
  end
end
```

Por padrão Ecto cria uma chave primária `id` auto incrementado. Aqui estamos a usar
o callback padrão `chage/0` mas Ecto também suporta `up/0` e `down/0` no caso de
precisar um controle mais granular.

Como você deve ter adivinhado, adicionando `timestamps` na sua migration irá criar
e gerir os campos `created_at` e `updated_at` por você.

Para aplicar as alterações definidas na nossa migration, roda `mix ecto.migrate`.

Para mais informações dê uma olhada a secção [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content)
da documentação.

## <a name="models"></a>Modelos

Agora que temos nossa migration podemos continuar para o modelo. Modelos definem o
nosso esquema, métodos auxiliares, e nosso *changeset*. Iremos falar mais sobre
*changesets* nas próximas secções.

Por agora vamos dar uma olhada em como o modelo para nossa migration se parece:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :encrypted_password, :string
    field :email, :string
    field :confirmed, :boolean, default: false
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps
  end

  @required_fields ~w(username encrypted_password email)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
  end
end
```

O esquema que definimos no nosso modelo representa de perto o que especificamos
na nossa migration. Além dos campos para nossa base de dados, estamos também a
incluir dois campos virtuais. Campos virtuais não são armazenados na base de dados
mas podem ser úteis para casos como da validação. Veremos os campos virtuais em
acção na secção [Changeset](#changeset).

## <a name="querying"></a>Consultas

Antes de consultar o nosso repositório, precisamos importar a *API Query*, por
enquanto precisamos importar apenas `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

A documentação oficial pode ser encontrada em [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html).

### <a name="basics"></a>O Básico

Ecto fornece uma excelente DSL<sup>(domain-specific language)</sup> de consulta que nos permite expressar consultas de forma muito clara. Para encontrar os usernames de todas as contas confirmadas poderíamos usar algo como este:

```elixir
alias ExampleApp.{Repo,User}

query = from u in User,
    where: u.confirmed == true,
    select: u.username

Repo.all(query)
```

Além do `all/2` Repo fornece uma série de callbacks incluindo `one/2`, `get/3`, `insert/2`, e `delete/2`. Uma lista completa de callbacks pode ser encontrada em [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### <a name="count"></a>Count

```elixir
query = from u in User,
    where: u.confirmed == true,
    select: count(u.id)
```

### <a name="group-by"></a>Group By

Para agrupar usernames por estado de confirmação podemos incluir a opção `group_by`:

```elixir
query = from u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]

Repo.all(query)
```

### <a name="order-by"></a>Order By

Ordenar utilizadores pela data de criação:

```elixir
query = from u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]

Repo.all(query)
```

Para ordenar por `DESC`:

```elixir
query = from u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
```

### <a name="joins"></a>Joins

Assumindo que temos um perfil associado ao nosso utilizador, vamos encontramos todos os perfis de contas confirmadas:

```elixir
query = from p in Profile,
    join: u in assoc(profile, :user),
    where: u.confirmed == true
```

### <a name="fragments"></a>Fragmentos

As vezes a API Query não é suficiente, por exemplo, quando precisamos de funções específicas para base de dados. A função `fragment/1` existe para esta finalidade:

```elixir
query = from u in User,
    where: fragment("downcase(?)", u.username) == ^username
    select: u
```

Outros exemplos de consultas podem ser encontradas na descrição do módulo [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html).

## Changesets

Na secção anterior aprendemos como recuperar dados. Mas então como inserir e actualizá-los? Para isso precisamos de *Changesets*.

Changesets cuidam da filtragem, validação, manutenção das *constraints* quando alteramos um modelo.

Para este exemplo iremos nos focar no *changeset* para criação de conta de utilizador. Para começar precisamos actualizar o nosso modelo:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field :username, :string
    field :encrypted_password, :string
    field :email, :string
    field :confirmed, :boolean, default: false
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps
  end

  @required_fields ~w(username email password password_confirmation)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_password_confirmation()
    |> unique_constraint(:username, name: :email)
    |> put_change(:encrypted_password, hashpwsalt(params[:password]))
  end

  defp validate_password_confirmation(changeset) do
    case get_change(changeset, :password_confirmation) do
      nil ->
        password_mismatch_error(changeset)
      confirmation ->
        password = get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_incorrect_error(changeset)
    end
  end

  defp password_mismatch_error(changeset) do
    add_error(changeset, :password_confirmation, "Passwords does not match")
  end

  defp password_incorrect_error(changeset) do
    add_error(changeset, :password, "is not valid")
  end
end
```

Melhoramos nossa função `changeset/2` e adicionamos três novas funções auxiliares: `validate_password_confirmation/1`, `password_mismatch_error/1` e `password_incorrect_error/1`.

Como o próprio nome sugere, `changeset/2` cria para nós um novo *changeset*. Nele usamos `cast/4` para converter nossos parametros para um *changeset* a partir de um conjuto de campos obrigatórios e opcionais. A seguir validamos o tamanho da palavra-passe do *changeset*, correspondência da confirmação da palavra-passe usando a nossa propria função, e a unicidade do nome de utilizador. Por último actualizamos nosso actual campo da base de dados para palavra-passe. Para tal usamos `put_change/3` para actualizar um valor no *changeset*. password confirmation match using our own function, and username uniqueness.  Finally we update our actual password database field.  For this we use `put_change/3` to update a value in the changeset.

Usar `User.changeset/2` é relativamente simples:

```elixir
alias ExampleApp.{User,Repo}

pw = "passwords should be hard"
changeset = User.changeset(%User{}, %{username: "doomspork",
                    email: "sean@seancallan.com",
                    password: pw,
                    password_confirmation: pw})

case Repo.insert(changeset) do
  {:ok, model}        -> # Inserted with success
  {:error, changeset} -> # Something went wrong
end
```

É isso aí! Agora você está pronto para guardar alguns dados.
