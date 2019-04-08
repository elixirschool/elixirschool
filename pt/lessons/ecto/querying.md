---
version: 1.0.0
title: Querying
---

{% include toc.html %}

Nesta lição, estaremos construindo o aplicativo `Example` e o catálogo de filmes que configuramos na [lição anterior](./associations)

## Buscando Registros com `Ecto.Repo`

Lembre-se de que um repositório no Ecto é mapeado para um armazenamento de dados, como nosso banco de dados Postgres.
Toda a comunicação com o banco de dados será feita usando este repositório.

Podemos realizar simples consultas diretamente em nosso `Example.Repo` com a ajuda de uma porção de funções.

### Buscando Registros por ID

Nós podemos usar a função `Repo.get/3` para carregar um registro vindo do banco de dados pelo seu ID. Essa função requer dois argumentos: uma estrutura "queryable" e o ID do registro para recuperar do banco de dados. Ela retorna uma estrutura descrevendo o registro encontrado, caso exista. Retorna `nil` se nenhum registro for encontrado.

Vamos dar uma olhada em um exemplo. Abaixo, vamos pegar o filme com o ID 1:

```elixir
iex> alias Example.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Note que o primeiro argumento que fornecemos a `Repo.get/3` foi nosso módulo `Movie`. `Movie` é "queryable" pois o módulo usa `Ecto.Schema` e define um `schema` para sua estrutura de dados. Isso dá ao `Movie` acesso ao protocolo `Ecto.Queryable`. Esse protocolo converte uma estrutura de dados em um `Ecto.Query`. Ecto queries são usadas para recuperar dados de um repositório. Mais sobre consultas depois.

### Buscando Registros por Atributo

Também podemos buscar registros que atendam a um determinado critério com a função `Repo.get_by/3`. Essa função requer dois argumentos: a estrutura de dados "queryable" e a cláusula com a qual queremos consultar. `Repo.get_by/3` retorna um único resultado do repositório. Vamos ver um exemplo: 

```elixir
iex> alias Example.Repo
iex> alias Example.Movie
iex> Repo.get_by(Movie, title: "Ready Player One")
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Se quisermos escrever consultas mais complexas, ou se quisermos retornar _todos_ registros que atendam a uma determinada condição, precisamos usar o módulo `Ecto.Query`.

## Escrevendo Consultar com `Ecto.Query`

O módulo `Ecto.Query` nos fornece a DSL de consulta que podemos usar para gravar consultas para recuperar dados do repositório da aplicação.

### Criando Consultas com `Ecto.Query.from/2`

Podemos criar uma consulta com a função `Ecto.Query.from/2`. Esta função recebe dois argumentos: uma expressão e uma lista de palavras-chave. Vamos criar uma consulta para selecionar todos os filmes do nosso repositório:

```elixir
import Ecto.Query
query = from(m in Movie, select: m)
#Ecto.Query<from m in Example.Movie, select: m>
```

Para executar nossa consulta, usamos a função `Repo.all/2`. Essa função aceita um argumento obrigatório de uma consulta Ecto e retorna todos os registros que atendem às condições da consulta.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### Usando `from` com Consultas de Palavras-chave

O exemplo acima dá ao `from/2` um argumento de uma *consulta de palavra-chave*. Quando usar `from` com uma consulta de palavra-chave, o primeiro argumento pode ser uma das duas coisas:

* Uma expressão `in` (ex: `m in Movie`)
* Um módulo que implementa o protoculo `Ecto.Queryable` (ex: `Movie`)

O segundo argumento é nossa consulta de palavra-chave `select` .

#### Usando `from` com uma Query Expression

Ao usar `from` com uma expressão de consulta, o primeiro argumento deve ser um valor que implemente o protocolo `Ecto.Queryable` (ex: `Movie`). O segundo argumento é uma expressão. Vamos ver um exemplo: 

```elixir
iex> query = select(Movie, [m], m)
#Ecto.Query<from m in Example.Movie, select: m>
iex> Repo.all(query)

06:16:20.854 [debug] QUERY OK source="movies" db=0.9ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Você pode usar expressões de consulta quando não precisar de uma instrução `in` (`m in Movie`). Você não precisa de uma declaração `in` quando não precisa de uma referência à estrutura de dados. Nossa consulta acima não requer uma referência à estrutura de dados--não estamos, por exemplo, selecionando filmes em que uma determinada condição é atendida. Portanto, não há necessidade de usar expressões `in` e consultas de palavras-chave.

### Usando Expressão `select`

Usamos a função `Ecto.Query.select/3` para especificar a parte da instrução de seleção da nossa consulta. Se quisermos selecionar apenas certos campos, podemos especificar esses campos como uma lista de átomos ou referenciando as chaves da estrutura. Vamos dar uma olhada na primeira abordagem:

```elixir
iex> query = from(Movie, select: [:title])                                            
#Ecto.Query<from m in Example.Movie, select: [:title]>
iex> Repo.all(query)

15:15:25.842 [debug] QUERY OK source="movies" db=1.3ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: nil,
    tagline: nil,
    title: "Ready Player One"
  }
]
```

Note que nós não usamos uma expressão `in` para o primeiro argumento dado à nossa função `from`. Isso porque não precisamos criar uma referência à nossa estrutura de dados para usar uma lista de palavras-chave com `select`.

Essa abordagem retorna uma estrutura apenas com o campo especificado, `title`, preenchido.

A segunda abordagem se comporta de maneira um pouco diferente. Desta vez, nós *precisamos* usar uma expressão `in`. Isso porque precisamos criar uma referência para nossa estrutura de dados para especificar a chave `title` da estrutura do filme:

```elixir
iex(15)> query = from(m in Movie, select: m.title)   
#Ecto.Query<from m in Example.Movie, select: m.title>
iex(16)> Repo.all(query)                             

15:06:12.752 [debug] QUERY OK source="movies" db=4.5ms queue=0.1ms
["Ready Player One"]
```

Observe que essa abordagem ao uso de `select` retorna uma lista contendo os valores selecionados.

### Usando Expressões `where`

Podemos usar expressões `where` para incluir cláusulas `where` em nossas consultas. Várias expressões `where` são combinadas em instruções SQL `WHERE AND`.

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One")                   
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One">
iex> Repo.all(query)

15:18:35.355 [debug] QUERY OK source="movies" db=4.1ms queue=0.1ms
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Podemos usar expressões `where` junto com `select`:

```elixir
iex> query = from(m in Movie, where: m.title == "Ready Player One", select: m.tagline)
#Ecto.Query<from m in Example.Movie, where: m.title == "Ready Player One", select: m.tagline>
iex> Repo.all(query)

15:19:11.904 [debug] QUERY OK source="movies" db=4.1ms
["Something about video games"]
```

### Usando `where` com Valores Interpolados

Para usar valores interpolados ou expressões Elixir em nossas cláusulas where, precisamos usar o operador pin, `^`. Isso nos permite _pregar_ um valor para uma variável e se referir ao valor fixado, em vez de vincular essa variável.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)            
#Ecto.Query<from m in Example.Movie, where: m.title == ^"Ready Player One",
 select: m.tagline>
iex> Repo.all(query)

15:21:46.809 [debug] QUERY OK source="movies" db=3.8ms
["Something about video games"]
```

### Obtendo o Primeiro e o Último Registro

Podemos buscar o primeiro ou último registro de um repositório usando as funções `Ecto.Query.first/2` e `Ecto.Query.last/2`.

Primeiro, vamos escrever uma expressão de consulta usando a função `first/2`:

```elixir
iex> first(Movie)
#Ecto.Query<from m in Example.Movie, order_by: [desc: m.id], limit: 1>
```

Então passamos nossa consulta para a função `Repo.one/2` para obter nosso resultado:

```elixir
iex> Movie |> first() |> Repo.one()

06:36:14.234 [debug] QUERY OK source="movies" db=3.7ms
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

A função `Ecto.Query.last/2` é usada da mesma maneira:

```elixir
iex> Movie |> last() |> Repo.one()
```

## Consulta Para Dados Associados

### Pré-carregamento

Para poder acessar os registros associados que os macros `belongs_to`,` has_many` e `has_one` nos expõem, precisamos _pré-carregar_ os esquemas associados.

Vamos dar uma olhada para ver o que acontece quando tentamos perguntar os atores associados a um filme:

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
#Ecto.Association.NotLoaded<association :actors is not loaded>
```

_Não podemos_ acessar esses atores associados, a menos que os pré-carregemos. Existem algumas maneiras diferentes de pré-carregar registros com o Ecto.

#### Pré-carregamento Com Duas Consultas

A consulta a seguir pré-carregará os registros associados em uma consulta _separada_.

```elixir
iex> import Ecto.Query
Ecto.Query
iex> Repo.all(from m in Movie, preload: [:actors])
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Podemos ver que a linha de código acima executou duas consultas ao banco de dados. Um para todos os filmes e outro para todos os atores com os IDs de filme fornecidos.


#### Pré-carregamento Com Uma Consulta
Podemos reduzir nossas consultas ao banco de dados com o seguinte:

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)  
[
  %Example.Movie{
    __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Bob"
      },
      %Example.Actor{
        __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Isso nos permite executar apenas uma chamada de banco de dados. Ele também tem o benefício adicional de nos permitir selecionar e filtrar filmes e atores associados na mesma consulta. Por exemplo, essa abordagem nos permite consultar todos os filmes em que os atores associados atendem a determinadas condições usando uma instrução `join`. Algo como:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne"
  preload: [actors: a]
```

Um pouco mais de instruções `join`.

#### Pré-carregamento de Registros já Buscados

Também podemos pré-carregar os esquemas associados de registros que já foram consultados no banco de dados.

```elixir
iex> movie = Repo.get(Movie, 1)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Example.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Example.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Bob"
    },
    %Example.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # actors are LOADED!!
  characters: [],
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Agora podemos pedir um filme para seus atores:

```elixir
iex> movie.actors
[
  %Example.Actor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Bob"
  },
  %Example.Actor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Usando a Instrução Join

Podemos executar consultas que incluem instruções de junção com a ajuda da função `Ecto.Query.join/5`.

```elixir
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Video Game Guy",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Video Game Guy"}]
```

A expressão `on` também pode usar uma lista de palavras-chave:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

No exemplo acima, estamos nos unindo em um esquema Ecto, `m in Movie`. Também podemos fazer junção de uma Ecto query. Digamos que nossa tabela de filmes tenha uma coluna `stars`, onde armazenamos a "classificação por estrelas" do filme, um número de 1 a 5.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Video Game Guy",
  select: {m.title, c.name}
```

A DSL Ecto Query é uma ferramenta poderosa que nos fornece tudo o que precisamos para fazer consultas complexas em bancos de dados. Com esta introdução, você terá o básico para iniciar suas consultas.