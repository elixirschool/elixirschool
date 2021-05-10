%{
  version: "2.4.0",
  title: "Básico",
  excerpt: """
  Ecto é um projeto oficial do Elixir que fornece uma camada de banco de dados e linguagem integrada para consultas. Com Ecto podemos criar migrações, definir esquemas, inserir e atualizar registros, e fazer consultas.
  """
}
---

### Adaptadores
O Ecto suporta diferentes banco de dados através do uso de adaptadores. Alguns
exemplos de adaptadores são:

+ PostgreSQL
+ MySQL
+ SQLite

Nessa lição configuraremos o Ecto para usar o adaptador do PostgreSQL.

### Começando
Nesta lição, cobriremos três partes do Ecto:

+ O repositório: provê a interface com nosso banco de dados, incluindo a conexão.
+ Migrações: um mecanismo para criar, modificar e destruir tabelas e índices no
  banco de dados.
+ Esquemas: estruturas especiais para representar linhas em tabelas no banco de
  dados.

Para iniciar criaremos uma aplicação com uma árvore de supervisão:

```shell
$ mix new friends --sup
$ cd friends
```

Adicione o ecto e o postgrex como dependências no seu `mix.exs`:

```elixir
defp deps do
  [
    {:ecto_sql, "~> 3.2"},
    {:postgrex, "~> 0.15"}
  ]
end
```

Depois, busque as dependências usando:

```shell
$ mix deps.get
```

#### Criando um repositório
Um repositório no Ecto mapeia a um banco de dados, como o nosso banco no
Postgres. Toda a comunicação ao banco de dados será feita através desse
repositório.

Crie um repositório rodando:

```shell
$ mix ecto.gen.repo -r Friends.Repo
```

Essa tarefa irá gerar toda a configuração requirida para conectar a um banco de dados em `config/config.exs`, incluindo a configuração do adaptador. Esse é o arquivo de configuração para nosso banco de dados `Friends`:

```elixir
config :friends, Friends.Repo,
  database: "friends_repo",
  username: "postgres",
  password: "",
  hostname: "localhost"
```

Ela também gera um módulo chamado `Friends.Repo` em `lib/friends/repo.ex`

```elixir
defmodule Friends.Repo do
  use Ecto.Repo,
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

Nós iremos utilizar o módulo `Friends.Repo` para consultar o banco de dados.
Nós também dizemos a esse módulo para encontrar suas configurações na aplicação
`:friends` e selecionamos o adaptador `Ecto.Adapters.Postgres`.

A seguir, iremos configurar o `Friends.Repo` como supervisor de nossa árvore de
supervisão em `lib/friends/application.ex`. Isso irá iniciar o processo do Ecto
assim que nossa aplicação iniciar.

```elixir
def start(_type, _args) do
  # List all child processes to be supervised
  children = [
    Friends.Repo
  ]

...
``` 

Depois disso, precisamos adicionar a seguinte linha no nosso
`config/config.exs`: 

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

Isso irá permitir à nossa aplicação rodar tarefas mix do Ecto a partir da linha
de comando.

Já concluímos a configuração do repositório! Agora podemos criar o banco de
dados no PostgreSQL com o seguinte comando:

```shell
$ mix ecto.create
```

Ecto vai utilizar a informação no arquivo `config/config.exs` para determinar
como se conectar ao Postgres e como nomear o banco de dados.

Se você receber algum erro, certifique-se de que os dados de configuração estão
corretos e de que sua instância do postgres está rodando.

### Migrações

Para criar e modificar tabelas no banco de dados, utilizamos as migrações do
Ecto. Cada migração descreve uma série de ações para serem realizadas no nosso
banco, como quais tabelas criar ou atualizar.

Como nosso banco de dados ainda não tem nenhuma tabela, precisaremos criar uma
migração para adicionar alguma. A convenção no Ecto é pluralizar o nome das
tabelas, portanto, para essa aplicação precisaremos de uma tabela `people`,
então vamos começar nossas migrações assim.

A melhor maneira de criar migrações é a tarefa `ecto.gen.migration <nome>`,
então em nosso caso vamos usar:

```shell
$ mix ecto.gen.migration create_people
``` 
Isso irá gerar um novo arquivo na pasta `priv/repo/migrations` contendo uma
timestamp no nome. Se navegarmos para esse diretório e abrirmos a migração,
veremos algo assim:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Vamos começar modificando a função `change/0` para criar uma nova tabela
`people` com os campos `name` (nome) e `age` (idade):

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string, null: false
      add :age, :integer, default: 0
    end
  end
end
```

Você também pode ver acima que definimos o tipo de dados das colunas.
Adicionalmente, nós incluímos `null: false` e `default: 0` como opções.

Agora vamos rodar nossa migração:

```shell
$ mix ecto.migrate
```

### Esquemas
Agora que criamos nossa tabela inicial, precisamos dizer mais sobre ela ao
Ecto, e parte de como fazemos isso é através de esquemas. Um esquema é um
módulo que define um mapeando dos campos de uma tabela.

Enquanto nas tabelas utilizamos o plural, no esquema tipicamente se utiliza
o singular. Então criamos um esquema `Person` para nossa tabela.

Criamos ele em `lib/friends/person.ex`

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Aqui você pode ver que o módulo `Friends.Person` diz ao Ecto que esse esquema
se refere à tabela `people` e que temos duas colunas: `name` que é uma string
e `age`, que é um inteiro de padrão `0`.

Vamos dar uma olhada em nosso esquema abrindo `iex -S mix` e criando uma nova
pessoa:

```elixir
iex> %Friends.Person{}
%Friends.Person{
  __meta__: #Ecto.Schema.Metadata<:built, "people">,
  age: 0,
  id: nil,
  name: nil
}
```

Como esperado, recebemos uma nova `Person` com o valor padrão aplicado a `age`.
Agora, vamos criar uma pessoa "real":

```elixir
iex> person = %Friends.Person{name: "Tom", age: 11}
person = %Friends.Person{name: "Tom", age: 11}
%Friends.Person{
  __meta__: #Ecto.Schema.Metadata<:built, "people">,
  age: 11,
  id: nil,
  name: "Tom"
}
```

Como esquemas são apenas structs, podemos interagir com eles da maneira que
estamos habituados:

```elixir
iex> person.name
"Tom"
iex> Map.get(person, :name)
"Tom"
iex> %{name: name} = person
%Friends.Person{
  __meta__: #Ecto.Schema.Metadata<:built, "people">,
  age: 11,
  id: nil,
  name: "Tom"
}
iex> name
"Tom"
```

De maneira similar, podemos atualizar nossos esquemas como poderíamos fazer com
qualquer outro map ou struct em Elixir:

```elixir
iex> %{person | age: 18}
%Friends.Person{
  __meta__: #Ecto.Schema.Metadata<:built, "people">,
  age: 18,
  id: nil,
  name: "Tom"
}
iex> Map.put(person, :name, "Jerry"}
%Friends.Person{
  __meta__: #Ecto.Schema.Metadata<:built, "people">,
  age: 11,
  id: nil,
  name: "Jerry"
}
```

Em nossa próxima lição, sobre changesets, iremos dar uma olhada em como
validar as nossas mudanças e, finalmente, em como fazer elas persistir no banco
de dados.

