---
layout: page
title: Mnesia
category: specifics
order: 5
lang: pt
---

Mnesia é um sistema de gestão de banco de dados em tempo real de alto tráfego.

## Sumário

- [Visão Geral](#visao-geral)
- [Quando Usar](#quando-usar)
- [Schema](#schema)
- [Nós](#nos)
- [Iniciando Mnesia](#iniciando-mnesia)
- [Criando Tabelas](#criando-tabelas)
- [A Maneira Suja](#a-maneira-suja)
- [Transações](#transacoes)


## <a name="visao-geral"></a> Visão Geral

Mnesia é um sistema de banco de dados (DBMS) que vem acompanhado da Runtime do Erlang, e por isso podemos utilizar naturalmente com Elixir. O *modelo de dados híbrido relacional e de objeto* do Mnesia é o que o torna adequado para o desenvolvimento de aplicações distribuídas de qualquer escala.

## Quando Usar

Quando usar uma determinada peça de tecnologia é muitas vezes um exercício confuso. Se você puder responder "sim" a qualquer uma das seguintes perguntas, então esta é uma boa indicação para usar Mnesia junto a ETS ou DETS.

  - Eu preciso reverter transações?
  - Preciso de uma sintaxe fácil de utilizar na leitura e escrita de dados?
  - Devo armazenar dados em vários nós, em vez de um?
  - Preciso escolher onde armazenar informações (RAM ou disco)?

## Schema

Como Mnesia faz parte do núcleo do Erlang, ao invés de Elixir, temos que acessá-lo com a sintaxe de dois pontos (Ver lição: [Erlang Interoperability](https://elixirschool.com/lessons/advanced/erlang/)) como a seguir:

```shell

iex> :mnesia.create_schema([node()])

# or if you prefer the Elixir feel...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])

```

Para esta lição, vamos tomar a última abordagem quando se trabalha com a API Mnesia. `Mnesia.create_schema/1` inicializa um novo schema vazio e passa em uma lista de nós. Neste caso, estamos passando o nó associado com a nossa sessão IEx.

## <a name="nos"></a> Nós

Uma vez que executar o comando`Mnesia.create_schema([node()])` via IEx, você deve ver uma pasta chamada **Mnesia.nonode@nohost** ou similar no seu diretório de trabalho atual. Você pode estar se perguntando o que o **nonode@nohost** significa já que não nos deparamos com isso antes. Vamos dar uma olhada.

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

Quando passamos a opção `--help` para IEx a partir da linha de comando, nos é apresentado todas as opções possíveis. Podemos ver que existe opção `--name` e `--sname` para atribuição de informações para nós. Um nó é apenas uma Máquina Virtual do Erlang lidando com suas próprias comunicações, garbage collection, processamento agendado, memória e muito mais. O nó está sendo nomeado como **nonode@nohost** simplesmente por padrão.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP 18 [erts-7.2.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir (1.2.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Como podemos ver agora, o nó que estamos executando é um átomo chamado `:"learner@elixirschool.com"`. Se nós executarmos `Mnesia.create_schema([node()])` novamente, nós iremos ver que ele criou uma outra pasta chamada **Mnesia.learner@elixirschool.com**. O propósito disto é bem simples. Nós em Erlang são usados para conectar a outros nós para compartilhar (distribuir) informação e recursos. Isto não tem que estar limitado a mesma máquina e pode comunicar através de LAN, internet, etc.

## Iniciando Mnesia

Agora que temos o conhecimento básico e criação do banco de dados, estamos agora em posição de iniciar o Mnesia DBMS com o comando ```Mnesia.start/0```.

```shell
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node])
:ok
iex> Mnesia.start()
:ok
```

Vale a pena manter em mente que quando executando um sistema distribuído com dois ou mais nós participando, a função `Mnesia.start/1` deve ser executada em todos os nós participantes.

## Criando Tabelas

A função `Mnesia.create_table/2` é usada para criar tabelas dentro do nosso banco de dados. Abaixo criamos uma tabela chamada `Person`, e em seguida, passamos uma lista de palavra-chave definindo o schema da tabela.

```shell
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```
Nós definimos as colunas usando os átomos `:id`, `:name`, e `:job`. Quando executamos `Mnesia.create_table/2`, ele irá retornar qualquer uma das seguinte respostas:

 - `{atomic, ok}` se a função foi executada com êxito
 - `{aborted, Reason}` se a função falhou

## A Maneira Suja

Primeiro de tudo, vamos olhar para a maneira suja de leitura e escrita em uma tabela no Mnesia. Isso geralmente deve ser evitado, pois o sucesso não é garantido, mas deve nos ajudar a aprender e tornar-se confortável trabalhando com Mnesia. Vamos adicionar algumas entradas para nossa tabela **Person**.

```shell
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

... e para recuperar as entradas podemos usar `Mnesia.dirty_read/1`:

```shell
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


## <a name="transacoes"></a> Transações

Tradicionalmente nós usamos **transações** para encapsular nossas leituras no nosso banco de dados. Transações são uma parte importante para concepção de sistemas altamente distribuídos e tolerantes a falhas. Uma *transação* no Mnesia é um mecanismo através do qual uma série de operações da base de dados pode ser executada como um bloco funcional. Primeiro criamos uma função anônima, neste caso `data_to_write` e em seguida, passamos esta função para `Mnesia.transaction`.

```shell
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
Com base neste mensagem de transação, podemos seguramente assumir que nós escrevemos os dados para a nossa tabela `Person`. Vamos usar uma transação para ler a partir do banco de dados agora para ter certeza. Usaremos `Mnesia.read/1` para ler a partir do banco de dados, mais uma vez de dentro de uma função anônima.

```shell
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```
