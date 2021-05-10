%{
  version: "1.1.0",
  title: "Documentação",
  excerpt: """
  Documentando código em Elixir.
  """
}
---

## Anotações

Quanto comentamos e o que faz uma documentação ser de qualidade segue sendo uma controvérsia dentro do mundo da programação. No entanto, nós podemos concordar que documentação é importante para nós e para aqueles que trabalham com a nossa base de código.

Elixir trata de documentação como uma *cidadã de primeira classe*, oferecendo várias funções de acesso e geração de documentação para seus projetos. O núcleo do Elixir nos fornece muitos atributos diferentes para anotar uma base de código. Vejamos 3 maneiras:

  - `#` - Para documentação em linha.
  - `@moduledoc` - Para documentação em nível de módulo.
  - `@doc` - Para documentação em nível de função.

### Documentação em Linha

Provavelmente, a maneira mais simples de comentar o seu código é com comentários em linha. Semelhante a Ruby ou Python, comentário em linha do Elixir é determinado com um `#`, muitas vezes conhecido como um `sustenido`, ou um *hash* dependendo de onde você vive no mundo.

Observe este script em Elixir (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Elixir, ao executar este script, irá ignorar tudo de `#` até o fim da linha, tratando-a como dados ocultos e sem lógica de execução. Pode adicionar nenhum valor para a operação ou alterar o desempenho do script, no entanto, quando não é tão óbvio o que está acontecendo, um programador deve conseguir entender ao ler o comentário. Esteja atento para não abusar do comentário de uma linha! Bagunçar uma base de código pode se tornar um pesadelo indesejável para alguns. É melhor usar com moderação.

### Documentação de  Módulos

A anotação `@moduledoc`  permite a documentação em linha em um nível de módulo. É tipicamente situada logo abaixo da declaração `defmodule` no topo de um arquivo. O exemplo abaixo mostra um comentário de uma linha dentro do decorador `@moduledoc`.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Nós (ou outros) podemos acessar esta documentação de módulo usando a função `h` helper dentro de IEx. Nós podemos ver por nós mesmos se colocarmos nosso módulo `Greeter` em um novo arquivo chamado `greeter.ex` e compilarmos:

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

_Nota_: não precisamos compilar manualmente nossos arquivos como fizemos acima se estamos trabalhando dentro do contexto de um projeto mix. Você pode usar o `iex -S mix` para carregar o IEx console de um projeto atual se você estiver trabalhando em um projeto mix.

### Documentação de Funções

Assim como Elixir nos dá a capacidade para anotação em nível de módulo, ele também permite anotações semelhantes para documentar funções. A anotação `@doc` permite a documentação de funções. A anotação `@doc` fica logo acima da função que está anotando.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Se utilizarmos IEx novamente e executar o comando auxiliar (`h`) sobre a função prefixada com o nome do módulo, devemos ver o seguinte.

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

`hello/1` prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Observe como você pode usar marcação na documentação e o terminal irá renderizar isto. Além de realmente ser uma ótima nova adição para o vasto ecossistema de Elixir, ficará muito mais interessante quando olharmos o ExDoc para gerar documentação HTML em tempo real.

**Nota:** a anotação `@spec` é usada para analisar estaticamente o código. Para aprender mais sobre isso, veja a lição [Especificações e tipos](../../advanced/typespec).

## ExDoc

ExDoc é um projeto oficial do Elixir que **produz HTML (Hyper Text Markup Language) e documentação online para projetos Elixir** que pode ser encontrado no [Github](https://github.com/elixir-lang/ex_doc). Primeiro vamos criar um projeto Mix para a nossa aplicação:

```bash
$ mix new greet_everyone

* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Agora, copie e cole o código a partir da lição de anotação `@doc` dentro do arquivo chamado `lib/greeter.ex` e garanta que tudo ainda está funcionando na linha de comando. Agora que estamos trabalhando dentro do projeto Mix nós temos que iniciar o IEx um pouco diferente usando o comando `iex -S mix`:

```bash
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Instalando

Assumindo que tudo está bem, a saída acima sugere que estamos prontos para configurar o ExDoc. Dentro do nosso arquivo `mix.exs` adicione as duas dependências necessárias para começar; `:earmark` e `:ex_doc`.

```elixir
def deps do
  [
    {:earmark, "~> 1.2", only: :dev},
    {:ex_doc, "~> 0.19", only: :dev}
  ]
end
```

Nós especificamos o par de chave-valor `only :dev`, já que não desejamos fazer o download e compilar essas dependências em um ambiente de produção. Porém, por que Earmark? Earmark é um parser para Markdown da linguagem de programação Elixir no qual ExDoc utiliza para converter nossa documentação dentro de `@moduledoc` e `@doc` em uma bela estrutura HTML.

É interessante notar neste momento que você não é obrigado a usar Earmark. Você pode mudar a ferramenta de marcação para outras como Pandoc, Hoedown ou Cmark; porém você terá que fazer um pouco mais de configuração, no qual você pode ler sobre [aqui](https://github.com/elixir-lang/ex_doc#changing-the-markdown-tool). Para este tutorial, vamos continuar utilizando Earmark.

### Gerando Documentação

Prosseguindo, a partir da linha de comando execute os dois comandos a seguir:

```bash
$ mix deps.get # gets ExDoc + Earmark.
$ mix docs # makes the documentation.

Docs successfully generated.
View them at "doc/index.html".
```

Com esperança, se tudo correu como planejado, você deve ver uma mensagem semelhante como a mensagem de saída no exemplo acima. Vamos agora olhar para dentro do nosso projeto Mix e devemos ver que há um outro diretório chamado **doc/**. Dentro estará nossa documentação gerada. Se visitarmos a página index em nosso navegador devemos ver o seguinte:

![ExDoc Screenshot 1](/images/documentation_1.png)

Podemos ver que Earmark converteu nosso markdown e o ExDoc está exibindo-o em um formato útil.

![ExDoc Screenshot 2](/images/documentation_2.png)

Agora nós podemos implantar isso para GitHub, o nosso próprio site, ou mais comumente no [HexDocs](https://hexdocs.pm/).

## Boas Práticas

Documentação deve ser adicionada seguindo as boas práticas orientadas pela linguagem. Considerando que Elixir é uma linguagem bastante jovem, muitas normas ainda serão descobertas ao longo do crescimento do ecossistema. A comunidade, entretanto, tem feito esforços para estabelecer as melhores práticas. Para ler mais sobre, veja [O Guia de Estilo Elixir](https://github.com/niftyn8/elixir_style_guide).

  - Sempre documente um módulo.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Caso você não pretenda documentar um módulo, **não deixe-o** em branco. Considere anotar o módulo com `false` como a seguir:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

  - Quando se referir a funções dentro da documentação de um módulo, use backticks desta forma:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Separe todo e qualquer código de uma única linha abaixo de `@moduledoc` como a seguir:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  This module also has a `hello/1` function.
  """

  alias Goodbye.bye_bye
  # and so on...

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Use markdown dentro de funções para torná-lo mais fácil de ler, até em caso de leitura através de IEx ou ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Tente incluir alguns exemplos de código em sua documentação, isto também permite gerar testes automáticos a partir dos exemplos de código encontrados em um módulo, função ou macro com [Exunit.DocTest] []. A fim de fazer isso, é preciso invocar o macro `doctest/1` de seu caso de teste e escrever os seus exemplos de acordo com algumas orientações, que são detalhados na [documentação oficial][ExUnit.DocTest].

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
