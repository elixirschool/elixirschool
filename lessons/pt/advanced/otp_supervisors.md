%{
  version: "1.1.1",
  title: "Supervisores OTP",
  excerpt: """
  Supervisores são processos especializados com um propósito: monitorar outros processos. Estes supervisores nos possibilitam a criação de aplicações tolerantes a falhas automaticamente reiniciando processos filhos quando eles falham.
  """
}
---

## Configuração

A magia de Supervisores está na função `Supervisor.start_link/2`. Além de iniciar nosso supervisor e filhos, nos permite definir a estratégia que nosso supervisor irá usar para gerenciar os processos filhos.

Usando o SimpleQueue da lição [OTP Concurrency](../../advanced/otp-concurrency) vamos começar:

Crie um novo projeto usando `mix new simple_queue --sup` para criar uma nova árvore de supervisão. O código para o módulo `SimpleQueue` deve ir em `lib/simple_queue.ex` e o código do supervisor que nós vamos adicionar vai em `lib/simple_queue/application.ex`

Filhos são definidos usando uma lista, pode ser uma lista com nome de módulos:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      SimpleQueue
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

ou uma lista de tuplas se você deseja incluir opções de configuração:

```elixir
defmodule SimpleQueue.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SimpleQueue, [1, 2, 3]}
    ]

    opts = [strategy: :one_for_one, name: SimpleQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Se nós rodarmos `iex -S mix` nós vamos ver que nosso `SimpleQueue` é automaticamente iniciado:

```elixir
iex> SimpleQueue.queue
[1, 2, 3]
```

Se o nosso `SimpleQueue` fosse falhar ou ser encerrado, nosso Supervisor iria automaticamente reiniciar este processo como se nada tivesse acontecido.

### Estratégias

Atualmente, existem três estratégias diferentes de reinicialização disponíveis aos supervisores:

+ `:one_for_one` - Apenas reinicia os processos filhos que falharem.

+ `:one_for_all` - Reinicia todos os processos filhos no evento da falha.

+ `:rest_for_one` - Reinicia o processo que falhou e qualquer processo que começou depois deste.

## Especificação dos filhos

Depois que o supervisor iniciou, ele deve saber como iniciar/parar/reiniciar seus filhos. Cada módulo filho deve ter uma função `child_spec/2` para definir esses comportamentos. Os macros `use GenServer`, `use Supervisor` e `use Agent` automaticamente definem esse método para nós (`SimpleQueue` usa `use GenServer`, então nós não precisamos modificar o módulo), mas se você precisar definir você mesmo `child_spec/1` deve return um map de opções:

```elixir
def child_spec(opts) do
  %{
    id: SimpleQueue,
    start: {__MODULE__, :start_link, [opts]},
    shutdown: 5_000,
    restart: :permanent,
    type: :worker
  }
end
```

+ `id` - Chave obrigatória. Usada pelo supervisor para identificar a especificação do filho.

+ `start` - Chave obrigatória. O Módulo/Função/Argumentos para chamar quando iniciar o supervisor.

+ `shutdown` - Chave opcional. Define o comportamento do filho durante o desligamento. Opções são:

  + `:brutal_kill` - O filho é parado imediatamente.

  + qualquer inteiro positivo - tempo em milisegundos que o supervisor vai esperar antes de matar o processo filho. Se o processo é do tipo `:worker`, esse valor é por padrão 5000.

  + `:infinity` - O Supervisor vai esperar indefinidamente antes de matar o processo filho. Padrão para processos do tipo `:supervisor`. Não recomendado para o tipo `:worker`.

+ `restart` - Chave opcional. Há várias abordagens para lidar com a quebra de processos filhos:

  + `:permanent` - O processo filho é sempre reiniciado. Padrão para todos os processos

  + `:temporary` - O processo filho nunca é reiniciado.

  + `:transient` - O processo filho é reiniciado se ele termina de maneira anormal.

+ `type` - Chave opcional. Processos podem  ser `:worker` ou `:supervisor`. Por padrão é `:worker`.

## DynamicSupervisor

Supervisores normalmente começam com uma lista de filhos para iniciar quando a aplicação inicia. No entanto, às vezes os filhos supervisionados não vão ser conhecidos quando a aplicação inicia (por exemplo, nós podemos ter uma aplicação web que inicia um processo para lidar com a conexão de um usuário em nosso site). Para esses caso nós vamos querer um supervisor que os filhos podem ser iniciados sob demanda. O DynamicSupervisor é usado para lidar com esse caso.

Já que nós não vamos especificar os filhos, nós precisamos apenas definir as opções de tempo de execução do supervisor. O DynamicSupervisor suporta apenas a estratégia de supervisão `:one_for_one`:

```elixir
options = [
  name: SimpleQueue.Supervisor,
  strategy: :one_for_one
]

DynamicSupervisor.start_link(options)
```

Então, para iniciar um novo SimpleQueue dinamicamente nós vamos usar `start_child/2` que recebe um supervisor e a especificação do filho (de novo, `SimpleQueue` usa `use GenServer` então a especificação do filho já é definida):

```elixir
{:ok, pid} = DynamicSupervisor.start_child(SimpleQueue.Supervisor, SimpleQueue)
```

## Supervisor de tarefas

Tarefas têm o seu próprio Supervisor especializado, o `Task.Supervisor`. Projetado para tarefas criadas dinamicamente, o supervisor usa `DynamicSupervisor` por debaixo dos panos.

### Instalação

Incluir o `Task.Supervisor` não é diferente de outros supervisores:

```elixir
children = [
  {Task.Supervisor, name: ExampleApp.TaskSupervisor, restart: :transient}
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

A maior diferença entre `Supervisor` e `Task.Supervisor` é que a estratégia de reinício padrão é `:temporary` (tarefas nunca irão ser reiniciadas).

### Tarefas Supervisionadas

Com o supervisor inicializado, podemos usar a função `start_child/2` para criar uma tarefa supervisionada:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Se a nossa tarefa quebrar prematuramente, ela irá ser reiniciada para nós. Isto pode ser particularmente útil quando se trabalha com conexões de entrada ou processamento em background.
