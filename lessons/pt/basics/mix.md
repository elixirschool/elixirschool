%{
  version: "1.1.2",
  title: "Mix",
  excerpt: """
  Antes de podermos mergulhar nas águas mais profundas de Elixir, primeiro precisamos aprender a utilizar o Mix. 
Se você estiver familiarizado com Ruby, Mix é o Bundler, RubyGems e o Rake juntos. 
É uma parte crucial de qualquer projeto Elixir e nesta lição vamos explorar apenas algumas das suas grandes funcionalidades. 
Para ver tudo que o Mix tem para oferecer no ambiente atual, execute `mix help`.

Até agora trabalhamos exclusivamente dentro do `iex` que tem limitações. 
A fim de construir algo substancial precisamos dividir nosso código acima em outros arquivos para gerenciá-lo de forma eficaz; Mix nos permite fazer isso com projetos.
  """
}
---

## Novos Projetos

Quando estamos prontos para criar um novo projeto em Elixir, Mix faz com que isso seja fácil utilizando o comando `mix new`. 
Este comando irá gerar a estrutura de pastas do nosso projeto e a base de arquivos necessária. 
Este é bastante simples, então vamos começar:

```bash
$ mix new example
```

A partir do resultado, podemos ver que o Mix criou nosso diretório e uma quantidade de arquivos necessários para o mesmo:

```bash
* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

Nesta lição nós iremos focar nossa atenção no `mix.exs`. 
Aqui nós configuramos nossa aplicação, dependências, ambiente e versão. 
Abra o arquivo no seu editor favorito, você deve ver algo como isto (comentários removidos por questões de consumo de espaço):

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

A primeira seção que iremos analisar é `project`. 
Aqui nós definimos o nome da nossa aplicação (`app`), especificamos nossa versão (`version`), versão do Elixir (`elixir`), e finalmente nossas dependências (`deps`).

A seção `application` é usada durante a geração do nosso arquivo de aplicação que iremos ver em breve.

## Interativo

Pode ser necessário a utilização do `iex` dentro do contexto da nossa aplicação.
Felizmente para nós, Mix torna isso fácil. 
Com a nossa aplicação compilada podemos começar uma nova seção `iex`:

```bash
$ cd example
$ iex -S mix
```

Iniciando `iex` desta forma, irá carregar sua aplicação e dependências no atual ambiente de execução.

## Compilação

Mix é inteligente e irá compilar as alterações quando necessário, mas ainda pode ser necessário explicitamente compilar o seu projeto. 
Nesta seção, vamos cobrir a forma de compilar o nosso projeto e o que essa compilação faz.

Para compilar um projeto Mix, nós apenas temos que executar `mix compile` em nossa base do diretório:
**Nota: As tarefas do Mix de um projeto estão disponíveis apenas no diretório raiz do projeto, apenas as tarefas globais do Mix estão disponíveis em todos os projetos.**

```bash
$ mix compile
```

Não há muito dentro do nosso projeto, então a saída não será muito emocionante, mas deve concluir com êxito:

```bash
Compiled lib/example.ex
Generated example app
```

Quando compilamos um projeto, Mix cria um diretório `_build` para os nossos artefatos. 
Se olharmos dentro de `_build` veremos nossa aplicação compilada: `example.app`.

## Gerenciando Dependências

Nosso projeto não tem nenhuma dependência, mas terá em breve, por isso iremos seguir em frente e cobrir a definição e busca de dependências.

Para adicionar uma nova dependência, primeiro precisamos adicioná-la ao nosso `mix.exs` na seção `deps`. 
Nossa lista de dependência é composta por tuplas com 2 valores obrigatórios e um opcional: O nome do pacote como um *atom*, a versão como *string* e opções opcionais.

Para este exemplo vamos ver um projeto com dependências, como [phoenix_slim](https://github.com/doomspork/phoenix_slim):

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

Como você provavelmente percebeu nas dependências acima, a dependência `cowboy` é apenas necessária durante o desenvolvimento e teste.

Uma vez que tenhamos definido nossas dependências, existe um passo final: buscar estas dependências. 
Isso é análogo ao `bundle install`:

```bash
$ mix deps.get
```

É isso aí! Nós definimos e buscamos nossas dependências. 
Agora estamos preparados para adicionar dependências quando chegar a hora.

## Ambientes

Mix, bem como Bundler, suporta ambientes diferentes. 
Naturalmente Mix trabalha com três ambientes:

+ `:dev` — O ambiente padrão.
+ `:test` — Usado por `mix test`. Coberto futuramente na nossa próxima lição.
+ `:prod` — Usado quando nós enviamos a nossa aplicação para produção.

O ambiente atual pode ser acessado usando `Mix.env`. 
Como esperado, o ambiente pode ser alterado através da variável de ambiente `MIX_ENV`:

```bash
$ MIX_ENV=prod mix compile
```
