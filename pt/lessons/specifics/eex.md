---
version: 1.0.2
title: Elixir embutido (EEx)
---

Do mesmo jeito que Ruby possui ERB e Java JSPs, Elixir tem EEx ou *Embedded Elixir (Elixir embutido)*. Com EEx podemos embutir e avaliar código Elixir dentro das *strings*.

{% include toc.html %}

## API

A API EEX suporta trabalhar com cadeias de caracteres e arquivos diretamente. A API está dividida em três componentes principais: avaliação simples, definições de funções, e compilação para AST.

### Avaliação

Usando `eval_string/3` e `eval_file/2` podemos realizar uma simples avaliação sobre uma string ou conteúdos de um arquivo. Este é a API mais simples mas lento uma vez que o código é interpretado e não compilado.

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### Definições

A mais rápida e preferida forma de usar o EEx é embutir nosso template dentro de um módulo assim ele pode ser compilado. Para isso precisamos do nosso template no momento da compilação e dos macros `function_from_string/5` e `function_from_file/5`.

Vamos mover nossa saudação para outro arquivo e gerar uma função para nosso template:

```elixir
# greeting.eex
Hi, <%= name %>

defmodule Example do
  require EEx
  EEx.function_from_file(:def, :greeting, "greeting.eex", [:name])
end

iex> Example.greeting("Sean")
"Hi, Sean"
```

### Compilação

Por último, EEx fornece-nos uma forma para directamente gerar Elixir AST a partir de uma cadeia de caracteres usando `compile_string/2` ou `compile_file/2`. Esta API é usada principalmente pelas APIs acima mencionadas, mas está disponível caso deseje implementar seu próprio tratamento de Elixir embutido.

## Etiquetas

Por padrão, existem quatro etiquetas (tags) suportadas no EEx:

```elixir
<% expressão Elixir - alinhado com a saída %>
<%= expressão Elixir - substitui com o resultado %>
<%% EEx quotation - retorna o contéudo do seu interior %>
<%# Comentários - são ignorados no código fonte %>
```

Todas expressões que desejamos imprimir __devem__ usar o sinal de igualdade (`=`). É importante notar que enquanto outras linguagens de templates tratam cláusulas tipo `if` de forma especial, EEx não faz isso. Sem `=` nada será impresso:

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## Motor

Por padrão Elixir usa `EEx.SmartEngine` que inclui suporte atribuições (como `@name`):ike `@name`):

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

As atribuições `EEx.SmartEngine` são úteis porque atribuições podem ser mudadas sem a necessidade de compilar o template:

Interessado em escrever o seu próprio motor?  Confira o procedimento [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) para ver o que é necessário.
