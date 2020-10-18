---
version: 1.1.1
title: Erlang Term Storage (ETS)
---

Erlang Term Storage, comumente referenciado como ETS, é um poderoso mecanismo de armazenamento, incorporado no OTP e disponível para uso no Elixir. Nesta lição iremos ver como interagir com ETS e como podemos usá-lo nas nossas aplicações.

{% include toc.html %}

## Visão Geral

ETS é um mecanismo de armazenamento em memória robusto para objetos do Elixir e do Erlang que já vem incluído. ETS é capaz de armazenar grandes quantidades de dados e oferecer um tempo constante para acesso aos dados.

Tabelas em ETS são criadas por processos individuais. Quando um processo proprietário termina suas tabelas são destruídas. Por padrão ETS está limitado a 1400 tabelas por cada nó.

## Criando Tabelas

Tabelas são criadas usando `new/2`, que aceita como parâmetros o nome da tabela, uma série de opções, e retorna um identificador de tabela que podemos usar nas operações subsequentes.

Para o nosso exemplo, iremos criar uma tabela para armazenar e buscar usuários pelos seus apelidos:

```elixir
iex> table = :ets.new(:user_lookup, [:set, :protected])
8212
```

Tal como GenServers, existe um mecanismo para acessar tabelas ETS usando nome em vez de identificador. Para fazer isso, precisamos incluir `:named_table` e assim podemos acessar nossa tabela diretamente pelo nome:

```elixir
iex> :ets.new(:user_lookup, [:set, :protected, :named_table])
:user_lookup
```

### Tipos de Tabelas

Existem quatro tipos de tabelas disponíveis no ETS:

+ `set` — Este é o tipo de tabela padrão. Um valor para cada chave. Chaves são únicas.
+ `ordered_set` — Igual ao `set` mas ordenado por termo Erlang/Elixir. É importante notar que comparação de chave é diferente dentro do `ordered_set`. Chaves não devem coincidir desde que sejam iguais. 1 e 1.0 são considerados iguais.
+ `bag` — Muitos objetos por cada chave mas apenas uma instância de cada objeto por cada chave.
+ `duplicate_bag` — Muitos objetos por cada chave; chaves duplicadas são permitidas.

### Controle de Acesso

Controle de acesso no ETS é semelhante ao controle de acesso dentro de módulos:

+ `public` - Leitura/Escrita disponíveis para todos os processos.
+ `protected` - Leitura disponível para todos os processos. Escrita disponível apenas para o proprietário. É o padrão.
+ `private` - Leitura/Escrita limitado ao proprietário do processo.

## Race Conditions

Se mais de um processo pode escrever em uma tabela - através de acesso `:public` ou por mensagens para o processo dono - race conditions são possíveis. Por exemplo, dois processos leem um contador de valor `0`, incrementam ele, e escrevem `1`; o resultado final reflete apenas um único incremento.

Para contadores especificamente, [:ets.update_counter/3](http://erlang.org/doc/man/ets.html#update_counter-3) fornece leitura e escrita atômicas. Para outros casos, pode ser necessário que o processo dono do execute operações atômicas customizadas em resposta à mensagens recebidas, como "adicione esse valor à lista na chave `:results`".

## Inserindo dados

ETS não possui esquema (`schema`). A única limitação é que dados devem ser armazenados como uma tupla onde o seu primeiro elemento é a chave. Para adicionar novos dados podemos usar `insert/2`:

```elixir
iex> :ets.insert(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
```

Quando usamos `insert/2` com um `set` ou `ordered_set` dados existentes serão substituídos. Para evitar isso, existe o `insert_new/2` que retorna `false` para chaves existentes:

```elixir
iex> :ets.insert_new(:user_lookup, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
false
iex> :ets.insert_new(:user_lookup, {"3100", "", ["Elixir", "Ruby", "JavaScript"]})
true
```

## Recuperando Dados

ETS oferece-nos algumas formas convenientes e flexíveis para recuperar nossos dados armazenados. Iremos ver como recuperar dados usando a chave através de diferentes formas de correspondência de padrão (*pattern matching*).

O mais eficiente, e ideal, método de recuperar dados é a busca por chave. Enquanto útil, *matching* percorre a tabela e deve ser usado com moderação especialmente para grandes conjuntos de dados.

### Pesquisa de chave

Dado uma chave, podemos usar `lookup/2` para recuperar todos os registos com esta chave:

```elixir
iex> :ets.lookup(:user_lookup, "doomspork")
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Correspondências Simples

ETS foi construído para o Erlang, logo, tenha em atenção que correspondência de variáveis pode parecer um _pouco_ desajeitado.

Para especificar uma variável no nosso *match*, usamos os *atoms* `:"$1"`, `:"$2"`, `:"$3"`, e assim por diante; o número da variável reflete a posição do resultado e não a posição do *match*. Para valores que não nos interessam usamos a variável `:_`.

Valores podem ser usados na correspondência, mas apenas variáveis farão parte do nosso resultado. Vamos juntar tudo isso e ver como funciona:


```elixir
iex> :ets.match(:user_lookup, {:"$1", "Sean", :_})
[["doomspork"]]
```

Vamos olhar outro exemplo para ver como variáveis influenciam a ordem da lista resultante:

```elixir
iex> :ets.match(:user_lookup, {:"$99", :"$1", :"$3"})
[["Sean", ["Elixir", "Ruby", "Java"], "doomspork"],
 ["", ["Elixir", "Ruby", "JavaScript"], "3100"]]
```

O que se queremos nosso objeto original e não uma lista? Podemos usar `match_object/2`, que independentemente das variáveis retorna nosso objeto inteiro:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

iex> :ets.match_object(:user_lookup, {:_, "Sean", :_})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

### Pesquisa Avançada

Aprendemos sobre casos simples de fazer *match*, mas o que se quisermos algo mais parecido a uma consulta SQL? Felizmente existe uma sintaxe mais robusta disponível para nós. Para pesquisar nossos dados com `select/2` precisamos construir uma lista de tuplas com três aridades. Estas tuplas representam o nosso padrão, zero ou mais guardas, e um formato de valor de retorno.

Nossas variáveis de correspondência e mais duas novas variáveis, `:"$$"` e `:"$_"` podem ser usadas para construir o valor de retorno. Estas novas variáveis são atalhos para o formato do resultado; `:"$$"` recebe resultados como listas e `:"$_"` o objeto do dado original.

Vamos pegar um dos nossos exemplos `match/2` anterior e transforma-lo num `select/2`:

```elixir
iex> :ets.match_object(:user_lookup, {:"$1", :_, :"$3"})
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]

{% raw %}iex> :ets.select(:user_lookup, [{{:"$1", :_, :"$3"}, [], [:"$_"]}]){% endraw %}
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]},
 {"3100", "", ["Elixir", "Ruby", "JavaScript"]}]
```

Apesar do `select/2` um controle mais fino sobre o que e como recuperamos registros, a sintaxe é um bastante hostil e tende a ser pior. Para lidar com isso, o módulo ETS inclui `fun2ms/1`, para transformar as funções em *match_specs*. Com `fun2ms/1` podemos criar consultas usando uma sintaxe de função mais familiar.

Vamos usar `fun2ms/1` e `select/2` para encontrar todos os usuários com 2 ou mais línguas:

```elixir
iex> fun = :ets.fun2ms(fn {username, _, langs} when length(langs) > 2 -> username end)
{% raw %}[{{:"$1", :_, :"$2"}, [{:>, {:length, :"$2"}, 2}], [:"$1"]}]{% endraw %}

iex> :ets.select(:user_lookup, fun)
["doomspork", "3100"]
```

Quer aprender mais sobre a especificação `match`? Confira a documentação oficial do Erlang para [match_spec](http://www.erlang.org/doc/apps/erts/match_spec.html).

## Eliminando Dados

### Removendo Registros

Eliminar termos é tão simples como `insert/2` e `lookup/2`. Com `delete/2` precisamos apenas da nossa tabela e a chave. Isso elimina tanto a chave como o seu respectivo valor:

```elixir
iex> :ets.delete(:user_lookup, "doomspork")
true
```

### Removendo Tabelas

Tables ETS não são lixo coletáveis, a menos que o processo pai seja terminado. As vezes poderá ser necessário eliminar a tabela inteira sem terminar o processo pai. Para isso podemos usar `delete/1`:

```elixir
iex> :ets.delete(:user_lookup)
true
```

## Exemplos de uso do ETS

Tendo em conta o que aprendemos acima, vamos juntar tudo e construir um simples *cache* para operações pesadas. Iremos implementar uma função `get/4` que recebe um módulo, uma função, argumentos, e opções. Por enquanto a única opção com que iremos nos preocupar é `:ttl`.

Para este exemplo estamos assumindo que a tabela ETS foi criada como parte de um outro processo, tal como um supervisor:

```elixir
defmodule SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  defp check_freshness({mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
```

Para demonstrar o uso do cache, iremos usar a função que retorna a hora do sistema e um TTL de 10 segundos. Tal como veremos no exemplo abaixo, obtemos o resultado em cache até que o valor expire:

```elixir
defmodule ExampleApp do
  def test do
    :os.system_time(:seconds)
  end
end

iex> :ets.new(:simple_cache, [:named_table])
:simple_cache
iex> ExampleApp.test
1451089115
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
iex> ExampleApp.test
1451089123
iex> ExampleApp.test
1451089127
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089119
```

Depois de 10 segundos se não tentarmos novamente deveremos receber um novo resultado:

```elixir
iex> ExampleApp.test
1451089131
iex> SimpleCache.get(ExampleApp, :test, [], ttl: 10)
1451089134
```

Como podes ver, podemos implementar um sistema de cache rápido e escalável sem nenhuma dependência externa e isso é apenas um de muitos casos de uso para ETS.

## ETS baseado em disco

Agora sabemos que ETS é para armazenamento em memória, mas o que fazer se precisarmos de armazenamento em disco? Para isso temos o Armazenamento Baseado em Disco ou apenas DETS (*Disk Based Term Storage*). Os APIs ETS e DETS são intercambiáveis a exceção de quantas tabelas são criadas. DETS depende de `open_file/2` e não requer a opção `:named_table`:

```elixir
iex> {:ok, table} = :dets.open_file(:disk_storage, [type: :set])
{:ok, :disk_storage}
iex> :dets.insert_new(table, {"doomspork", "Sean", ["Elixir", "Ruby", "Java"]})
true
iex> select_all = :ets.fun2ms(&(&1))
[{:"$1", [], [:"$1"]}]
iex> :dets.select(table, select_all)
[{"doomspork", "Sean", ["Elixir", "Ruby", "Java"]}]
```

Se saires do `iex` e olhares no seu diretório local, verás um arquivo novo `disk_storage`:

```shell
$ ls | grep -c disk_storage
1
```

Uma última coisa a notar é que DETS não suporta `ordered_set` como ETS, apenas `set`, `bag`, e `duplicate_bag`.
