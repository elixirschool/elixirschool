%{
  version: "1.1.1",
  title: "StreamData",
  excerpt: """
  Uma biblioteca de testes unitários baseada em exemplos como a [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) é uma ferramenta maravilhosa para verificar se o código que você escreveu funciona da maneira que você espera.
  Entretanto, esse tipo de teste tem algumas desvantagens:

  * Pode ser fácil de perder casos de borda, já que você está testando apenas algumas poucas entradas.
  * Você pode escrever esses testes sem pensar cuidadosamente em seus requisitos.
  * Esses testes podem ser bastante verbosos quando você usa vários exemplos para uma função.

  Nessa lição, vamos explorar como [StreamData](https://github.com/whatyouhide/stream_data) pode nos ajudar a superar alguns desses problemas.
  """
}
---

## O que é StreamData?

[StreamData](https://github.com/whatyouhide/stream_data) é uma biblioteca que realiza testes sem estado (stateless), baseados em propriedade.

A biblioteca StreamData vai rodar cada teste [100 vezes por padrão](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options), usando dados aleatórios.
Quando um teste falha, a biblioteca vai tentar reduzir [(shrink)](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options) a entrada ao menor valor que causa a falha do teste.
Isso pode ser bastante útil na hora de debuggar seu código!
Se, por exemplo, uma lista de 50 elementos faz a sua função quebrar e apenas um elemento dessa lista é problemático, StreamData pode te ajudar a identificar o elemento que causa o problema.

Essa biblioteca de testes tem dois módulos principais.
[`StreamData`](https://hexdocs.pm/stream_data/StreamData.html) gera streams de dados aleatórios.
[`ExUnitProperties`](https://hexdocs.pm/stream_data/ExUnitProperties.html) permite que você rode seus testes em suas funções, usando os dados gerados como dados de entrada.

Você pode estar se perguntando como podem ser gerados dados que façam sentido para a função que você está testando, se não se sabe exatamente qual é o input esperado. Continue lendo!

## Instalando StreamData

Primeiro, crie um novo projeto Mix.
Dê uma olha em [New Projects](https://elixirschool.com/en/lessons/basics/mix/#new-projects) se precisar de ajuda.

Segundo, adicione StreamData como uma dependência no seu arquivo `mix.exs`

```elixir
defp deps do
  [{:stream_data, "~> x.y", only: :test}]
end
```

Substitua `x` e `y` pela versão mostrada nas [instruções de instalação](https://github.com/whatyouhide/stream_data#installation) da biblioteca.

Terceiro, rode o seguinte comando no seu terminal:

```shell
mix deps.get
```

## Usando StreamData

Para ilustrar os recursos da biblioteca StreamData, vamos escrever algumas funções utilitárias simples que repetem valores.
Digamos que queremos uma função tipo a [`String.duplicate/2`](https://hexdocs.pm/elixir/String.html#duplicate/2), mas que irá duplicar strings, listas ou tuplas.

### Strings

Primeiro, vamos escrever uma função que irá duplicar strings.
Quais são os requisitos para a nossa função? 

1. O primeiro argumento deve ser uma string.
Esta é a string que iremos duplicar.
2. O segundo argumento deve ser um número inteiro não negativo.
Isso vai nos dizer quantas vezes duplicaremos o primeiro argumento.
3. A função deve retornar uma string.
Esta nova string é apenas a string original, repetida zero ou mais vezes.
4. Se a string original estiver vazia, a string retornada também deve estar vazia.
5. Se o segundo argumento for `0`, a string retornada deve estar vazia.

Quando rodamos nossa função, queremos que ela se comporte assim:

```elixir
Repeater.duplicate("a", 4)
# "aaaa"
```

Elixir tem uma função chamada `String.duplicate/2` que vai cuidar disso para a gente.
Nossa nova função `duplicate/2` vai apenas delegar para essa função:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end
end
```

O caminho feliz deve ser fácil de testar com [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html).

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicate/2" do
    test "cria uma nova string, com o primeiro argumento duplicado um número específico de vezes" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end
  end
end
```

Esse, porém, dificilmente vai ser um teste abrangente.
O que deve acontecer quando o segundo argumento for `0`?
Qual deve ser a saída quando o primeiro argumento for uma string vazia?
O que significa repetir uma string vazia?
Como a função deve funcionar com caracteres UTF-8?
A função ainda vai funcionar com entradas grandes?

Poderíamos escrever mais exemplos para testar casos de borda e strings grandes.
No entanto, vamos ver se podemos usar StreamData para testar essa função com mais rigor, sem muito mais código.

```elixir
defmodule RepeaterTest do

  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "cria uma nova string, com o primeiro argumento duplicado um número específico de vezes" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do

        assert ??? == Repeater.duplicate(str, times)
      end
    end
  end
end
```

O que isso faz?

* Nós substituimos `test` por [`property`](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109).
Isso nos permite documentar a propriedade que estamos testando.
* [`check/1`](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1) é uma macro que nos permite definir os dados que vamos usar no teste.
* [`StreamData.string/2`](https://hexdocs.pm/stream_data/StreamData.html#string/2) gera strings aleatórias.
Nós podemos omitir o nome do módulo quando chamamos `string/2` porque `use ExUnitProperties` [importa as funções da biblioteca StreamData](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109). 
* `StreamData.integer/0` gera inteiros aleatórios.
* `times >= 0` é tipo uma cláusula guard.
Isso garante que os inteiros aleatórios que usamos nos nossos testes são maiores ou iguais a zero.
[`SreamData.positive_integer/0`](https://hexdocs.pm/stream_data/StreamData.html#positive_integer/0) existe, mas não é exatamente o que queremos, já que zero é um valor aceito por nossa função.

O `???` é apenas um pseudocódigo que adicionamos.
Deveríamos criar asserções sobre o que, exatamente?
_Poderíamos_ escrever:

```elixirduas
assert String.duplicate(str, times) == Repeater.duplicate(str, times)
```

...mas isso apenas usa a implementação atual da função, o que não é muito útil.
Poderíamos "afrouxar" nossa asserção para apenas verificar o tamanho da string:

```elixir
expected_length = String.length(str) * times
actual_length =
  str
  |> Repeater.duplicate(times)
  |> String.length()

assert actual_length == expected_length
```

Isso é melhor do que nada, mas ainda não é o ideal.
Esse teste ainda passaria se nossa função gerasse strings aleatórias com o tamanho correto. 

Realmente queremos verificar duas coisas:

1. Nossa função gera uma string com o tamanho correto.
2. O conteúdo da string final é a string original repetida indefinidamente.

Isso é apenas uma outra forma de [reformular a propriedade](https://www.propertesting.com/book_what_is_a_property.html#_alternate_wording_of_properties).
Já temos algum código para verificar #1.
Para verificar #2, vamos dividir a string final pela original e verifcar que nos foi retornado uma lista de zero ou mais strings vazias.

```elixir
list =
  str
  |> Repeater.duplicate(times)
  |> String.split(str)

assert Enum.all?(list, &(&1 == ""))
```

Vamos combinar nossas asserções:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "cria uma nova string, com o primeiro argumento duplicado um número específico de vezes" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end
  end
end
```

Quando comparamos isso com o nosso teste original, vemos que a versão usando StreamData é duas vezes maior. 
No entendo, conforme você adiciona mais casos de teste ao teste original ...

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicando uma string" do
    test "duplica o primeiro argumento para um número de vezes igual ao segungo argumento" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end

    test "retorna uma string vazia se o primeiro argumento for uma string vazia" do
      assert "" == Repeater.duplicate("", 4)
    end

    test "retorna uma string vazia se o segundo argumento for zero" do
      assert "" == Repeater.duplicate("a", 0)
    end

    test "funciona com strings grandes" do
      alphabet = "abcdefghijklmnopqrstuvwxyz"

      assert "#{alphabet}#{alphabet}" == Repeater.duplicate(alphabet, 2)
    end
  end
end
```

... a versão com StreamData é, na verdade, menor.
StreamData também cobre casos de borda que o desenvolvedor pode esquecer de testar.

### Listas

Agora, vamos escrever uma função que repete listas.
Queremos que a função funcione assim:

```elixir
Repeater.duplicate([1, 2, 3], 3)
# [1, 2, 3, 1, 2, 3, 1, 2, 3]
```

Aqui temos uma implementação correta, mas de certa forma, ineficiente:

```elixir
defmodule Repeater do
  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end
end
```

Um teste usando StreamData vai ficar mais ou menos assim:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "cria uma nova lista, com os elementos da lista original repetidos um número específico de vezes" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end
  end
end
```

Nós usamos `StreamData.list_of/1` e `StreamData.term/0` para criar listas de tamanho aleatório, com elementos de qualquer tipo.

Como o teste baseado em propriedade para repetir strings, nós comparamos o tamanho da nova lista com o produto da lista de origem e `times`.
A segunda asserção requer algumas explicações:

1. Dividimos a nova lista em várias listas, cada uma delas com o mesmo número de elementos que `list`.
2. Verificamos então que cada pedaço da lista é igual a `list`.

Em outras palavras, garantimos que nossa lista original aparece na lista final o número certo de vezes e que nenhum _outro_ elemento aparece na nossa lista final.

Por que usamos a condicional?
A primeira asserção e a condicional combinam-se para nos dizer que a lista original e a lista final estão vazias, portanto, não há necessidade de fazer nenuma outra comparação de lista.
Além disso, `Enum.chunk_every/2` requer que o segundo argumento seja positivo.

### Tuplas

Finalmente, vamos implementar uma função que repete os elementos de uma tupla.

A função deve funcionar assim:

```elixir
Repeater.duplicate({:a, :b, :c}, 3)
# {:a, :b, :c, :a, :b, :c, :a, :b, :c}
```

Uma maneira de fazermos isso é converter a tupla em uma lista, duplicar a lista e converter a estrutura de dados de volta para uma tupla. 

```elixir
defmodule Repeater do
  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

Como devemos testar isso?
Vamos abordar isso de uma maneira diferente do que fizemos até agora.
Para strings e listas, criamos algumas asserções sobre o tamanho do dado final e também sobre o conteúdo desse dado.
Tentar a mesma abordagem com tuplas é possível, mas o código de teste pode não ficar muito legível.

Considere duas sequências de operações que você pode fazer em uma tupla:

1. Chame `Repeater.duplicate/2` na tupla e converta o resultado em uma lista
2. Converta a tupla em uma lista e, em seguida, passe a lista para `Repeater.duplicate/2`

Essa é uma aplicação de um pattern que Scott Wlaschin chama de ["Caminhos diferentes, mesmo destino"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/#different-paths-same-destination).

É esperado que ambas as sequências de operações reproduzam o mesmo resultado.
Vamos usar essa abordagem em nosso teste.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "cria uma nova tupla, com os elementos da tupla original repetidos um número específico de vezes" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

## Sumário

Temos agora três cláusulas de funções que repetem strings, elementos de uma lista e elementos de uma tupla.
Temos também alguns testes baseados em propriedade que nos dão um alto grau de confiança que nossa implementação está correta.

Aqui está o código final da nossa aplicação:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end

  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end

  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

Aqui estão os testes baseados em propriedade:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "cria uma nova string, com o primeiro argumento duplicado um número específico de vezes" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end

    property "cria uma nova lista, com os elementos da lista original repetidos um número específico de vezes" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end

    property "cria uma nova tupla, com os elementos da tupla original repetidos um número específico de vezes" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

Você pode rodar seus testes rodando o seguinte comando em seu terminal:

```shell
mix test
```

Lembre que cada teste que você escreve usando StreamData vai rodar 100 vezes por padrão.
Além disso, alguns dados aleatórios de StreamData demoram mais para serem gerados do que outros.
O efeito cumulativo é que esse tipo de teste vai ser executado mais lentamente do que os testes unitários baseados em exemplos.

Ainda assim, testes baseados em propriedade são ótimos complementos para testes unitátios baseados em exemplos.
Eles nos permitem escrever testes sucintos que cobrem uma ampla variedade de entradas.
Se você não precisa manter estado entre as execuções de teste, SteamData oferece uma ótima sintaxe para escrever testes baseados em propriedade. 