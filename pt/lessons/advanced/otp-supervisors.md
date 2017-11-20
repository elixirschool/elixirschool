---
version: 0.9.1
title: Supervisores OTP
---

Supervisores são processos especializados com um propósito: monitorar outros processos. Estes supervisores nos possibilitam a criação de aplicações tolerantes a falhas automaticamente reiniciando processos filhos quando eles falham.

{% include toc.html %}

## Configuração

A magia de Supervisores está na função `Supervisor.start_link/2`. Além de iniciar nosso supervisor e filhos, nos permite definir a estratégia que nosso supervisor irá usar para gerenciar os processos filhos.

Filhos são definidos usando uma lista e a função `worker/3` que nós importamos de `Supervisor.Spec`. A função `worker/3` pega um módulo, argumentos e um conjunto de opções. Por baixo dos panos, `worker/3` chama `start_link/3` com nossos argumentos durante a inicialização.

Usando o SimpleQueue da lição [OTP Concurrency](../../advanced/otp-concurrency) vamos começar:

```elixir
import Supervisor.Spec

children = [
  worker(SimpleQueue, [], name: SimpleQueue)
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

Se o nosso processo fosse falhar ou ser encerrado, nosso Supervisor iria automaticamente reiniciar este processo como se nada tivesse acontecido.

### Estratégias

Atualmente, existem quatro estratégias diferentes de reinicialização disponíveis aos supervisores:

+ `:one_for_one` - Apenas reinicia os processos filhos que falharem.

+ `:one_for_all` - Reinicia todos os processos filhos no evento da falha.

+ `:rest_for_one` - Reinicia o processo que falhou e qualquer processo que começou depois deste.

+ `:simple_one_for_one` - O melhor para processos filhos dinamicamente adicionados. É requerido que o Supervisor.Spec tenha apenas um filho, mas este filho pode ser gerado múltiplas vezes. Esta estratégia se destina a ser usada quando precisamos dinamicamente iniciar ou parar filhos supervisionados.

### Nesting

Além de processos de trabalho também podemos supervisionar surpevisores para criar uma árvore de supervisores. A única diferença para nós é trocar `supervisor/3` por `worker/3`.

```elixir
import Supervisor.Spec

children = [
  supervisor(ExampleApp.ConnectionSupervisor, [[name: ExampleApp.ConnectionSupervisor]]),
  worker(SimpleQueue, [[], [name: SimpleQueue]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

## Supervisor de tarefas

Tarefas têm o seu próprio Supervisor especializado, o `Task.Supervisor`. Projetado para tarefas criadas dinamicamente. O supervisor usa `:simple_one_for_one` por debaixo dos panos.

### Instalação

Incluir o `Task.Supervisor` não é diferente de outros supervisores:

```elixir
import Supervisor.Spec

children = [
  supervisor(Task.Supervisor, [[name: ExampleApp.TaskSupervisor]])
]

{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
```

### Tarefas Supervisionadas

Com o supervisor inicializado, podemos usar a função `start_child/2` para criar uma tarefa supervisionada:

```elixir
{:ok, pid} = Task.Supervisor.start_child(ExampleApp.TaskSupervisor, fn -> background_work end)
```

Se a nossa tarefa quebrar prematuramente, ela irá ser reiniciada para nós. Isto pode ser particularmente útil quando se trabalha com conexões de entrada ou processamento em background.
