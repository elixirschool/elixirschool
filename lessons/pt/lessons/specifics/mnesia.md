%{
  version: "1.2.0",
  title: "Mnesia",
  excerpt: """
  Mnesia é um sistema de gestão de banco de dados em tempo real de alto tráfego.
  """
}
---

## Visão Geral

Mnesia é um sistema de banco de dados (DBMS) que vem acompanhado da Runtime do Erlang, e por isso podemos utilizar naturalmente com Elixir. 
O *modelo de dados híbrido relacional e de objeto* do Mnesia é o que o torna adequado para o desenvolvimento de aplicações distribuídas de qualquer escala.

## Quando Usar

Quando usar uma determinada peça de tecnologia é muitas vezes um exercício confuso. 
Se você puder responder "sim" a qualquer uma das seguintes perguntas, então esta é uma boa indicação para usar Mnesia ao invés do ETS ou DETS.

  - Eu preciso reverter transações?
  - Preciso de uma sintaxe fácil de utilizar na leitura e escrita de dados?
  - Devo armazenar dados em vários nós, em vez de um?
  - Preciso escolher onde armazenar informações (RAM ou disco)?

## Schema

Como Mnesia faz parte do núcleo do Erlang, ao invés de Elixir, temos que acessá-lo com a sintaxe de dois pontos (Ver lição: [Erlang Interoperability](../../advanced/erlang/)) como a seguir:

```elixir

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

Para esta lição, vamos tomar a última abordagem quando se trabalha com a API Mnesia.
`Mnesia.create_schema/1` inicializa um novo schema vazio e passa em uma lista de nós.
Neste caso, estamos passando o nó associado com a nossa sessão IEx.

## Nós

Uma vez que executar o comando`Mnesia.create_schema([node()])` via IEx, você deve ver uma pasta chamada **Mnesia.nonode@nohost** ou similar no seu diretório de trabalho atual.
Você pode estar se perguntando o que o **nonode@nohost** significa já que não nos deparamos com isso antes. 
Vamos dar uma olhada.

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

Quando passamos a opção `--help` para IEx a partir da linha de comando, nos é apresentado todas as opções possíveis. 
Podemos ver que existe opção `--name` e `--sname` para atribuição de informações para nós.
Um nó é apenas uma Máquina Virtual do Erlang lidando com suas próprias comunicações, garbage collection, processamento agendado, memória e muito mais.
O nó está sendo nomeado como **nonode@nohost** simplesmente por padrão.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Como podemos ver agora, o nó que estamos executando é um átomo chamado `:"learner@elixirschool.com"`. 
Se nós executarmos `Mnesia.create_schema([node()])` novamente, nós iremos ver que ela criou uma outra pasta chamada **Mnesia.learner@elixirschool.com**.
O propósito disto é bem simples. 
Nós em Erlang são usados para conectar a outros nós para compartilhar (distribuir) informação e recursos.
Isto não tem que estar limitado a mesma máquina e pode comunicar através de LAN, internet, etc.

## Iniciando Mnesia

Agora que temos o conhecimento básico e criação do banco de dados, estamos agora em posição de iniciar o Mnesia DBMS com o comando `Mnesia.start/0`.

```elixir
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```
A função `Mnesia.start/0` é assíncrona. Ela inicia a inicialização das tabelas existentes e retorna o átomo `:ok`. Caso seja necessário realizar algumas ações em uma tabela existente logo após iniciar o Mnesia, precisaremos chamar a função `Mnesia.wait_for_tables/2`. Ela irá suspender o chamador até que as tabelas sejam inicializadas. Veja o exemplo na seção [Inicialização de dados e migração](#inicialização-de-dados-e-migração).

Vale a pena manter em mente que quando executando um sistema distribuído com dois ou mais nós participando, a função `Mnesia.start/1` deve ser executada em todos os nós participantes.

## Criando Tabelas

A função `Mnesia.create_table/2` é usada para criar tabelas dentro do nosso banco de dados. 
Abaixo criamos uma tabela chamada `Person`, e em seguida, passamos uma lista de palavra-chave definindo o schema da tabela.

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Nós definimos as colunas usando os átomos `:id`, `:name`, e `:job`. 
O primeiro átomo (neste caso, `:id`) é a chave primária.
Pelo menos um atributo adicional é necessário.

Quando executamos `Mnesia.create_table/2`, ele irá retornar qualquer uma das seguinte respostas:

 - `{:atomic, :ok}` se a função foi executada com êxito
 - `{:aborted, Reason}` se a função falhou

Em particular, se a tabela já existir a razão será na forma `{:already_exists, table}`, e se nós tentarmos criar esta tabela uma segunda vez nós teremos:

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## A Maneira Suja

Primeiro de tudo, vamos olhar para a maneira suja de leitura e escrita em uma tabela no Mnesia. 
Isso geralmente deve ser evitado, pois o sucesso não é garantido, mas deve nos ajudar a aprender e tornar-se confortável trabalhando com Mnesia.
Vamos adicionar algumas entradas para nossa tabela **Person**.

```elixir
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

... e para recuperar as entradas podemos usar `Mnesia.dirty_read/1`:

```elixir
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

Se nós tentarmos consultar um registro que não existe, Mnesia irá responder com uma lista vazia.

## Transações

Tradicionalmente nós usamos **transações** para encapsular nossas leituras no nosso banco de dados.
Transações são uma parte importante para concepção de sistemas altamente distribuídos e tolerantes a falhas.
Uma *transação* no Mnesia é um mecanismo através do qual uma série de operações da base de dados pode ser executada como um bloco funcional. 
Primeiro criamos uma função anônima, neste caso `data_to_write` e em seguida, passamos esta função para `Mnesia.transaction`.

```elixir
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
Com base neste mensagem de transação, podemos seguramente assumir que nós escrevemos os dados para a nossa tabela `Person`. 
Vamos usar uma transação para ler a partir do banco de dados agora para ter certeza.
Usaremos `Mnesia.read/1` para ler a partir do banco de dados, mais uma vez de dentro de uma função anônima.

```elixir
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

Note que se você quiser atualizar dados, somente precisa chamar `Mnesia.write/1` com a mesma chave de um registro existente. 
Portanto, para atualizar o registro para Hans, você pode fazer o seguinte:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## Usando índices

Mnesia suporta índices em colunas não chaves, e dados podem ser então consultados usando estes índices. 
Dessa forma podemos adicionar um índice na coluna `:job` da tabela `Person`:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

O resultado é similar ao retornado por `Mnesia.create_table/2`:

- `{:atomic, :ok}` se a função executar com sucesso
- `{:aborted, Reason}` se a função falhar

Em particular, se o índice já existir, a razão será na forma `{:already_exists, table, attribute_index}`. Assim, se tentarmos adicionar este índice uma segunda vez teremos:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

Uma vez que o índice tenha sido criado com sucesso, nós podemos usá-lo para buscar uma lista de todos os diretores:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Combinação e seleção

Mnesia suporta consultas complexas para recuperar dados de uma tabela na forma de combinação e funções de seleção ad-hoc.

A função `Mnesia.match_object/1` retorna todos os registros que combinem com o padrão informado. 
Se qualquer coluna na tabela tiver índices, estes podem ser usados para tornar a busca mais eficiente.
Use o átomo especial `:_` para identificar colunas que não devem participar da combinação.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

A função `Mnesia.select/2` permite que você especifique uma consulta customizada usando qualquer operador ou função da linguagem Elixir (ou Erlang, para esse efeito).
Vamos olhar um exemplo que seleciona todos os registros que contém uma chave que é maior que 3:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

Vamos analisar isto. 
O primeiro atributo é a tabela, `Person`, e o segundo atributo é uma tripla da forma `{match, [guard], [result]}`:

- `match` é o mesmo que você passaria para a função `Mnesia.match_object/1`. Entretanto, note os átomos especiais `:"$n"` que especificam parâmetros posicionais que são usados no restante da consulta
- a lista `guard` é uma lista de tuplas que especifica quais funções guarda aplicar, neste caso a função integrada `:>` (maior que) com o primeiro parâmetro posicional `:"$1"` e a constante `3` como atributos
- a lista `result` que é a lista de campos que serão retornados pela consulta, na forma de parâmetros posicionais do átomo especial `:"$$"` para referenciar todos os campos. Você poderia usar `[:"$1", :"$2"]` para retornar os primeiros dois campos ou `[:"$$"]` para retornar todos os campos

Para mais detalhes, veja [a documentação para select/2 do Mnesia Erlang](http://erlang.org/doc/man/mnesia.html#select-2).

## Inicialização de dados e migração

A cada evolução de software, virá a hora quando você precisará atualizar o software e migrar os dados armazenados em seu banco de dados.
Por exemplo, talvez precisaremos adicionar a coluna `:age` em nossa tabela `Person` na v2 da nossa aplicação. 
Nós não podemos criar a tabela `Person` uma vez que ela já foi criada, mas podemos transformá-la. 
Para isso precisamos saber quando transformar, o qual podemos fazer quando estamos criando a tabela. 
Para fazer isto, podemos usar a função `Mnesia.table_info/2` para buscar a estrutura atual da tabela e a função `Mnesia.transform_table/3` para transformá-la na nova estrutura.

O código abaixo faz isto através da implementação da seguinte lógica:

* Cria a tabela com os atributos da v2: `[:id, :name, :job, :age]`
* Trata o resultado da criação:
  * `{:atomic, :ok}`: inicializa a tabela criando índices em `:job` e `:age`
  * `{:aborted, {:already_exists, Person}}`: verifica quais são os atributos na tabela atual e age de acordo:
    * se é a lista v1 (`[:id, :name, :job]`), transforma a tabela dando uma idade de 21 anos para todos e adiciona um novo índice em `:age`
    * se é a lista v2, não faz nada
    * se é algo diferente, descarta

Se estivermos executando alguma ação nas tabelas existentes logo após iniciar o Mnesia com `Mnesia.start/0`, essas tabelas podem não ser inicializadas e acessíveis. Nesse caso, devemos usar a função [`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2). Ela suspenderá o processo atual até que as tabelas sejam inicializadas ou até que o tempo limite seja atingido.

A função `Mnesia.transform_table/3` recebe como atributos o nome da tabela, a função que transforma o registro do formato antigo para o novo, e a lista de novos atributos.

```elixir
case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
  {:atomic, :ok} ->
    Mnesia.add_table_index(Person, :job)
    Mnesia.add_table_index(Person, :age)
  {:aborted, {:already_exists, Person}} ->
    case Mnesia.table_info(Person, :attributes) do
      [:id, :name, :job] ->
        Mnesia.wait_for_tables([Person], 5000)
        Mnesia.transform_table(
          Person,
          fn ({Person, id, name, job}) ->
            {Person, id, name, job, 21}
          end,
          [:id, :name, :job, :age]
          )
        Mnesia.add_table_index(Person, :age)
      [:id, :name, :job, :age] ->
        :ok
      other ->
        {:error, other}
    end
end
```
