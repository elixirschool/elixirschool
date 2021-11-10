%{
  version: "1.0.2",
  title: "IEx Helpers",
  excerpt: """
  
  """
}
---

## Visão Geral

Assim que você começar a trabalhar com Elixir, IEx será o seu melhor amigo. Ele é um REPL, mas possui muitas funcionalidades avançadas que podem tornar a vida mais fácil, seja explorando um novo código ou desenvolvendo seu próprio trabalho a medida que avança. Há uma enorme quantidade de helpers embutidos que nós iremos detalhar nesta lição.

### Autocompletar

Quando trabalhando no shell, você talvez com frequência se encontre usando um novo módulo com o qual não está familiarizado. Para entender um pouco do que está disponível para você, a funcionalidade de autocompletar é maravilhosa. Simplesmente digite o nome de um módulo seguido por `.` então pressione `Tab`:


```elixir
iex> Map. # pressione Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

E agora sabemos as funções que temos e seus números de argumentos!

### .iex.exs

Toda vez que o IEx inicia, ele irá procurar por um arquivo de configuração `.iex.exs`. Se não estiver presente no diretório atual, então o (`~/.iex.exs`) do diretório home do usuário será usado como alternativa.

Opções de configurações e código definido dentro deste arquivo estarão disponíveis para nós quando o shell do IEx iniciar. Por exemplo, se quiséssemos alguma função helper disponível no IEx, poderíamos abrir o arquivo `.iex.exs` e fazer algumas mudanças.

Vamos começar adicionando um módulo com alguns funções auxiliares.

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Agora quando executamos o IEx teremos o IExHelpers módulo disponível desde o início. Abra o IEx e vamos experimentar nossos novos helpers.

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Como podemos ver não precisamos fazer nada de especial para requerer ou importar nossos helpers, IEx trata disso para nós.

### h

`h` é uma das mais úteis ferramentas que o Elixir shell nos dá.
Devido ao fantástico suporte de primeira classe da linguagem para documentação, as docs para qualquer código podem ser visualizadas usando este helper.
Para vê-lo em ação é simples:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

E agora podemos até combinar isso com as funcionalidades de autocompletar do nosso shell.
Imagine que estivéssemos explorando Map pela primeira vez:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Como podemos ver, fomos não só capazes de encontrar quais funções estavam disponíveis como parte do módulo, mas fomos capazes de acessar documentação individual de uma função, muitas das quais incluem exemplo de uso.

### i

Vamos colocar um pouco do nosso conhecimento adquirido empregando o uso do `h` para aprender um pouco mais sobre o `i` helper:

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Agora nós temos bastante informação sobre o `Map`, incluindo onde seu código-fonte está salvo e os módulos que ele faz referência.
Isto é bastante útil ao explorar tipos de dados personalizados e externos, e novas funções.

Os cabeçalhos individuais podem ser densos, mas em um alto nível podemos coletar algumas informações relevantes:

- É um tipo de dado atom
- Onde o código-fonte está
- A versão e opções de compilação
- Uma descrição geral
- Como acessá-lo
- Quais outros módulos são referenciados

Isto nos dá muito para trabalhar e é melhor que seguir às cegas.

### r

Se quisermos recompilar um módulo em particular, podemos usar o `r` helper. Vamos dizer que mudamos algum código e queremos executar uma nova função que adicionamos. Para fazermos isto precisamos salvar nossas alterações e recompilar com r:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### t

O `t` helper nos diz sobre Tipos disponíveis em um dado módulo:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

E agora sabemos que o `Map` define os tipos key e value em sua implementação.
Se formos olhar no fonte do `Map`:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```
Isto é um exemplo simples, declarando que keys e values por implementação pode ser de qualquer tipo, mas é útil saber disto.

Com a aplicação de todos estes helpers embutidos podemos facilmente explorar o código e aprender mais sobre como as coisas funcionam. IEx é uma ferramenta bastante poderosa e robusta que dá poder aos desenvolvedores. Com essas ferramentas em nossa caixa de ferramentas, explorar e construir pode ser ainda mais divertido!
