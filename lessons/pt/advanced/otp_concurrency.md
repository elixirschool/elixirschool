---
version: 1.0.3
title: Concorrência OTP
---

Já olhamos as abstrações em Elixir para concorrência, mas as vezes precisamos de um controle maior e para isso nós temos os comportamentos OTP no qual Elixir é construída em cima.

Nessa lição vamos nos focar na peça mais importante: GenServers.

{% include toc.html %}

## GenServer

Um servidor OTP é um módulo com o comportamento GenServer que implementa uma série de *callbacks*. No nível mais básico, um GenServer é um único processo que roda um loop que processa uma mensagem por interação passando para frente um estado atualizado.

Para demonstrar a API do GenServer nós vamos implementar uma fila básica para armazenar e retornar valores.

Para começar nosso GenServer nós precisamos iniciá-lo e processar a inicialização. Na maioria das vezes nós vamos querer criar um *link* entre processos, então precisamos usar `GenServer.start_link/3`. Nós passamos para o módulo GenServer que estamos iniciando os argumentos iniciais e uma lista de opções. Os argumentos são passados para `GenServer.init/1` que configura o estado inicial através de seu valor de retorno. No nosso exemplo, os argumentos serão nosso estado inicial:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Start our queue and link it.  This is a helper function
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}
end
```

### Funções síncronas

É geralmente necessário a interação com GenServers de uma maneira síncrona, chamando a função e esperando por sua resposta. Para processar mensagens síncronas nós precisamos implementar o *callback* `GenServer.handle_call/3` que recebe: a requisição, o PID do processo que chamou, um estado existente; é esperado o retorno na forma de uma tupla: `{:reply, resposta, estado}`.

Com casamento de padrão nós podemos definir *callbacks* para muitas diferentes requisições e estados. Uma completa lista de valores de retorno aceitos pode ser encontrada na [documentação do `GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3).

Para demonstrar as requisições síncronas, vamos adicionar as habilidades de mostrar nossa fila atual e remover um valor:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Vamos iniciar nossa SimpleQueue e testar nossa funcionalidade de desenfileirar:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.90.0>}
iex> SimpleQueue.dequeue
1
iex> SimpleQueue.dequeue
2
iex> SimpleQueue.queue
[3]
```

### Funções assíncronas

Requisições assíncronas são processadas pelo *callback* `handle_cast/2`. Funciona de forma parecida com `handle_call/3` mas não recebe o PID do processo que chama e não é esperada resposta.

Nós iremos implementar nossa funcionalidade de enfileirar assíncronamente, atualizando a fila mas não bloqueando nossa execução atual:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 callback
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2 callback
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Client API / Helper functions

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Vamos colocar nossa funcionalidade em uso:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.100.0>}
iex> SimpleQueue.queue
[1, 2, 3]
iex> SimpleQueue.enqueue(20)
:ok
iex> SimpleQueue.queue
[1, 2, 3, 20]
```

Para mais informações olhe a documentação oficial do [GenServer](https://hexdocs.pm/elixir/GenServer.html#content).
