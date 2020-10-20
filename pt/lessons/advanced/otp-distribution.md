---
version: 1.0.1
title: Distribuição OTP
---

## Introdução à Distribuição
Nós podemos executar nossas aplicações Elixir em um conjunto diferente de nós, distribuídos em um único servidor ou entre múltiplos servidores. Elixir permite que nos comuniquemos entre esses nós por meio de alguns mecanismos diferentes, os quais iremos destacar nessa lição.

{% include toc.html %}

## Comunicação Entre Nós

Elixir roda em uma VM Erlang, o que significa que tem acesso à poderosa [funcionalidade de distribuição](http://erlang.org/doc/reference_manual/distributed.html) do Erlang.

> Um sistema Erlang distribuído consiste em vários sistemas Erlang em execução se comunicando uns com os outros.
Cada sistema em execução é chamado de nó.

Um nó é qualquer sistema Erlang em execução que possua um nome.
Podemos iniciar um nó abrindo uma sessão `iex` e nomeando-a:

```bash
iex --sname alex@localhost
iex(alex@localhost)>
```

Vamos abrir outro nó em outra janela do terminal:

```bash
iex --sname kate@localhost
iex(kate@localhost)>
```

Esses dois nós podem enviar mensagens entre si usando `Node.spawn_link/2`.

### Comunicando com `Node.spawn_link/2`

Essa função recebe dois argumentos:
* O nome do nó que você deseja se conectar
* A função a ser executada pelo processo remoto em execução no outro nó

Isso estabelece a conexão com o nó remoto e executa a função enviada para aquele nó, retornando o PID dos processos conectados.

Vamos definir um módulo, `Kate`, em um nó `kate` que sabe como apresentar Kate, a pessoa:

```elixir
iex(kate@localhost)> defmodule Kate do
...(kate@localhost)>   def say_name do
...(kate@localhost)>     IO.puts "Hi, my name is Kate"
...(kate@localhost)>   end
...(kate@localhost)> end
```

#### Enviando Mensagens

Agora, nós podemos usar [`Node.spawn_link/2`](https://hexdocs.pm/elixir/Node.html#spawn_link/2) para que o nó `alex` peça ao nó `kate` chamar a função `say_name/0`:

```elixir
iex(alex@localhost)> Node.spawn_link(:kate@localhost, fn -> Kate.say_name end)
Hi, my name is Kate
#PID<10507.132.0>
```

#### Uma Nota sobre I/O e Nós

Observe que, embora `Kate.say_name/0` esteja send executada no nó remoto, é o nó local (ou nó chamador), que recebe a saída de `IO.puts`.
Isso acontece porque o nó local é o **líder do grupo**.
A VM Erlang gerencia I/O por meio de processos.
Isso permite que executemos tarefas de I/O, como `IO.puts`, entre nós distribuídos.
Esses processos distribuídos são gerenciados por um processo de I/O líder do grupo.
O líder do grupo sempre é o nó que gerou os processos.
Então, como nosso nó `alex` é o nó do qual chamamos `spawn_link/2`, esse nó é o líder do grupo e a saída de `IO.puts` será direcionada para o fluxo de saída padrão desse nó.

#### Respondendo a Mensagens

E se quisermos que o nó que recebe a mensagem envie alguma *resposta* de volta ao rementente? Nós podemos usar uma configuração simples de `receive/1` e [`send/3`](https://hexdocs.pm/elixir/Process.html#send/3) para fazer exatamente isso.

Nós temos nosso nó `alex` gerando um link para o nó `kate` e enviando ao nó `kate` uma função anônima para executar.
Essa função anônima estará esperando receber uma tupla em particular, que descreve uma mensagem e o PID do nó `alex`.
E responderá a essa mensagem enviando de volta (via `send`) uma mensagem para o PID do nó `alex`:

```elixir
iex(alex@localhost)> pid = Node.spawn_link :kate@localhost, fn ->
...(alex@localhost)>   receive do
...(alex@localhost)>     {:hi, alex_node_pid} -> send alex_node_pid, :sup?
...(alex@localhost)>   end
...(alex@localhost)> end
#PID<10467.112.0>
iex(alex@localhost)> pid
#PID<10467.112.0>
iex(alex@localhost)> send(pid, {:hi, self()})
{:hi, #PID<0.106.0>}
iex(alex@localhost)> flush()
:sup?
:ok
```

#### Uma Nota sobre Comunicação entre Nós de Diferentes Redes

Se você deseja enviar mensagens entre nós de diferentes redes, precisamos iniciar os nós nomeados com um cookie compartilhado:

```bash
iex --sname alex@localhost --cookie secret_token
```

```bash
iex --sname kate@localhost --cookie secret_token
```

Somente nós iniciados com o mesmo `cookie` vão ser capazes de se conectar entre si com sucesso.

#### Limitações de `Node.spawn_link/2`

Enquanto `Node.spawn_link/2` ilustra as relações entre nós e a maneira como podemos enviar mensagens entre eles, essa não é a escolha certa para uma aplicação que será executada entre nós distribuídos.
`Node.spawn_link/2` gera processos isolados, ou seja, processos que não serão supervisionados.
Se ao menos houvese uma maneira de gerar processos supervisionados e assíncronos entre nós...

## Tarefas Distribuídas

[Tarefas distribuídas](https://hexdocs.pm/elixir/master/Task.html#module-distributed-tasks) permitem que geremos tarefas supervisionadas entre nós.
Nós vamos construir uma aplicação de supervisão simples que utiliza tarefas distribuídas para permitir que usuários conversem uns com os outros por meio de uma sessão `iex`, entre nós distribuídos.

### Definindo a Aplicação de Supervisão

Crie sua aplicação:

```
mix new chat --sup
```

### Adicionando a Tarefa de Supervisão na Árvore de Supervisão

Uma Tarefa de Supervisão supervisona dinamicamente tarefas.
Ela é iniciada sem filhos, normalmente _sob_ um supervisor próprio, e podemos usar depois para supervisionar qualquer número de tarefas.

Nós vamos adicionar a Tarefa de Supervisão à árvore de supervisão da nossa aplicação e chamá-la de `Chat.TaskSupervisor`

```elixir
# lib/chat/application.ex
defmodule Chat.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Chat.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Agora nós sabemos que sempre que nossa aplicação é iniciada em determinado nó, o `Chat.Supervisor` vai estar rodando e pronto para supervisionar tarefas.

### Enviando Mensagens com Tarefas de Supervisão

Nós vamos iniciar tarefas de supervisão com a função [`Task.Supervisor.async/5`](https://hexdocs.pm/elixir/master/Task.Supervisor.html#async/5).

Esta função deve receber quatro argumentos:

* O supervisor que nós queremos usar para supervisionar a tarefa.
This can be passed in as a tuple of `{SupervisorName, remote_node_name}` in order to supervise the task on the remote node.
* O nome do módulo no qual queremos executar uma função
* O nome da função que queremos executar
* Qualquer argumento que precise ser fornecido para essa função

Você pode passar um quinto e opcional argumento, descrevendo as opções de shutdown (desligamento).
Nós não vamos nos preocupar com isso aqui.

Nossa aplicação de Chat é super simples.
Ela envia mensagens a nós remotos e nós remotos responde a essas mensagens, passando-as para a função `IO.puts`, que será exibida no STDOUT (saída padrão) do nó remoto.

Primeiramente, vamos definir uma função, `Chat.receive_message/1`, que desejamos que nossa tarefa execute em um nó remoto.

```elixir
# lib/chat.ex
defmodule Chat do
  def receive_message(message) do
    IO.puts message
  end
end
```

Em seguida, vamos ensinar o módulo `Chat` como enviar a mensagem para o nó remoto usando uma tarefa supervisionada.
Nós vamos definir o método `Chat.send_message/2` que irá executar esse processo:

```elixir
# lib/chat.ex
defmodule Chat do
  ...

  def send_message(recipient, message) do
    spawn_task(__MODULE__, :receive_message, recipient, [message])
  end

  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  defp remote_supervisor(recipient) do
    {Chat.TaskSupervisor, recipient}
  end
end
```

Vamos ver isso em ação.

Em uma janela do terminal, inicie nosso app de chat em uma sessão `iex` nomeada

```bash
iex --sname alex@localhost -S mix
```

Abra outra janela no terminal para iniciar o app em um diferente nó nomeado:

```bash
iex --sname kate@localhost -S mix
```

Agora, do nó `alex`, nós podemos enviar uma mensagem para o nó `kate`:

```elixir
iex(alex@localhost)> Chat.send_message(:kate@localhost, "hi")
:ok
```

Alterne para a janela `kate` e você deve ver a mensagem:

```elixir
iex(kate@localhost)> hi
```

O nó `kate` pode responder de volta para o nó `alex`:

```elixir
iex(kate@localhost)> hi
Chat.send_message(:alex@localhost, "how are you?")
:ok
iex(kate@localhost)>
```

E a mensagem aparecerá na sessão `iex` do nó `alex`:

```elixir
iex(alex@localhost)> how are you?
```

Vamos revisar nosso código e detalhar o que está acontecendo aqui.

Nós temos uma função `Chat.send_message/2` que recebe o nome do nó remoto no qual queremos executar nossas tarefas supervisionadas e a mensagem que queremos enviar para esse nó.

Essa função chama nossa função `spawn_task/4` que inicia uma tarefa assíncrona em execução no nó remoto com o nome fornecido, supervisionada por `Chat.TaskSupervisor` naquele nó remoto.
Nós sabemos que a Tarefa de Supervisão com o nome `Chat.TaskSupervisor` está em execução naquele nó porque esse nó está _também_ executando uma instância da nossa aplicação Chat e `Chat.TaskSupervisor` é iniciada como parte da árvore de supervisão da app Chat.

Nós estamos dizendo para `Chat.TaskSupervisor` para supervisionar uma tarefa que executa a função `Chat.receive_message` que recebe como um argumento qualquer mensagem passada para `spawn_task/4` a partir da função `send_message/2`.

Então, `Chat.receive_message("hi")` é chamada no nó remoto, `kate`, o nó, faz com que a mensagem `"hi"` seja colocada no fluxo STDOUT (saída) desse nó.
Nesse caso, desde que a tarefa esteja sendo supervisionada no nó remoto, esse nó é o gerenciador do grupo para esse processo de I/O (Entrada/Saída)

### Respondendo a Mensagens de Nós Remotos

Vamos fazer nossa app Chat um pouco mais esperta.
Até agora, qualquer número de usuários podem executar a aplicação em uma sessão `iex` e iniciar o bate-papo.
Mas vamos dizer que haja um cachorro branco de porte médio chamado Moebi que não queria ficar de fora.
Moebi quer ser incluido na nossa app Chat mas infelizmente ele não sabe como digitar, porque ele é um cachorro.
Então, vamos ensinar nosso módulo `Chat` responder a qualquer mensagem enviada do nó chamado `moebi@localhost` em nome de Moebi.
Não importa o que você diga a Moebi, ele vai responder com `"chicken?"`, porque seu único desejo verdadeiro é comer frango.

Nós vamos definir outra versão da nossa função `send_message/2` cujo padrão casará com o argumento `recipient` (pattern matching).
Se o destinatário é `:moebi@locahost`, nós vamos

* Pegar o nome do nó atual usando `Node.self()`
* Passe o nome do nó atual, por exemplo, o remetente, para a nova função `receive_message_for_moebi/2`, para que possamos enviar uma mensagem _de volta_ para esse nó.

```elixir
# lib/chat.ex
...
def send_message(:moebi@localhost, message) do
  spawn_task(__MODULE__, :receive_message_for_moebi, :moebi@localhost, [message, Node.self()])
end
```

A seguir, vamos definir uma função `receive_message_for_moebi/2` que exibe a mensagem recebida no fluxo de STDOUT (saída) do nó `moebi` via `IO.puts` _e_ envia uma mensagem de volta para o remetente:

```elixir
# lib/chat.ex
...
def receive_message_for_moebi(message, from) do
  IO.puts message
  send_message(from, "chicken?")
end
```

Ao chamar `send_message/2` com o nome de um nó que enviou a mensagem original (o "nó rementente") nós estamos dizendo para o nó _remoto_ para gerar uma tarefa supervisionada de volta para esse nó rementente.

Vamos ver isso em ação.
Em três janelas diferentes do terminal, abra três diferentes nós nomeados:

```bash
iex --sname alex@localhost -S mix
```

```bash
iex --sname kate@localhost -S mix
```

```bash
iex --sname moebi@localhost -S mix
```

Vamos fazer `alex` enviar uma mensagem para `moebi`:

```elixir
iex(alex@localhost)> Chat.send_message(:moebi@localhost, "hi")
chicken?
:ok
```

Podemos ver que o nó `alex` recebeu a resposta `chicken?`.
Se abrirmos o nó `kate`, vamos ver que nenhuma mensagem foi recebida, uma vez que nem `alex` ou `moebi` enviaram uma mensagem para ela (desculpa, `kate`).
E se abrirmos a janela do terminal do nó `moebi`, vamos ver a mensagem que o nó `alex` enviou:

```elixir
iex(moebi@localhost)> hi
```

## Testando Código Distribuído

Vamos começar escrevendo um simples teste para nossa função `send_message`.

```elixir
# test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

Se nós executarmos nossos testes via `mix test`, veremos que ele falhará com o seguinte erro:

```elixir
** (exit) exited in: GenServer.call({Chat.TaskSupervisor, :moebi@localhost}, {:start_task, [#PID<0.158.0>, :monitor, {:sophie@localhost, #PID<0.158.0>}, {Chat, :receive_message_for_moebi, ["hi", :sophie@localhost]}], :temporary, nil}, :infinity)
         ** (EXIT) no connection to moebi@localhost
```

Esse erro faz total sentido -- nós não podemos conectar ao nó chamado `moebi@localhost` porque não existe tal nó em execução.

Nós podemos fazer esse teste passar executando alguns passos:

* Abra outra janela do terminal e execute o nó nomeado: `iex --sname moebi@localhost -S mix`
* Execute os testes no primeiro terminal por meio de um nó nomeado que executa `mix test` em uma sessão `iex` : `iex --sname sophie@localhost -S mix test`

É muito trabalhoso e definitivamente não seria considerado um processo de teste automatizado.

Tem duas abordagens diferentes que podemos usar aqui:

1.
Exclua condicionalmente tests que necessitem de nós distribuídos, se o nó necessário não estiver em execução.

2.
Configure nossa aplicação para evitar a geração de tarefas em nós remotos em um ambiente de teste.

Vamos dar uma olhada na primeira abordagem.

### Excluindo Testes Condicionalmente com Tags

Nós vamos adicionar uma tag `ExUnit` tag nesse teste:

```elixir
#test/chat_test.ex
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  @tag :distributed
  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

E vamos adicionar alguma lógica condicional ao nosso helper de teste para excluir testes com tais tags se os testes _não_ estão executando em um nó nomeado.

```elixir
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
```

Nós checamos se o nó está ativo, por exemplo,
se o nó faz parte do sistema distribuído com [`Node.alive?`](https://hexdocs.pm/elixir/Node.html#alive?/0).
Se não, podemos dizer a `ExUnit` para pular qualquer teste com a tag `distributed: true`.
Caso contrário, diremos para não excluir nenhum teste.

Agora, se nós executarmos o velho `mix test`, veremos:

```bash
mix test
Excluding tags: [distributed: true]

Finished in 0.02 seconds
1 test, 0 failures, 1 excluded
```

E se quisermos executar nossos testes distribuídos, simplesmente precisamos seguir os passos descritos na seção anterior:  executar o nó `moebi@localhost` _e_ rodar os testes em um nó nomeado por meio de `iex`.

Vamos dar uma olhada em nossa outra abordagem de teste - configurar a aplicação para se comportar de maneira diferente em ambientes diferentes.

### Configuração da Aplicação Específicas por Ambiente

A parte do nosso código que diz a `Task.Supervisor` para iniciar uma tarefa supervisionada em um nó remoto está aqui:

```elixir
# app/chat.ex
def spawn_task(module, fun, recipient, args) do
  recipient
  |> remote_supervisor()
  |> Task.Supervisor.async(module, fun, args)
  |> Task.await()
end

defp remote_supervisor(recipient) do
  {Chat.TaskSupervisor, recipient}
end
```

`Task.Supervisor.async/5` recebe como primeiro argumento o supervisor que desejamos usar.
Se passarmos uma tupla `{SupervisorName, location}`, isso iniciará o supervisor recebido no nó remoto fornecido.
No entanto, se passarmos a `Task.Supervisor` como primeiro argumento o nome do supervisor, esse supervisor será usado para supervisionar a tarefa localmente.

Vamos criar uma função `remote_supervisor/1`, configurável com base no ambiente
Se for um ambiente de desenvolvimento, ela retornará `{Chat.TaskSupervisor, recipient}` e no ambiente de teste, retornará `Chat.TaskSupervisor`.

Vamos fazer isso por meio de variáveis de ambiente.

Crie um arquivo, `config/dev.exs`, e adicione:

```elixir
# config/dev.exs
use Mix.Config
config :chat, remote_supervisor: fn(recipient) -> {Chat.TaskSupervisor, recipient} end
```

Crie um arquivo, `config/test.exs` e adicione:

```elixir
# config/test.exs
use Mix.Config
config :chat, remote_supervisor: fn(_recipient) -> Chat.TaskSupervisor end
```

Lembre-se de descomentar essa linha no arquivo `config/config.exs`:

```elixir
use Mix.Config
import_config "#{Mix.env()}.exs"
```

Por último, vamos atualizar nossa função `Chat.remote_supervisor/1` para pesquisar e usar a função armazenada em uma variável da nossa aplicação:

```elixir
# lib/chat.ex
defp remote_supervisor(recipient) do
  Application.get_env(:chat, :remote_supervisor).(recipient)
end
```

## Conclusão

A capacidade de distribuição nativa de Elixir, que a possui graças ao poder da VM Erlang, é um dos recursos que torna a linguagem uma ferramenta tão poderosa.
Nós podemos imaginar o uso dessa abilidade do Elixir para lidar com computação distribuída, para executar background jobs concorrentes, para oferecer suporte a aplicações de alto desempenho, para executar operações onerosas -- você escolhe.

Essa lição nos dá uma introdução básica ao conceito de distribuição em Elixir e fornece as ferramentas que você precisa para começar a construir aplicações distribuídas.
Por meio de tarefas supervisionadas, você pode enviar mensagens entre vários nós de uma aplicação distribuída.
