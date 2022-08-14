%{
  version: "1.1.0",
  title: "OTP Distribution",
  excerpt: """
  We can run our Elixir apps on a set of different nodes distributed across a single host or across multiple hosts.
  Elixir allows us to communicate across these nodes via a few different mechanisms which we will outline in this lesson.
  """
}
---

## Communication Between Nodes

Elixir runs on the Erlang VM, which means it has access to Erlang's powerful [distribution functionality.](http://erlang.org/doc/reference_manual/distributed.html)

> A distributed Erlang system consists of a number of Erlang runtime systems communicating with each other.
Each such runtime system is called a node.

A node is any Erlang runtime system that has been given a name.
We can start a node by opening up `iex` session and naming it:

```bash
iex --sname alex@localhost
iex(alex@localhost)>
```

Let's open up another node in another terminal window:

```bash
iex --sname kate@localhost
iex(kate@localhost)>
```

These two nodes can send messages to one another using `Node.spawn_link/2`.

### Communicating with Node.spawn_link/2

This function takes in two arguments:

* The name of the node to which you want to connect
* The function to be executed by the remote process running on that node

It establishes the connection to the remote node and executes the given function on that node, returning the PID of the linked process.

Let's define a module, `Kate`, in the `kate` node that knows how to introduce Kate, the person:

```elixir
iex(kate@localhost)> defmodule Kate do
...(kate@localhost)>   def say_name do
...(kate@localhost)>     IO.puts "Hi, my name is Kate"
...(kate@localhost)>   end
...(kate@localhost)> end
```

#### Sending Messages

Now, we can use [`Node.spawn_link/2`](https://hexdocs.pm/elixir/Node.html#spawn_link/2) to have the `alex` node ask the `kate` node to call the `say_name/0` function:

```elixir
iex(alex@localhost)> Node.spawn_link(:kate@localhost, fn -> Kate.say_name end)
Hi, my name is Kate
#PID<10507.132.0>
```

#### A Note on I/O and Nodes

Notice that, although `Kate.say_name/0` is getting executed on the remote node, it is the local, or calling, node that receives the `IO.puts` output.
That is because the local node is the **group leader**.
The Erlang VM manages I/O via processes.
This allows us to execute I/O tasks, like `IO.puts`, across distributed nodes.
These distributed processes are managed by the I/O process group leader.
The group leader is always the node that spawns the process.
So, since our `alex` node is the one from which we called `spawn_link/2`, that node is the group leader and the output of `IO.puts` will be directed to the standard output stream of that node.

#### Responding to Messages

What if we want the node that receives the message to send some *response* back to the sender? We can use a simple `receive/1` and [`send/3`](https://hexdocs.pm/elixir/Process.html#send/3) setup to accomplish exactly that.

We'll have our `alex` node spawn a link to the `kate` node and give the `kate` node an anonymous function to execute.
That anonymous function will listen for the receipt of a particular tuple describing a message and the PID of the `alex` node.
It will respond to that message by `send`-ing back a message to the PID of the `alex` node:

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

#### A Note On Communicating Between Nodes on Different Networks

If you want to send messages between nodes on different networks, we need to start the named nodes with a shared cookie:

```bash
iex --sname alex@localhost --cookie secret_token
```

```bash
iex --sname kate@localhost --cookie secret_token
```

Only nodes started with the same `cookie` will be able to successfully connect to one another.

#### Node.spawn_link/2 Limitations

While `Node.spawn_link/2` illustrates the relationships between nodes and the manner in which we can send messages between them, it is *not* really the right choice for an application that will run across distributed nodes.
`Node.spawn_link/2` spawns processes in isolation, i.e. processes that are not supervised.
If only there was a way to spawn supervised, asynchronous processes *across nodes*...

## Distributed Tasks

[Distributed tasks](https://hexdocs.pm/elixir/master/Task.html#module-distributed-tasks) allow us to spawn supervised tasks across nodes.
We'll build a simple supervisor application that leverages distributed tasks to allow users to chat with one another via an `iex` session, across distributed nodes.

### Defining the Supervisor Application

Generate your app:

```shell
mix new chat --sup
```

### Adding the Task Supervisor to the Supervision Tree

A Task Supervisor dynamically supervises tasks.
It is started with no children, often *under* a supervisor of its own, and can be used later on to supervise any number of tasks.

We'll add a Task Supervisor to our app's supervision tree and name it `Chat.TaskSupervisor`

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

Now we know that wherever our application is started on a given node, the `Chat.Supervisor` is running and ready to supervise tasks.

### Sending Messages with Supervised Tasks

We'll start supervised tasks with the [`Task.Supervisor.async/5`](https://hexdocs.pm/elixir/master/Task.Supervisor.html#async/5) function.

This function must take in four arguments:

* The supervisor we want to use to supervise the task.
This can be passed in as a tuple of `{SupervisorName, remote_node_name}` in order to supervise the task on the remote node.
* The name of the module on which we want to execute a function
* The name of the function we want to execute
* Any arguments that need to be supplied to that function

You can pass in a fifth, optional argument describing shutdown options.
We won't worry about that here.

Our Chat application is pretty simple.
It sends messages to remote nodes and remote nodes respond to those messages by `IO.puts`-ing them out to the STDOUT of the remote node.

First, let's define a function, `Chat.receive_message/1`, that we want our task to execute on a remote node.

```elixir
# lib/chat.ex
defmodule Chat do
  def receive_message(message) do
    IO.puts message
  end
end
```

Next up, let's teach the `Chat` module how to send the message to a remote node using a supervised task.
We'll define a method `Chat.send_message/2` that will enact this process:

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

Let's see it in action.

In one terminal window, start up our chat app in a named `iex` session

```bash
iex --sname alex@localhost -S mix
```

Open up another terminal window to start the app on a different named node:

```bash
iex --sname kate@localhost -S mix
```

Now, from the `alex` node, we can send a message to the `kate` node:

```elixir
iex(alex@localhost)> Chat.send_message(:kate@localhost, "hi")
:ok
```

Switch to the `kate` window and you should see the message:

```elixir
iex(kate@localhost)> hi
```

The `kate` node can respond back to the `alex` node:

```elixir
iex(kate@localhost)> hi
Chat.send_message(:alex@localhost, "how are you?")
:ok
iex(kate@localhost)>
```

And it will show up in the `alex` node's `iex` session:

```elixir
iex(alex@localhost)> how are you?
```

Let's revisit our code and break down what's happening here.

We have a function `Chat.send_message/2` that takes in the name of the remote node on which we want to run our supervised tasks and the message we want to send that node.

That function calls our `spawn_task/4` function which starts an async task running on the remote node with the given name, supervised by the `Chat.TaskSupervisor` on that remote node.
We know that the Task Supervisor with the name `Chat.TaskSupervisor` is running on that node because that node is *also* running an instance of our Chat application and the `Chat.TaskSupervisor` is started up as part of the Chat app's supervision tree.

We are telling the `Chat.TaskSupervisor` to supervise a task that executes the `Chat.receive_message` function with an argument of whatever message was passed down to `spawn_task/4` from `send_message/2`.

So, `Chat.receive_message("hi")` is called on the remote, `kate`, node, causing the message `"hi"`, to be put out to that node's STDOUT stream.
In this case, since the task is being supervised on the remote node, that node is the group manager for this I/O process.

### Responding to Messages from Remote Nodes

Let's make our Chat app a little smarter.
So far, any number of users can run the application in a named `iex` session and start chatting.
But let's say there is a medium-sized white dog named Moebi who doesn't want to be left out.
Moebi wants to be included in the Chat app but sadly he does not know how to type, because he is a dog.
So, we'll teach our `Chat` module to respond to any messages sent to a node named `moebi@localhost` on Moebi's behalf.
No matter what you say to Moebi, he will respond with `"chicken?"`, because his one true desire is to eat chicken.

We'll define another version of our `send_message/2` function that pattern matches on the `recipient` argument.
If the recipient is `:moebi@locahost`, we will

* Grab the name of the current node using `Node.self()`
* Give the name of the current node, i.e. the sender, to a new function `receive_message_for_moebi/2`, so that we can send a message *back* to that node.

```elixir
# lib/chat.ex
...
def send_message(:moebi@localhost, message) do
  spawn_task(__MODULE__, :receive_message_for_moebi, :moebi@localhost, [message, Node.self()])
end
```

Next up, we'll define a function `receive_message_for_moebi/2` that `IO.puts` out the message in the `moebi` node's STDOUT stream *and* sends a message back to the sender:

```elixir
# lib/chat.ex
...
def receive_message_for_moebi(message, from) do
  IO.puts message
  send_message(from, "chicken?")
end
```

By calling `send_message/2` with the name of the node that sent the original message (the "sender node") we are telling the *remote* node to spawn an supervised task back on that sender node.

Let's see it in action.
In three different terminal windows, open three different named nodes:

```bash
iex --sname alex@localhost -S mix
```

```bash
iex --sname kate@localhost -S mix
```

```bash
iex --sname moebi@localhost -S mix
```

Let's have `alex` send a message to `moebi`:

```elixir
iex(alex@localhost)> Chat.send_message(:moebi@localhost, "hi")
chicken?
:ok
```

We can see that the `alex` node received the response, `"chicken?"`.
If we open the `kate` node, we'll see that no message was received, since neither `alex` nor `moebi` send her one (sorry `kate`).
And if we open the `moebi` node's terminal window, we'll see the message that the `alex` node sent:

```elixir
iex(moebi@localhost)> hi
```

## Testing Distributed Code

Let's start by writing a simple test for our `send_message` function.

```elixir
# test/chat_test.exs
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

If we run our tests via `mix test`, we see it fail with the following error:

```elixir
** (exit) exited in: GenServer.call({Chat.TaskSupervisor, :moebi@localhost}, {:start_task, [#PID<0.158.0>, :monitor, {:sophie@localhost, #PID<0.158.0>}, {Chat, :receive_message_for_moebi, ["hi", :sophie@localhost]}], :temporary, nil}, :infinity)
         ** (EXIT) no connection to moebi@localhost
```

This error makes perfect sense--we can't connect to a node named `moebi@localhost` because there is no such node running.

We can get this test passing by performing a few steps:

* Open another terminal window and run the named node: `iex --sname moebi@localhost -S mix`
* Run the tests in the first terminal via a named node that runs the mix tests in an `iex` session: `iex --sname sophie@localhost -S mix test`

This is a lot of work and definitely wouldn't be considered an automated testing process.

There are a two different approaches we could take here:

1. Conditionally exclude tests that need distributed nodes, if the necessary node is not running.
2. Configure our application to avoid spawning tasks on remote nodes in the test environment.

Let's take a look at the first approach.

### Conditionally Excluding Tests with Tags

We'll add an `ExUnit` tag to this test:

```elixir
# test/chat_test.exs
defmodule ChatTest do
  use ExUnit.Case, async: true
  doctest Chat

  @tag :distributed
  test "send_message" do
    assert Chat.send_message(:moebi@localhost, "hi") == :ok
  end
end
```

And we'll add some conditional logic to our test helper to exclude tests with such tags if the tests are *not* running on a named node.

```elixir
# test/test_helper.exs
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
```

We check to see if the node is alive, i.e.
if the node is part of a distributed system with [`Node.alive?`](https://hexdocs.pm/elixir/Node.html#alive?/0).
If not, we can tell `ExUnit` to skip any tests with the `distributed: true` tag.
Otherwise, we will tell it not to exclude any tests.

Now, if we run plain old `mix test`, we'll see:

```bash
mix test
Excluding tags: [distributed: true]

Finished in 0.02 seconds
1 test, 0 failures, 1 excluded
```

And if we want to run our distributed tests, we simply need to go through the steps outlined in the previous section: run the `moebi@localhost` node *and* run the tests in a named node via `iex`.

Let's take a look at our other testing approach--configuring the application to behave differently in different environments.

### Environment-Specific Application Configuration

The part of our code that tells `Task.Supervisor` to start a supervised task on a remote node is here:

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

`Task.Supervisor.async/5` takes in a first argument of the supervisor we want to use.
If we pass in a tuple of `{SupervisorName, location}`, it will start up the given supervisor on the given remote node.
However, if we pass `Task.Supervisor` a first argument of a supervisor name along, it will use that supervisor to supervise the task locally.

Let's make the `remote_supervisor/1` function configurable based on environment.
In the development environment, it will return `{Chat.TaskSupervisor, recipient}` and in the test environment it will return `Chat.TaskSupervisor`.

We'll do this via application variables.

Create a file, `config/dev.exs`, and add:

```elixir
# config/dev.exs
import Config
config :chat, remote_supervisor: fn(recipient) -> {Chat.TaskSupervisor, recipient} end
```

Create a file, `config/test.exs` and add:

```elixir
# config/test.exs
import Config
config :chat, remote_supervisor: fn(_recipient) -> Chat.TaskSupervisor end
```

Remember to uncomment this line in `config/config.exs`:

```elixir
import Config
import_config "#{config_env()}.exs"
```

Lastly, we'll update our `Chat.remote_supervisor/1` function to look up and use the function stored in our new application variable:

```elixir
# lib/chat.ex
defp remote_supervisor(recipient) do
  Application.get_env(:chat, :remote_supervisor).(recipient)
end
```

## Conclusion

Elixir's native distribution capabilities, which it has thanks to the power of the Erlang VM, is one of the features that make it such a powerful tool.
We can imagine leveraging Elixir's ability to handle distributed computing to run concurrent background jobs, to support high-performance applications, to run expensive operations--you name it.

This lesson gives us a basic introduction to the concept of distribution in Elixir and gives you the tools you need to start building distributed applications.
By using supervised tasks, you can send messages across the various nodes of a distributed application.
