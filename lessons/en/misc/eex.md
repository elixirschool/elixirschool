%{
  version: "1.0.2",
  title: "Embedded Elixir (EEx)",
  excerpt: """
  Much like Ruby has ERB and Java has JSPs, Elixir has EEx, or Embedded Elixir.
  With EEx we can embed and evaluate Elixir inside strings.
  """
}
---

## API

The EEx API supports working with strings and files directly.
The API is divided into three main components: simple evaluation, function definitions, and compilation to AST.

### Evaluation

Using `eval_string/3` and `eval_file/2` we can perform a simple evaluation against a string or file contents.
This is the simplest API but the slowest since code is evaluated and not compiled.

```elixir
iex> EEx.eval_string "Hi, <%= name %>", [name: "Sean"]
"Hi, Sean"
```

### Definitions

The fastest, and preferred, method of using EEx is to embed our template into a module so it can be compiled.
For this we need our template at compile time, along with the `function_from_string/5` and `function_from_file/5` macros.

Let's move our greeting to another file and generate a function for our template:

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

### Compilation

Lastly, EEx provides us a way to directly generate Elixir AST from a string or file using `compile_string/2` or `compile_file/2`.
This API is primarily used by the aforementioned APIs but is available should you wish to implement your own handling of embedded Elixir.

## Tags

By default there are four supported tags in EEx:

```elixir
<% Elixir expression - inline with output %>
<%= Elixir expression - replace with result %>
<%% EEx quotation - returns the contents inside %>
<%# Comments - they are discarded from source %>
```

All expressions that wish to output __must__ use the equals sign (`=`).
It's important to note that while other templating languages treat clauses like `if` in a special way, EEx does not.
Without `=` nothing will be output:

```elixir
<%= if true do %>
  A truthful statement
<% else %>
  A false statement
<% end %>
```

## Engine

By default Elixir uses the `EEx.SmartEngine`, which includes support for assignments (like `@name`):

```elixir
iex> EEx.eval_string "Hi, <%= @name %>", assigns: [name: "Sean"]
"Hi, Sean"
```

The `EEx.SmartEngine` assignments are useful because assignments can be changed without requiring template compilation.

Interested in writing your own engine?  Check out the [`EEx.Engine`](https://hexdocs.pm/eex/EEx.Engine.html) behaviour to see what's required.
