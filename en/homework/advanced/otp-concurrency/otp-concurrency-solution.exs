defmodule SimpleQueue do
  use GenServer

  def init(state), do: {:ok, state}

  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  def handle_call({:enqueue, value}, _from, state) do
    {:reply, value, state ++ [value]}
  end

  def handle_call(:sum, _from, state), do: {:reply, Enum.sum(state), state}

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.call(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
  def sum, do: GenServer.call(__MODULE__, :sum)
end

ExUnit.start()

defmodule SimpleQueueTests do
  use ExUnit.Case

  test "Task 1" do
    SimpleQueue.start_link([1,2,3])
    assert SimpleQueue.queue() == [1,2,3]
    assert SimpleQueue.enqueue(20) == 20
    assert SimpleQueue.queue() == [1,2,3,20]
  end

  test "Task 2" do
    SimpleQueue.start_link([1,2,3,4,5,6,7])
    assert SimpleQueue.sum() == 28
    assert SimpleQueue.queue() == [1,2,3,4,5,6,7] # State is not modified
  end
end
