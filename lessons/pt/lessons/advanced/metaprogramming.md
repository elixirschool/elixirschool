%{
  version: "1.0.2",
  title: "Metaprogramação",
  excerpt: """
  Metaprogramação é o processo de utilização de código para escrever código. Em Elixir isso nos dá a capacidade de estender a linguagem para se adequar às nossas necessidades e dinamicamente alterar o código. Vamos começar observando como Elixir é representado por debaixo dos panos, em seguida como modificá-lo, e finalmente, como podemos usar esse conhecimento para estendê-la.


Uma palavra de cautela: Metaprogramação é complicado e só deve ser usado quando for absolutamente necessário. O uso excessivo certamente levará a um código complexo que é difícil de entender e debugar.
  """
}
---

## Quote

O primeiro passo para metaprogramação é a compreensão de como as expressões são representadas. Em Elixir, a árvore de sintaxe abstrata (AST), a representação interna do nosso código, é composta de tuplas. Estas tuplas contêm três partes: o nome da função, metadados e argumentos da função.

A fim de ver essas estruturas internas, Elixir nos fornece a função `quote/2`. Usando `quote/2` podemos converter o código Elixir em sua representação subjacente:

```elixir
iex> quote do: 42
42
iex> quote do: "Hello"
"Hello"
iex> quote do: :world
:world
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
iex> quote do: if value, do: "True", else: "False"
{:if, [context: Elixir, import: Kernel],
 [{:value, [], Elixir}, [do: "True", else: "False"]]}
```

Notou que os três primeiros exemplos não retornaram tuplas? Existem cinco literais que retornam eles mesmos quando citados (quoted):

```elixir
iex> :atom
:atom
iex> "string"
"string"
iex> 1 # All numbers
1
iex> [1, 2] # Lists
[1, 2]
iex> {"hello", :world} # 2 element tuples
{"hello", :world}
```

## Unquote

Agora que podemos recuperar a estrutura interna do nosso código, como podemos modificá-lo? Para injetar novo código ou valores usamos `unquote/1`. Quando *unquote* em uma expressão que vai ser avaliada e injetado no AST. Para demonstrar `unquote/1` vejamos alguns exemplos:

```elixir
iex> denominator = 2
2
iex> quote do: divide(42, denominator)
{:divide, [], [42, {:denominator, [], Elixir}]}
iex> quote do: divide(42, unquote(denominator))
{:divide, [], [42, 2]}
```

No primeiro exemplo, a variável `denominator` é citada de modo que a AST resultante inclua uma tupla para acessar a variável. No exemplo de `unquote/1`, o código resultante inclui o valor de `denominator` no lugar.

## Macros

Uma vez que entendemos `quote/2` e `unquote/1` estamos prontos para mergulhar em macros. É importante lembrar que macros, como todas as metaprogramações, devem ser usadas com moderação.

No mais simples dos termos, macros são funções especiais destinadas a retornar uma expressão entre aspas que será inserido no nosso código do aplicativo. Imagine um macro substituído por uma expressão *quote*, em vez de chamada como uma função. Com macros temos tudo que é necessário para estender Elixir e dinamicamente adicionar código para nossas aplicações.

Começamos por definir um macro usando `defmacro/2` que em si é um macro, como grande parte da linguagem Elixir (deixar isso imerso). Como exemplo vamos implementar `unless` como um macro. Lembre-se que o nosso macro precisa retornar uma expressão citada:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Vamos exigir um módulo e testar o seu Macro:

```elixir
iex> require OurMacro
nil
iex> OurMacro.unless true, do: "Hi"
nil
iex> OurMacro.unless false, do: "Hi"
"Hi"
```

Já que macros substituem o código em nossa aplicação, nós podemos controlar quando e o que é compilado. Um exemplo disso pode ser encontrado no módulo `Logger`. Quando o log está desabilitado nenhum código é injetado e o aplicativo resultante não contém referências ou chamadas de função para registro. Isso é diferente de outras linguagens onde ainda existe a sobrecarga de uma chamada de função, mesmo quando a implementação é NOP.

Para demonstrar isso, vamos fazer um *logger* simples que pode ser ativado ou desativado:

```elixir
defmodule Logger do
  defmacro log(msg) do
    if Application.get_env(:logger, :enabled) do
      quote do
        IO.puts("Logged message: #{unquote(msg)}")
      end
    end
  end
end

defmodule Example do
  require Logger

  def test do
    Logger.log("This is a log message")
  end
end
```

Com o log ativado a nossa função `test` resultaria em um código parecido com isto:

```elixir
def test do
  IO.puts("Logged message: #{"This is a log message"}")
end
```

Mas se desativarmos o log, o código resultante seria:

```elixir
def test do
end
```

## Debugando

Está bem, agora nós sabemos como usar `quote/2`, `unquote/1` e escrever macros. Mas e se você tiver uma grande quantidade de código *quoted* e você precisa entendê-lo? Nesse caso, você pode usar `Macro.to_string/2`. Veja este exemplo:

```elixir
iex> Macro.to_string(quote(do: foo.bar(1, 2, 3)))
"foo.bar(1, 2, 3)"
```

E quando você quiser ver o código gerado por macros você pode combinar eles com `Macro.expand/2` e `Macro.expand_once/2`, essas funções expandem os macros para seus códigos *quoted*. O primeiro pode expandir ele várias vezes, enquanto o último - apenas uma vez. Por exemplo, vamos modificar o exemplo do `unless` da seção anterior:

```elixir
defmodule OurMacro do
  defmacro unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end

require OurMacro

quoted =
  quote do
    OurMacro.unless(true, do: "Hi")
  end
```

```elixir
iex> quoted |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts
if(!true) do
  "Hi"
end
```

Se nós rodarmos o mesmo código com `Macro.expand/2`, é intrigante:

```elixir
iex> quoted |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
case(!true) do
  x when x in [false, nil] ->
    nil
  _ ->
    "Hi"
end
```

Você deve lembrar que nós mencionamos que `if` é um macro em Elixir, aqui nós vemos expandido para sua declaração `case` subjacente.

### Macros Privados

Embora não seja tão comum, Elixir suporta macros privadas. Um macro privado é definido com `defmacrop` e só pode ser chamado a partir do módulo no qual ele foi definido. Macros privados devem ser definidas antes do código que as invoca.

### Higienização de Macros

A característica de como macros interagem com o contexto de quem o chamou quando expandido é conhecida como a higienização de macro. Por padrão macros no Elixir são higiênicos e não entrarão em conflito com nosso contexto:

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end
end

iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
```

Mas e se quisermos manipular o valor de `val` ? Para marcar uma variável como sendo anti-higiênica podemos usar `var!/2`. Vamos atualizar o nosso exemplo para incluir outro macro utilizando `var!/2`!

```elixir
defmodule Example do
  defmacro hygienic do
    quote do: val = -1
  end

  defmacro unhygienic do
    quote do: var!(val) = -1
  end
end
```

Vamos comparar a forma como eles interagem com nosso contexto:

```elixir
iex> require Example
nil
iex> val = 42
42
iex> Example.hygienic
-1
iex> val
42
iex> Example.unhygienic
-1
iex> val
-1
```

Ao incluir `var!/2` em nossa macro que manipular o valor de `val` sem passá-la em nossa macro. O uso de macros não higiênicos deve ser mantido a um mínimo. Ao incluir `var!/2` que aumentam o risco de um conflito de resolução de variável.

### Binding

Nós já cobrimos a utilidade do `unquote/1` mas há outra maneira de injetar valores em nosso código: *binding*. Com *binding* de variável somos capazes de incluir múltiplas variáveis em nossa macro e garantir que eles são *unquote* apenas uma vez, evitando reavaliações acidentais. Para usar variáveis de vinculação precisamos passar uma lista de palavras-chave para a opção `bind_quoted` de `quote/2`.

Para ver o benefício de `bind_quote` e para demonstrar o problema de reavaliação, vamos usar um exemplo. Podemos começar por criar uma macro que simplesmente exibe a expressão duas vezes:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote do
      IO.puts(unquote(expr))
      IO.puts(unquote(expr))
    end
  end
end
```

Vamos tentar o nosso novo macro, passando a hora atual do sistema, devemos esperar para vê-lo emitido duas vezes:

```elixir
iex> Example.double_puts(:os.system_time)
1450475941851668000
1450475941851733000
```

Os tempos são diferentes! O que aconteceu? Usando `unquote/1` na mesma expressão várias vezes os resultados em reavaliação podem ter consequências inesperadas. Vamos atualizar o exemplo para usar `bind_quoted` e ver o que temos:

```elixir
defmodule Example do
  defmacro double_puts(expr) do
    quote bind_quoted: [expr: expr] do
      IO.puts(expr)
      IO.puts(expr)
    end
  end
end

iex> require Example
nil
iex> Example.double_puts(:os.system_time)
1450476083466500000
1450476083466500000
```

Com `bind_quoted` nós temos o nosso resultado esperado: o mesmo tempo impresso duas vezes.

Agora que nós cobrimos `quote/2`, `unquote/1`, e `defmacro/2` temos todas as ferramentas necessárias para estender Elixir para atender às nossas necessidades.
