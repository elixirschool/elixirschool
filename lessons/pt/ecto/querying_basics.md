%{
  version: "1.2.0",
  title: "Consultas",
  excerpt: """
  
  """
}
---

Nesta lição, estaremos construindo a aplicação `Friends` e o catálogo de filmes que configuramos na [lição anterior](./associations).

## Buscando Registros com `Ecto.Repo`

Lembre-se de que um "repositório" no Ecto é mapeado para um armazenamento de dados, como nosso banco de dados Postgres.
Toda a comunicação com o banco de dados será feita usando este repositório.

Podemos realizar simples consultas diretamente em nosso `Friends.Repo` com a ajuda de algumas funções.

### Buscando Registros por ID

Nós podemos usar a função `Repo.get/3` para buscar um registro vindo do banco de dados pelo seu ID. Essa função requer dois argumentos: uma estrutura "queryable" (consultável) e o ID do registro a ser recuperado do banco de dados. Ela retorna uma struct descrevendo o registro encontrado, caso exista. Retorna `nil` se nenhum registro for encontrado.

Vamos dar uma olhada em um exemplo. Abaixo, vamos pegar o filme com o ID 1:

```elixir
iex> alias Friends.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Note que o primeiro argumento que fornecemos a `Repo.get/3` foi nosso módulo `Movie`. `Movie` é "queryable" pois o módulo usa `Ecto.Schema` e define um `schema` para sua estrutura de dados. Isso dá a `Movie` acesso ao protocolo `Ecto.Queryable`. Esse protocolo converte uma estrutura de dados em um `Ecto.Query`. Ecto queries são usadas para recuperar dados de um repositório. Mais sobre consultas depois.

### Buscando Registros por Atributo

Também podemos buscar registros que atendam a um determinado critério utilizado a função `Repo.get_by/3`. Essa função requer dois argumentos: a estrutura de dados "queryable" (consultável) e a cláusula com a qual queremos consultar. `Repo.get_by/3` retorna um único resultado do repositório. Vamos ver um exemplo:

```elixir
iex> Repo.get_by(Movie, title: "Ready Player One")
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Se quisermos escrever consultas mais complexas, ou se quisermos retornar _todos_ os registros que atendam a uma determinada condição, precisamos usar o módulo `Ecto.Query`.

## Escrevendo Consultar com `Ecto.Query`

O módulo `Ecto.Query` nos fornece a DSL de consulta que podemos usar para criar consultas para recuperar dados do repositório da aplicação.

### Criando Consultas baseadas em palavras-chave com `Ecto.Query.from/2`

Podemos criar uma consulta com a função `Ecto.Query.from/2`. Esta função recebe dois argumentos: uma expressão e uma lista opcional de palavras-chave. Vamos criar a consulta mais simples para selecionar todos os filmes do nosso repositório:

```elixir
import Ecto.Query
query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

Para executar nossa consulta, usamos a função `Repo.all/2`. Essa função aceita um argumento obrigatório de uma consulta Ecto e retorna todos os registros que atendem às condições da consulta.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### Consultas bindingless com `from`

O exemplo acima não tem a parte mais divertida das declarações (statements) SQL. Nós frequentemente queremos não apenas buscar campos específicos ou filtrar registros por alguma condição. Vamos carregar `title` e `tagline` de todos os filmes que tenham o título `"Ready Player One"`:

```elixir
iex> query = from(Movie, where: [title: "Ready Player One"], select: [:title, :tagline])
#Ecto.Query<from m0 in Friends.Movie, where: m0.title == "Ready Player One",
 select: [:title, :tagline]>

iex> Repo.all(query)
SELECT m0."title", m0."tagline" FROM "movies" AS m0 WHERE (m0."title" = 'Ready Player One') []
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    id: nil,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Note que a estrutura (struct) retornada tem somente os campos `tagline` e `title` – esse é o resultado da parte do nosso `select:`.

Consultas como esta são chamadas *bindingless*, porque elas são simples o suficiente para não requerer bindings.

#### Bindings em consultas

Até agora, nós usamos um módulo para implementar o protocolo `Ecto.Queryable` (ex: `Movie`) como o primeiro argumento da macro `from`. No entanto, nós podemos usar também a expressão `in`, assim:

```elixir
iex> query = from(m in Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

Nesse caso, nós chamamos `m` de *binding* (atribuição). Bindings são extremamente úteis, porque eles permitem que nós referenciemos módulos em outras partes de uma consulta (query). Vamos selecionar os títulos de todos os filmes que tenham o `id` menor que `2`:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

Um ponto muito importante aqui é como a saída de uma consulta é alterada. Usando uma *expressão* com uma atribuição na parte do `select:` isso nos permite especificar exatamente a forma como os campos selecionados serão retornados. Nós podemos solicitar o retorno como uma tupla, por exemplo:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```

É sempre uma boa ideia começar com uma simples consulta sem atribuição (bindingless) e introduzir a atribuição sempre que você precisar referenciar sua estrutura de dados. Mais sobre atribuições (bindings) em consultas pode ser encontrado na [documentação do Ecto](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions)

### Consultas baseadas em macros

Nos exemplos acima nós usamos as palavras-chave `select:` e `where:` dentro da macro `from` para construir uma consulta (query) - essas são chamadas de *consultas baseadas em palavras-chave*. Há, no entanto, outra forma de compor consultas - baseadas em macros. Ecto fornece macros para cada palavra-chave, como `select/3` or `where/3`.

Cada macro aceita um valor *queryable* (buscável), *uma lista explícita de bindings* e a mesma expressão que você forneceu para sua consulta de palavras-chave análoga:

```elixir
iex> query = select(Movie, [m], m.title)
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

Uma boa coisa sobre macros é que elas podem trabalhar muito bem com pipes:

```elixir
iex> Movie \
...>  |> where([m], m.id < 2) \
...>  |> select([m], {m.title}) \
...>  |> Repo.all
[{"Ready Player One"}]
```

Note que para continuar escrevendo depois da quebra de linha, use o caracter `\`.

### Usando `where` com Valores Interpolados

Para usar valores interpolados ou expressões Elixir em nossas cláusulas where, precisamos usar o operador pin, `^`. Isso nos permite _fixar_ um valor para uma variável e se referir ao valor fixado, em vez de vincular essa variável.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)
%Ecto.Query<from m in Friends.Movie, where: m.title == ^"Ready Player One",
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
%Ecto.Query<from m in Friends.Movie, order_by: [desc: m.id], limit: 1>
```

Então passamos nossa consulta para a função `Repo.one/2` para obter nosso resultado:

```elixir
iex> Movie |> first() |> Repo.one()

SELECT m0."id", m0."title", m0."tagline" FROM "movies" AS m0 ORDER BY m0."id" LIMIT 1 []
%Friends.Movie{
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
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

_Não podemos_ acessar esses atores associados, a menos que os pré-carreguemos. Existem algumas maneiras diferentes de pré-carregar registros com o Ecto.

#### Pré-carregamento Com Duas Consultas

A consulta a seguir pré-carregará os registros associados em uma consulta _separada_.

```elixir
iex> Repo.all(from m in Movie, preload: [:actors])

13:17:28.354 [debug] QUERY OK source="movies" db=2.3ms queue=0.1ms
13:17:28.357 [debug] QUERY OK source="actors" db=2.4ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Podemos ver que a linha de código acima executou duas consultas no banco de dados. Um para todos os filmes e outro para todos os atores com os IDs de filme fornecidos.


#### Pré-carregamento Com Uma Consulta
Podemos reduzir nossas consultas ao banco de dados com o seguinte:

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)

13:18:52.053 [debug] QUERY OK source="movies" db=3.7ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
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
  where: a.name == "John Wayne",
  preload: [actors: a]
```

Mais sobre a instrução join daqui a pouco.

#### Pré-carregamento de Registros já Buscados

Também podemos pré-carregar os esquemas associados de registros que já foram consultados no banco de dados.

```elixir
iex> movie = Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    },
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # actors are LOADED!!
  characters: [],
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Agora podemos pedir a `movie` (filme) a lista de atores/atrizes:

```elixir
iex> movie.actors
[
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Tyler Sheridan"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Usando a Instrução Join

Podemos executar consultas que incluem instruções de junção com a ajuda da função `Ecto.Query.join/5`.

```elixir
iex> alias Friends.Character
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

A expressão `on` também pode usar uma lista de palavras-chave:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # lista de palavras-chave
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

No exemplo acima, estamos fazendo junção em um esquema Ecto, `m in Movie`. Também podemos fazer junção de uma consulta Ecto. Digamos que nossa tabela de filmes tenha uma coluna `stars`, onde armazenamos a "classificação por estrelas" do filme, um número de 1 a 5.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # lista de palavras-chave
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

A DSL Ecto Query é uma ferramenta poderosa que nos fornece tudo o que precisamos para fazer consultas complexas em bancos de dados. Com esta introdução, você terá o básico para iniciar suas consultas.
