%{
  version: "1.0.2",
  title: "IEx Helpers",
  excerpt: """
  """
}
---

## Overview

As you begin to work in Elixir, IEx is your best friend.
It is a REPL, but it has many advanced features that can make life easier when exploring new code or developing your work as you go.
There is a slew of built-in helpers that we will go over in this lesson.

### Autocomplete

When working in the shell, you often might find yourself using a new module that you are unfamiliar with.
To understand some of what is available to you, the autocomplete functionality is wonderful.
Simply type a module name followed by `.` then press `Tab`:

```elixir
iex> Map. # press Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

And now we know the functions we have and their arity!

### .iex.exs

Every time IEx starts it will look for a `.iex.exs` configuration file.
If it's not present in the current directory, then the user's home directory (`~/.iex.exs`) will be used as the fallback.

Configuration options and code defined within this file will be available to us when the IEx shell starts up.
For instance, if we want some helper functions available to us in IEx, we can open up `.iex.exs` and make some changes.

Let's start by adding a module with a few helper functions:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Now when we run IEx we'll have the IExHelpers module available to us from the start.
Open up IEx and let's try out our new helpers:

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

As we can see we don't need to do anything special to require or import our helpers, IEx handles that for us.

### h

`h` is one of the most useful tools our Elixir shell gives us.
Due to the language's fantastic first-class support for documentation, the docs for any code can be reached using this helper.
To see it in action is simple:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration.
For example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable.
The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as a result, infinite streams need to be carefully used with such
functions, as they can potentially run forever.
For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

And now we can even combine this with the autocomplete features of our shell.
Imagine we were exploring Map for the first time:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===).
Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct.
Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

As we can see we were not only able to find what functions were available as part of the module but we were able to access individual function docs, many of which include example usage.

### i

Let's put some of our new-found knowledge to use by employing `h` to learn a bit more about the `i` helper:

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Now we have a bunch of information about `Map` including where its source is stored and the modules it references.
This is quite useful when exploring custom, foreign data types, and new functions.

The individual headings can be dense, but at a high level we can gather some relevant information:

- Its an atom data type
- Where the source code is
- The version, and compile options
- A general description
- How to access it
- What other modules it references

This gives us a lot to work with and is better than going in blind.

### r

If we want to recompile a particular module we can use the `r` helper.
Let's say we've changed some code and want to run a new function we've added.
To do that we need to save our changes and recompile with r:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### t

The `t` helper tells us about Types available in a given module:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

And now we know that `Map` defines key and value types in its implementation.
If we go and look at the source of `Map`:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

This is a simple example, stating that keys and values per the implementation can be any type, but it is useful to know.

By leveraging all these built-in niceties we can easily explore the code and learn more about how things work.
IEx is a very powerful and robust tool that empowers developers.
With these tools in our toolbox, exploring, and building can be even more fun!
