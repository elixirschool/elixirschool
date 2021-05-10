%{
  version: "1.2.2",
  title: "Associações",
  excerpt: """
  Nessa seção vamos aprender a utilizar o Ecto para definir e trabalhar com associações entre esquemas.
  """
}
---

## Configuração

Nós vamos utilizar a mesma aplicação `Friends`, das últimas lições. Você pode referir-se a configuração [aqui](https://elixirschool.com/pt/lessons/ecto/basics) para uma breve recapitulação.

## Tipos de Associações

Existem três tipos de associações que podem ser definidas entre nossos esquemas. Vamos dar atenção ao que elas são e como implementar cada um dos tipos.

### Belongs To/Has Many

Nós estamos adicionando algumas novas entidades ao modelo de domínio da nossa aplicação Friends para que seja possível categorizar nossos filmes favoritos. Vamos iniciar com dois esquemas: `Movie` e `Character`. Vamos implementar uma relação "has many/belongs to" entre os dois: Um filme tem vários (has many) personagens e um personagem pertence a (belongs to) um filme.

#### A Migração Has Many

Vamos gerar uma migração para `Movie`:

```console
mix ecto.gen.migration create_movies
```

Abra o arquivo da migração recém gerada e defina a sua função `change`, com o intuito de criar a tabela `movies`:

```elixir
# priv/repo/migrations/*_create_movies.exs
defmodule Friends.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string
      add :tagline, :string
    end
  end
end
```

#### O Schema Has Many

Nós vamos adicionar um esquema que especifica a relação "has many" entre um filme e os seus personagens.

```elixir
# lib/friends/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

A macro `has_many/3` não adiciona dados ao banco de dados por si só. O que ela faz é utilizar uma chave estrangeira no esquema associado (`characters`) para tornar as associações de personagens de um filme disponíveis. Isso é o que nos permite realizar chamadas como `movie.characters`.

#### A migração Belongs

Agora nós estamos prontos para construir nossa migração e `schema` para `Character`. Um personagem pertence(`belongs to`) a um filme, então vamos definir uma migração que especifique o relacionamento.

Primeiro, precisamos gerar a migração:

```console
mix ecto.gen.migration create_characters
```

Para declarar que um personagem pertence a um filme, precisamos da tabela `characters` e que ela possua uma coluna `movie_id`. Nós queremos que essa coluna funcione como uma chave estrangeira. Podemos alcançar isso com a seguinte linha, na chamada para `create table/1`:

```elixir
add :movie_id, references(:movies)
```

Assim, nossa migração deve ser algo como:

```elixir
# priv/migrations/*_create_characters.exs
defmodule Friends.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### O Schema Belongs To

Nosso esquema precisa definir a relação `belongs to` entre um personagem e seu filme.

```elixir
# lib/friends/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Vamos dar uma olhada mais a fundo no que a macro `belongs_to/3` faz por nós. Além de adicionar a coluna `movie_id` ao nosso esquema, ela também nos permite acessar os esquemas de `movies` associados _através_ de `characters`. Ela utiliza a chave estrangeira para tornar o filme associado a um personagem disponível quando executamos a consulta sobre os personagens. Isso nos permite chamar `character.movie`.

Agora nós estamos prontos para executar as migrações:

```console
mix ecto.migrate
```

### Belong To/Has One

Digamos que um filme tenha um distribuidor. Por exemplo, o Netflix é o distribuidor do filme original "Bright".

Vamos definir a migração e o esquema `Distributor` com o relacionamento "belongs to". Primeiro, é preciso gerar a migração:

```console
mix ecto.gen.migration create_distributors
```

Nós devemos adicionar uma chave estrangeira de `movie_id` à migração da tabela `distributors` que acabamos de gerar, bem como um índice único _(unique)_ para garantir que um filme tenha apenas um distribuidor:

```elixir
# priv/repo/migrations/*_create_distributors.exs

defmodule Friends.Repo.Migrations.CreateDistributors do
  use Ecto.Migration

  def change do
    create table(:distributors) do
      add :name, :string
      add :movie_id, references(:movies)
    end

    create unique_index(:distributors, [:movie_id])
  end
end
```

E o esquema `Distributor` deve usar a macro `belongs_to/3` para nos permitir chamar `distributor.movie` e procurar o filme associado a um distribuidor usando esta chave estrangeira.

```elixir
# lib/friends/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Em seguida, adicionaremos o relacionamento "has one" ao esquema `Movie`:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor # Eu sou novo!
  end
end
```

A macro `has_one/3` funciona como a macro `has_many/3`. Ela usa a chave estrangeira do esquema para procurar e expor o distribuidor do filme. Isso nos permitirá chamar, por exemplo, `movie.distributor`.

Agora podemos executar nossas migrações:

```console
mix ecto.migrate
```

### Muitos para muitos(many to many)

Digamos que um filme tenha muitos atores e que um ator possa pertencer a mais de um filme. Vamos construir uma tabela de relação que faça referência a _ambos_ filmes(movies) _e_ atores(actors) para implementar esse relacionamento.

Primeiro, precisamos gerar a migração dos atores:

```console
mix ecto.gen.migration create_actors
```

Defina a migração:

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.Actors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

Vamos gerar nossa migração da tabela de relacionamento:

```console
mix ecto.gen.migration create_movies_actors
```

Vamos definir nossa migração de forma que a tabela tenha duas chaves estrangeiras. Também adicionaremos um índice exclusivo para impor pares únicos de atores e filmes:

```elixir
# priv/migrations/*_create_movies_actors.ex

defmodule Friends.Repo.Migrations.CreateMoviesActors do
  use Ecto.Migration

  def change do
    create table(:movies_actors) do
      add :movie_id, references(:movies)
      add :actor_id, references(:actors)
    end

    create unique_index(:movies_actors, [:movie_id, :actor_id])
  end
end
```

Em seguida, vamos adicionar a macro `many_to_many` ao nosso esquema `Movie`:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor
    many_to_many :actors, Friends.Actor, join_through: "movies_actors" # Eu sou novo!
  end
end
```

Finalmente, definiremos nosso esquema `Actor` com a mesma macro `many_to_many`.

```elixir
# lib/friends/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

Estamos prontos para executar nossas migrações:

```console
mix ecto.migrate
```

## Salvando Dados Associados

A maneira como salvamos registros junto dos dados associados depende da natureza do relacionamento entre os registros. Vamos começar com o relacionamento "Belongs to/has many".

### Belongs To

#### Salvando com o Ecto.build_assoc/3

Com um relacionamento "belongs to", podemos alavancar a função `build_assoc/3` do Ecto.

[`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) aceita três argumentos:

* A estrutura do registro que queremos salvar.
* O nome da associação.
* Quaisquer atributos que queremos atribuir ao registro associado que estamos salvando.

Vamos salvar um filme e um personagem associado. Primeiro, vamos criar um registro de filme:

```elixir
iex> alias Friends.{Movie, Character, Repo}
iex> movie = %Movie{title: "Ready Player One", tagline: "Something about video games"}

%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:built, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: nil,
  tagline: "Something about video games",
  title: "Ready Player One"
}

iex> movie = Repo.insert!(movie)
```

Agora vamos construir nosso personagem associado e inseri-lo no banco de dados:

```elixir
iex> character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
iex> Repo.insert!(character)
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

Observe que, como a macro `has_many/3` do esquema `Movie` especifica que um filme possui muitos `:characters`, o nome da associação que passamos como segundo argumento para `build_assoc/3` é exatamente isso: `:characters`. Podemos ver que criamos um personagem que tem seu `movie_id` definido corretamente para o ID do filme associado.

Para usar `build_assoc/3` com o intuito de salvar o distribuidor associado a um filme, adotamos a mesma abordagem de passar o _nome_ do relacionamento do filme com o distribuidor como o segundo argumento para`build_assoc/3`:

```elixir
iex> distributor = Ecto.build_assoc(movie, :distributor, %{name: "Netflix"})
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:built, "distributors">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
iex> Repo.insert!(distributor)
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "distributors">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
```

### Many to Many

#### Salvando com Ecto.Changeset.put_assoc/4

A abordagem `build_assoc/3` não funcionará para o nosso relacionamento muitos-para-muitos(many-to-many). Isso ocorre porque nem as tabelas de filme nem de ator contêm uma chave estrangeira. Em vez disso, precisamos usar o Ecto Changesets e a função `put_assoc/4`.

Supondo que já tenhamos o registro do filme que criamos acima, vamos criar um registro de ator:

```elixir
iex> alias Friends.Actor
iex> actor = %Actor{name: "Tyler Sheridan"}
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:built, "actors">,
  id: nil,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
iex> actor = Repo.insert!(actor)
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
  id: 1,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
```

Agora estamos prontos para associar nosso filme ao nosso ator por meio da tabela de relacionamento.

Primeiro, note que para trabalhar com Changesets, precisamos ter certeza de que nossa estrutura `movie` pré-carregou seus esquemas associados. Falaremos mais sobre pré-carregar dados a frente. Por enquanto, é suficiente entender que podemos pré-carregar nossas associações assim:

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
 %Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Em seguida, criaremos um conjunto de alterações para nosso registro de filme:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

Agora vamos passar nosso changeset como o primeiro argumento para [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4):

```elixir
iex> movie_actors_changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [actor])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
       %Ecto.Changeset<action: :update, changes: %{}, errors: [],
       data: %Friends.Actor<>, valid?: true>
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
```

Isso nos dá um _novo_ changeset, representando a seguinte mudança: adicione os atores nesta lista de atores ao registro de filme dado.

Por fim, atualizaremos os registros de filme e ator fornecidos usando nosso changeset mais recente:

```elixir
iex> Repo.update!(movie_actors_changeset)
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    }
  ],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Podemos ver que isso nos dá um registro de filme com o novo ator apropriadamente associado e já pré-carregado para nós em `movie.actors`.

Podemos usar essa mesma abordagem para criar um novo ator associado ao filme em questão. Em vez de passar uma estrutura de ator _salva_ para `put_assoc/4`, simplesmente passamos uma struct de ator, descrevendo um novo ator que queremos criar:

```elixir
iex> changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [%{name: "Gary"}])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<
        action: :insert,
        changes: %{name: "Gary"},
        errors: [],
        data: %Friends.Actor<>,
        valid?: true
      >
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
iex>  Repo.update!(changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Podemos ver que um novo ator foi criado com um ID "2" e os atributos que atribuímos a ele.

Na próxima seção, aprenderemos a consultar nossos registros associados.
