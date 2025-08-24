%{
  version: "1.0.0",
  title: "Lua",
  excerpt: """
  A biblioteca Lua fornece uma interface ergonômica para o Luerl, permitindo a execução segura de scripts Lua em sandbox diretamente na BEAM VM. Nesta lição, exploraremos como incorporar capacidades de scripting Lua em nossas aplicações Elixir para lógica definida pelo usuário, configuração e extensibilidade.
  """
}
---

## Visão Geral

A [biblioteca Lua](https://github.com/tv-labs/lua) para Elixir é um wrapper ergonômico em torno do [Luerl](https://github.com/rvirding/luerl), a implementação pura em Erlang do Lua 5.3 de Robert Virding. Ao contrário das abordagens tradicionais que incorporam o runtime C do Lua, esta implementação executa inteiramente na BEAM VM, fornecendo excelentes capacidades de sandbox e integração.

Esta abordagem oferece várias vantagens principais:
- **Segurança**: O código Lua executa em um ambiente sandbox sem acesso aos internos de nossa aplicação Elixir
- **Performance**: Nenhuma sobrecarga de serialização entre runtimes, os dados fluem diretamente entre Elixir e Lua
- **Integração**: Interoperabilidade perfeita com funções e estruturas de dados do Elixir
- **Concorrência**: Aproveita os processos leves e a tolerância a falhas da BEAM

## Por Que Usar Lua no Elixir?

Podemos nos perguntar por que usar Lua quando o próprio Elixir é uma linguagem tão poderosa. Aqui estão casos de uso comuns:

- **Scripts definidos pelo usuário**: Permitir que usuários finais escrevam lógica personalizada sem expor nossa base de código Elixir
- **Configuração como código**: Habilitar configurações complexas e dinâmicas que vão além de arquivos estáticos
- **Sistemas de plugins**: Criar aplicações extensíveis onde usuários podem escrever comportamentos personalizados
- **Linguagens específicas de domínio**: Implementar interfaces de scripting para domínios de negócios específicos
- **Execução segura de código**: Executar código não confiável de fontes externas em um ambiente controlado

## Instalação

Adicione a biblioteca Lua às nossas dependências do `mix.exs`:

```elixir
defp deps do
  [
    {:lua, "~> 0.1.0"}
  ]
end
```

Então execute:

```shell
mix deps.get
```

## Uso Básico

Vamos começar com o exemplo mais simples possível avaliando código Lua:

```elixir
iex> {result, _state} = Lua.eval!("return 2 + 3")
{[5], #PID<0.123.0>}
iex> result
[5]
```

A função `Lua.eval!/2` retorna uma tupla contendo os resultados (como uma lista) e o estado Lua. Mesmo expressões simples retornam resultados como listas porque funções Lua podem retornar múltiplos valores.

## O Sigil ~LUA

A biblioteca Lua fornece um sigil `~LUA` que valida a sintaxe Lua em tempo de compilação:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> {[7], _state} = Lua.eval!(~LUA[return 3 + 4])
{[7], #PID<0.124.0>}
```

Se tentarmos usar sintaxe Lua inválida, obteremos um erro em tempo de compilação:

```elixir
iex> {result, _state} = Lua.eval!(~LUA[return 2 +])
** (Lua.CompilerException) Failed to compile Lua!
```

## Otimização em Tempo de Compilação

Usar o modificador `c` com o sigil compila nosso código Lua em um `Lua.Chunk.t()` em tempo de compilação, melhorando a performance em runtime:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> {[42], _state} = Lua.eval!(~LUA[return 6 * 7]c)
{[42], #PID<0.125.0>}
```

## Trabalhando com Estado Lua

Cada ambiente de execução Lua mantém seu próprio estado, incluindo variáveis, funções e dados. Podemos criar e manipular este estado:

```elixir
iex> lua = Lua.new()
#PID<0.126.0>

# Definir uma variável
iex> lua = Lua.set!(lua, [:my_var], 42)
#PID<0.126.0>

# Lê-la de volta
iex> {[42], _state} = Lua.eval!(lua, "return my_var")
{[42], #PID<0.126.0>}
```

Também podemos trabalhar com estruturas de dados aninhadas:

```elixir
iex> lua = Lua.new()
iex> lua = Lua.set!(lua, [:config, :database, :port], 5432)
iex> {[5432], _state} = Lua.eval!(lua, "return config.database.port")
{[5432], #PID<0.127.0>}
```

## Expondo Funções Elixir para Lua

## Exposição Simples de Função

A maneira mais direta de expor uma função Elixir para Lua é usando `Lua.set!/3`:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> 
iex> lua = 
...>   Lua.new()
...>   |> Lua.set!([:sum], fn args -> [Enum.sum(args)] end)
#PID<0.128.0>

iex> {[10], _state} = Lua.eval!(lua, ~LUA[return sum(1, 2, 3, 4)]c)
{[10], #PID<0.128.0>}
```

Note que funções Elixir expostas ao Lua devem:
- Aceitar uma lista de argumentos
- Retornar uma lista de resultados (mesmo para valores únicos)

## Usando a Macro deflua

Para APIs mais complexas, a macro `deflua` fornece uma sintaxe mais limpa:

```elixir
defmodule MathAPI do
  use Lua.API

  deflua add(a, b), do: a + b
  deflua multiply(a, b), do: a * b
  deflua power(base, exponent), do: :math.pow(base, exponent)
end

# Carrega a API em um estado Lua
iex> lua = Lua.new() |> Lua.load_api(MathAPI)
iex> {[16.0], _state} = Lua.eval!(lua, ~LUA[return power(2, 4)])
{[16.0], #PID<0.129.0>}
```

## APIs com Escopo

Podemos organizar funções sob namespaces usando a opção `:scope`:

```elixir
defmodule StringAPI do
  use Lua.API, scope: "str"

  deflua upper(text), do: String.upcase(text)
  deflua lower(text), do: String.downcase(text)
  deflua length(text), do: String.length(text)
end

iex> lua = Lua.new() |> Lua.load_api(StringAPI)
iex> {["HELLO"], _state} = Lua.eval!(lua, ~LUA[return str.upper("hello")])
{["HELLO"], #PID<0.130.0>}
```

## Padrões de API Avançados

## Trabalhando com Tabelas Lua

Ao trabalhar com estruturas de dados Lua complexas, podemos usar `Lua.Table.as_list/1` para converter tabelas Lua de volta para listas Elixir:

```elixir
defmodule Queue do
  use Lua.API, scope: "q"

  deflua push(v), state do
    # Puxa a variável global "my_queue" do lua
    queue = Lua.get!(state, [:my_queue])
    
    # Chama a função Lua table.insert(table, value)
    {[], state} = Lua.call_function!(state, [:table, :insert], [queue, v])
    
    # Retorna o estado lua modificado sem valores de retorno
    {[], state}
  end
end

iex> lua = Lua.new() |> Lua.load_api(Queue)
iex> {[queue], _} = Lua.eval!(lua, """
...> my_queue = {}
...> q.push("first")
...> q.push("second")
...> return my_queue
...> """)
iex> Lua.Table.as_list(queue)
["first", "second"]
```

```elixir
defmodule CounterAPI do
  use Lua.API, scope: "counter"

  deflua increment(), state do
    current = Lua.get(state, [:count], 0)
    new_count = current + 1
    state = Lua.set!(state, [:count], new_count)
    {[new_count], state}
  end

  deflua get_count(), state do
    count = Lua.get(state, [:count], 0)
    {[count], state}
  end
end

iex> lua = Lua.new() |> Lua.load_api(CounterAPI)
iex> {[1], lua} = Lua.eval!(lua, ~LUA[return counter.increment()])
iex> {[2], lua} = Lua.eval!(lua, ~LUA[return counter.increment()])
iex> {[2], _state} = Lua.eval!(lua, ~LUA[return counter.get_count()])
```

## Chamando Funções Lua do Elixir

Também podemos chamar funções Lua do nosso código Elixir usando `Lua.call_function!/3`:

```elixir
defmodule StringProcessorAPI do
  use Lua.API, scope: "processor"

  deflua process_with_lua(text), state do
    # Chama uma função Lua para processar o texto
    Lua.call_function!(state, [:string, :upper], [text])
  end
end

iex> lua = Lua.new() |> Lua.load_api(StringProcessorAPI)
iex> {["PROCESSED"], _state} = Lua.eval!(lua, ~LUA[return processor.process_with_lua("processed")])
```

## Tipos de Dados e Codificação

Ao trabalhar com Lua, entender como os tipos de dados Elixir mapeiam para Lua é crucial:

| Tipo Elixir | Tipo Lua | Codificação Necessária? |
|-------------|----------|-------------------------|
| `nil` | `nil` | Não |
| `boolean()` | `boolean` | Não |
| `number()` | `number` | Não |
| `binary()` | `string` | Não |
| `atom()` | `string` | Sim |
| `map()` | `table` | Sim |
| `list()` | `table` | Talvez* |
| `{:userdata, any()}` | `userdata` | Sim |

*Listas requerem codificação apenas se contiverem elementos que necessitem codificação.

## Trabalhando com Maps e Tabelas

Maps Elixir se tornam tabelas Lua quando codificados:

```elixir
iex> config = %{database: %{host: "localhost", port: 5432}, debug: true}
iex> {encoded_config, lua} = Lua.encode!(Lua.new(), config)
iex> lua = Lua.set!(lua, [:config], encoded_config)
iex> {[5432], _state} = Lua.eval!(lua, "return config.database.port")
{[5432], #PID<0.131.0>}
```

## User Data para Estruturas Complexas

Para passar estruturas de dados Elixir complexas que não queremos que o Lua modifique:

```elixir
defmodule User do
  defstruct [:id, :name, :email]
end

iex> user = %User{id: 1, name: "Alice", email: "alice@example.com"}
iex> {encoded_user, lua} = Lua.encode!(Lua.new(), {:userdata, user})
iex> lua = Lua.set!(lua, [:current_user], encoded_user)
iex> {[{:userdata, %User{id: 1, name: "Alice", email: "alice@example.com"}}], _state} = 
...>   Lua.eval!(lua, "return current_user")
{[{:userdata, %User{id: 1, name: "Alice", email: "alice@example.com"}}], #PID<0.132.0>}
```

## Contexto Privado e Segurança

Uma das características mais poderosas é a capacidade de manter contexto privado que é acessível ao nosso código Elixir mas oculto dos scripts Lua:

```elixir
defmodule UserAPI do
  use Lua.API, scope: "user"

  deflua get_name(), state do
    user = Lua.get_private!(state, :current_user)
    {[user.name], state}
  end

  deflua get_permission(resource), state do
    user = Lua.get_private!(state, :current_user)
    permissions = Lua.get_private!(state, :permissions)
    
    has_permission = resource in Map.get(permissions, user.id, [])
    {[has_permission], state}
  end
end

# Configura o contexto de execução
user = %{id: 1, name: "Alice"}
permissions = %{1 => ["read_posts", "write_comments"]}

lua = 
  Lua.new()
  |> Lua.put_private(:current_user, user)
  |> Lua.put_private(:permissions, permissions)
  |> Lua.load_api(UserAPI)

# O usuário só pode acessar seu nome e verificar permissões
{["Alice"], _state} = Lua.eval!(lua, ~LUA[return user.get_name()])
{[true], _state} = Lua.eval!(lua, ~LUA[return user.get_permission("read_posts")])
{[false], _state} = Lua.eval!(lua, ~LUA[return user.get_permission("admin_panel")])
```

## Exemplo do Mundo Real: Motor de Configuração

Vamos construir um exemplo prático, um motor de configuração que permite aos usuários definir regras de negócio complexas:

```elixir
defmodule ConfigEngine do
  defmodule PricingAPI do
    use Lua.API, scope: "pricing"

    deflua get_base_price(product_type), state do
      prices = Lua.get_private!(state, :base_prices)
      price = Map.get(prices, product_type, 0)
      {[price], state}
    end

    deflua calculate_discount(user_tier, order_amount), _state do
      discount = case user_tier do
        "premium" when order_amount >= 100 -> 0.2
        "premium" -> 0.1
        "standard" when order_amount >= 50 -> 0.05
        _ -> 0.0
      end
      {[discount], state}
    end

    deflua apply_seasonal_modifier(month), _state do
      modifier = case month do
        12 -> 0.9  # Desconto de dezembro
        1 -> 0.95  # Desconto de janeiro
        _ -> 1.0
      end
      {[modifier], state}
    end
  end

  def calculate_price(product_type, quantity, user_tier, lua_script) do
    base_prices = %{
      "widget" => 10.0,
      "gadget" => 25.0,
      "premium_item" => 100.0
    }

    lua = 
      Lua.new()
      |> Lua.put_private(:base_prices, base_prices)
      |> Lua.load_api(PricingAPI)
      |> Lua.set!([:product_type], product_type)
      |> Lua.set!([:quantity], quantity)
      |> Lua.set!([:user_tier], user_tier)
      |> Lua.set!([:current_month], Date.utc_today().month)

    {[final_price], _state} = Lua.eval!(lua, lua_script)
    final_price
  end
end
```

Agora os usuários podem definir lógica de preço complexa:

```elixir
pricing_script = ~LUA"""
base_price = pricing.get_base_price(product_type)
subtotal = base_price * quantity

discount = pricing.calculate_discount(user_tier, subtotal)
seasonal_modifier = pricing.apply_seasonal_modifier(current_month)

final_price = subtotal * (1 - discount) * seasonal_modifier
return final_price
"""c

# Calcula o preço para um usuário premium comprando 5 widgets em dezembro
price = ConfigEngine.calculate_price("widget", 5, "premium", pricing_script)
# Resultado: 50 * 0.8 * 0.9 = 36.0
```

## Tratamento de Erros e Depuração

A biblioteca Lua fornece mensagens de erro melhoradas comparado ao Luerl puro:

```elixir
iex> try do
...>   Lua.eval!("return undefined_function()")
...> rescue
...>   e -> IO.puts("Erro Lua: #{inspect(e)}")
...> end
```

Para erros de validação em tempo de compilação:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> try do
...>   ~LUA[return 2 +]
...> rescue
...>   e in Lua.CompilerException -> IO.puts("Erro de compilação: #{e.message}")
...> end
Erro de compilação: Failed to compile Lua!
```

Para depuração, podemos inspecionar o estado Lua:

```elixir
iex> lua = Lua.new() |> Lua.set!([:debug_var], "debugging")
iex> variables = Lua.get_globals(lua)
iex> IO.inspect(variables)
```

## Testando Integração Lua

Ao testar código que usa Lua, podemos fornecer scripts Lua controlados:

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  import Lua, only: [sigil_LUA: 2]

  test "cálculo de preço com script lua" do
    script = ~LUA[return base_price * quantity * 0.9]c
    
    lua = 
      Lua.new()
      |> Lua.set!([:base_price], 10.0)
      |> Lua.set!([:quantity], 3)

    {[result], _state} = Lua.eval!(lua, script)
    assert result == 27.0
  end

  test "tratamento de erro para lua inválido" do
    assert_raise Lua.CompilerException, fn ->
      Lua.eval!(~LUA[return invalid syntax])
    end
  end
end
```

## Considerações de Performance

- **Chunks em tempo de compilação**: Use o modificador `c` com sigils `~LUA` para melhor performance
- **Reutilização de estado**: Reutilize estados Lua quando possível em vez de criar novos
- **Conversão mínima de dados**: Mantenha dados em formatos compatíveis para reduzir sobrecarga de codificação
- **Exposição de funções**: Exponha apenas as funções que nossos scripts Lua realmente precisam

## Melhores Práticas de Segurança

- **Nunca exponha funções perigosas**: Não forneça acesso a operações de sistema de arquivos, rede ou processos
- **Use contexto privado**: Mantenha dados sensíveis em contexto privado em vez de variáveis Lua
- **Valide entradas**: Sempre valide dados vindos de scripts Lua
- **Limites de recursos**: Considere implementar timeouts e limites de memória para scripts de longa execução
- **Princípio do menor privilégio**: Exponha apenas a superfície mínima de API necessária

## Casos de Uso na Prática

A biblioteca Lua excele em vários cenários:

## Sistemas de Plugins

```elixir
# Permite aos usuários definir transformações de dados personalizadas
transform_script = ~LUA"""
-- Transformação definida pelo usuário
if user_tier == "premium" then
  return data * 1.5
else
  return data
end
"""
```

## Configuração como Código

```elixir
# Regras de roteamento complexas definidas por usuários
routing_script = ~LUA"""
if request.path:match("^/api/") then
  if user.role == "admin" then
    return "backend_pool_1"
  else
    return "backend_pool_2"
  end
else
  return "frontend_pool"
end
"""
```

## Motor de Regras de Negócio

```elixir
# Fluxos de aprovação definidos pelo usuário
approval_script = ~LUA"""
if amount > 10000 then
  return {"requires": {"cfo_approval", "board_approval"}}
elseif amount > 1000 then
  return {"requires": {"manager_approval"}}
else
  return {"approved": true}
end
"""
```

## Conclusão

A biblioteca Lua para Elixir fornece uma maneira poderosa e segura de adicionar capacidades de scripting definidas pelo usuário às nossas aplicações. Ao aproveitar as forças da BEAM VM e as capacidades de sandbox do Luerl, podemos criar sistemas flexíveis e extensíveis que permitem aos usuários personalizar comportamento sem comprometer a segurança.

Seja construindo sistemas de plugins, motores de configuração ou plataformas de regras de negócio, a combinação da robustez do Elixir e da simplicidade do Lua cria possibilidades convincentes para extensibilidade de aplicações.

A integração perfeita entre Elixir e Lua, combinada com as garantias de segurança de executar tudo na BEAM VM, faz desta biblioteca uma excelente escolha para aplicações que precisam executar lógica definida pelo usuário de forma segura e eficiente.