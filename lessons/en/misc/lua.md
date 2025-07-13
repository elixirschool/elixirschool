%{
  version: "1.0.0",
  title: "Lua",
  excerpt: """
  The Lua library provides an ergonomic interface to Luerl, enabling safe execution of sandboxed Lua scripts directly on the BEAM VM. In this lesson, we'll explore how to embed Lua scripting capabilities into our Elixir applications for user-defined logic, configuration, and extensibility.
  """
}
---

The [Lua library](https://github.com/tv-labs/lua) for Elixir is an ergonomic wrapper around [Luerl](https://github.com/rvirding/luerl), Robert Virding's pure Erlang implementation of Lua 5.3. Unlike other approaches that rely on NIFs or other mechanisms, this implementation runs entirely on the BEAM VM while providing excellent sandboxing and integration capabilities.

## Why Use Lua in Elixir?

So why might we want to use Lua when Elixir itself is such a powerful language? While Elixir is incredibly powerful, it comes with certain risks when executing user-provided code. Elixir's hot code loading feature, which allows modules to be replaced at runtime, means that evaluating untrusted Elixir code could potentially overwrite existing modules in our running application or introduce malicious code that persists beyond the evaluation context! This makes direct evaluation of user-provided Elixir code extremely dangerous in production environments and strongly discouraged.

Lua provides a safer alternative that allows us to execute user code which in turn enriches our applications with features like user defined business logic and complex system configuration.

## Installation

Add the Lua library to our `mix.exs` dependencies:

```elixir
defp deps do
  [
    {:lua, "~> 0.1.0"}
  ]
end
```

Then run:

```shell
mix deps.get
```

## Basic Usage

Let's start with the simplest possible example evaluating Lua code:

```elixir
iex> {result, _state} = Lua.eval!("return 2 + 3")
{[5], #PID<0.123.0>}
iex> result
[5]
```

The `Lua.eval!/2` function returns a tuple containing the results (as a list) and the Lua state. Even simple expressions return results as lists because Lua functions can return multiple values.

### The ~LUA Sigil

The Lua library provides a `~LUA` sigil that validates Lua syntax at compile time:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> {[7], _state} = Lua.eval!(~LUA[return 3 + 4])
{[7], #PID<0.124.0>}
```

If we try to use invalid Lua syntax, we'll get a compile-time error:

```elixir
iex> {result, _state} = Lua.eval!(~LUA[return 2 +])
** (Lua.CompilerException) Failed to compile Lua!
```

### Compile-time Optimization

Using the `c` modifier with the sigil compiles our Lua code into a `Lua.Chunk.t()` at compile-time, improving runtime performance:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> {[42], _state} = Lua.eval!(~LUA[return 6 * 7]c)
{[42], #PID<0.125.0>}
```

## Working with Lua State

Each Lua execution environment maintains its own state, including variables, functions, and data. We can create and manipulate this state:

```elixir
iex> lua = Lua.new()
#PID<0.126.0>

# Set a variable
iex> lua = Lua.set!(lua, [:my_var], 42)
#PID<0.126.0>

# Read it back
iex> {[42], _state} = Lua.eval!(lua, "return my_var")
{[42], #PID<0.126.0>}
```

We can also work with nested data structures:

```elixir
iex> lua = Lua.new()
iex> lua = Lua.set!(lua, [:config, :database, :port], 5432)
iex> {[5432], _state} = Lua.eval!(lua, "return config.database.port")
{[5432], #PID<0.127.0>}
```

## Exposing Elixir Functions to Lua

### Simple Function Exposure

The most straightforward way to expose an Elixir function to Lua is using `Lua.set!/3`:

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

Note that Elixir functions exposed to Lua should:
- Accept a list of arguments
- Return a list of results (even for single values)

### Using the deflua Macro

For more complex APIs, the `deflua` macro provides a cleaner syntax:

```elixir
defmodule MathAPI do
  use Lua.API

  deflua add(a, b), do: a + b
  deflua multiply(a, b), do: a * b
  deflua power(base, exponent), do: :math.pow(base, exponent)
end

# Load the API into a Lua state
iex> lua = Lua.new() |> Lua.load_api(MathAPI)
iex> {[16.0], _state} = Lua.eval!(lua, ~LUA[return power(2, 4)])
{[16.0], #PID<0.129.0>}
```

### Scoped APIs

We can organize functions under namespaces using the `:scope` option:

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

## Advanced API Patterns

### Working with Lua Tables

When working with complex Lua data structures, we can use `Lua.Table.as_list/1` to convert Lua tables back to Elixir lists:

```elixir
defmodule Queue do
  use Lua.API, scope: "q"

  deflua push(v), state do
    # Pull out the global variable "my_queue" from lua
    queue = Lua.get!(state, [:my_queue])
    
    # Call the Lua function table.insert(table, value)
    {[], state} = Lua.call_function!(state, [:table, :insert], [queue, v])
    
    # Return the modified lua state with no return values
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

### Calling Lua Functions from Elixir

We can also call Lua functions from our Elixir code using `Lua.call_function!/3`:

```elixir
defmodule StringProcessorAPI do
  use Lua.API, scope: "processor"

  deflua process_with_lua(text), state do
    # Call a Lua function to process the text
    Lua.call_function!(state, [:string, :upper], [text])
  end
end

iex> lua = Lua.new() |> Lua.load_api(StringProcessorAPI)
iex> {["PROCESSED"], _state} = Lua.eval!(lua, ~LUA[return processor.process_with_lua("processed")])
```

## Data Types and Encoding

When working with Lua, understanding how Elixir data types map to Lua is crucial:

| Elixir Type | Lua Type | Encoding Required? |
|-------------|----------|-------------------|
| `nil` | `nil` | No |
| `boolean()` | `boolean` | No |
| `number()` | `number` | No |
| `binary()` | `string` | No |
| `atom()` | `string` | Yes |
| `map()` | `table` | Yes |
| `list()` | `table` | Maybe* |
| `{:userdata, any()}` | `userdata` | Yes |

*Lists require encoding only if they contain elements that need encoding.

### Working with Maps and Tables

Elixir maps become Lua tables when encoded:

```elixir
iex> config = %{database: %{host: "localhost", port: 5432}, debug: true}
iex> {encoded_config, lua} = Lua.encode!(Lua.new(), config)
iex> lua = Lua.set!(lua, [:config], encoded_config)
iex> {[5432], _state} = Lua.eval!(lua, "return config.database.port")
{[5432], #PID<0.131.0>}
```

### User Data for Complex Structures

For passing around complex Elixir data structures that we don't want Lua to modify:

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

## Private Context and Security

One of the most powerful features is the ability to maintain private context that's accessible to our Elixir code but hidden from Lua scripts:

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

# Set up the execution context
user = %{id: 1, name: "Alice"}
permissions = %{1 => ["read_posts", "write_comments"]}

lua = 
  Lua.new()
  |> Lua.put_private(:current_user, user)
  |> Lua.put_private(:permissions, permissions)
  |> Lua.load_api(UserAPI)

# User can only access their name and check permissions
{["Alice"], _state} = Lua.eval!(lua, ~LUA[return user.get_name()])
{[true], _state} = Lua.eval!(lua, ~LUA[return user.get_permission("read_posts")])
{[false], _state} = Lua.eval!(lua, ~LUA[return user.get_permission("admin_panel")])
```

## Real-World Example: Configuration Engine

Let's build a practical example that allows users to define complex business rules:

```elixir
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
      12 -> 0.9  # December discount
      1 -> 0.95  # January discount
      _ -> 1.0
    end
    {[modifier], state}
  end
end

defmodule ConfigEngine do
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

Now users can define complex pricing logic unique to their needs without us having to code many different scenarios into our application:

```elixir
pricing_script = ~LUA"""
base_price = pricing.get_base_price(product_type)
subtotal = base_price * quantity

discount = pricing.calculate_discount(user_tier, subtotal)
seasonal_modifier = pricing.apply_seasonal_modifier(current_month)

final_price = subtotal * (1 - discount) * seasonal_modifier
return final_price
"""c

# Calculate price for a premium user buying 5 widgets in December
price = ConfigEngine.calculate_price("widget", 5, "premium", pricing_script)
# Result: 50 * 0.8 * 0.9 = 36.0
```

## Error Handling and Debugging

The Lua library provides improved error messages compared to raw Luerl:

```elixir
iex> try do
...>   Lua.eval!("return undefined_function()")
...> rescue
...>   e -> IO.puts("Lua error: #{inspect(e)}")
...> end
```

For compile-time validation errors:

```elixir
iex> import Lua, only: [sigil_LUA: 2]
iex> try do
...>   ~LUA[return 2 +]
...> rescue
...>   e in Lua.CompilerException -> IO.puts("Compile error: #{e.message}")
...> end
Compile error: Failed to compile Lua!
```

For debugging we can inspect the Lua state:

```elixir
iex> lua = Lua.new() |> Lua.set!([:debug_var], "debugging")
iex> variables = Lua.get_globals(lua)
iex> IO.inspect(variables)
```

## Testing Lua Integration

When testing code that uses Lua we can provide controlled Lua scripts:

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  import Lua, only: [sigil_LUA: 2]

  test "pricing calculation with lua script" do
    script = ~LUA[return base_price * quantity * 0.9]c
    
    lua = 
      Lua.new()
      |> Lua.set!([:base_price], 10.0)
      |> Lua.set!([:quantity], 3)

    {[result], _state} = Lua.eval!(lua, script)
    assert result == 27.0
  end

  test "error handling for invalid lua" do
    assert_raise Lua.CompilerException, fn ->
      Lua.eval!(~LUA[return invalid syntax])
    end
  end
end
```

## Some Things to Consider

When integrating Lua into our Elixir applications there are several important considerations for performance optimization and security that will help ensure efficient and secure execution.

## Performance

For performance one of the most impactful optimization is using compile-time chunks with the `c` modifier in `~LUA` sigils, eliminating parsing overhead on every execution. It is also advisable to reuse Lua state when possible since creating new states involves expensive initialization of the entire Lua environment.

Data conversion may become a bottleneck with large datasets so keeping data in compatible formats reduces conversion overhead. Another consideration that impacts performance and security is to expose only the functions your scripts actually need, each exposed function increases memory footprint and potential security risks.

## Security

When evaluating user code be sure to never expose dangerous functions that access file systems, networks, or processes, as malicious scripts could compromise your entire application. If you must store sensitive data in your Lua state use private context rather than Lua variables since private context remains isolated from the Lua execution environment.

Lastly, follow the principle of least privilege by exposing only necessary APIs, as each function represents a potential attack vector for malicious scripts.

## Conclusion

The Lua library for Elixir provides a powerful and safe way to add user-defined scripting capabilities to our applications. By leveraging the BEAM VM's strengths and Luerl's sandboxing capabilities, we can create flexible, extensible systems that allow users to customize behavior without compromising security.

Whether we're building plugin systems, configuration engines, or business rules platforms, the combination of Elixir and Lua's simplicity creates amazing possibilities for application extensibility.

The seamless integration between Elixir and Lua, combined with the safety guarantees of running everything on the BEAM VM, makes this library an excellent choice for applications that need to execute user-defined logic safely and efficiently.