---
layout: page
title: IEx Helpers
category: specifics
order: 6
lang: en
---

{% include toc.html %}

## Overview
As you begin to work in Elixir, IEx is your best friend.
It is a REPL, but it has many advanced features that can make life easier when exploring new code or developing your own work as you go.
There are a slew of built-in helpers that we will go over in this lesson.

### Autocomplete
When working in the shell, you often might find yourself using a new module that you are unfamiliar with.
To understand some of what is available to you, the autocomplete functionality is wonderful.
Simply type a module name and then `.` and press `Tab`:

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
split/2              take/2               to_list/1
update!/3            update/4             values/1
```

And now we know the functions we have and their arity!

### `.iex.exs`
Every time IEx starts, it will look for a `.iex.exs` file.
If this is not present in the current directory, it will look at `~/.iex.exs` as a fallback.
Anything inside it will be loaded in the shell that is started up.
Lets say for some reason we really wanted to have a function called `fuzzy_bunnies/0` to be available all the time for some reason in a new project in a given namespace and have it print a message to us when we start our shell.

We could simply do this:

```shell
$ mix new my_project
$ cd my_project
```

And now we set it up:

```elixir
defmodule Fuzzy do
  def fuzzy_bunnies do
    IO.puts "FUZZY BUNNIES"
  end
end
Fuzzy.fuzzy_bunnies
```

And when we run IEx:

```shell
$ iex
Erlang/OTP 19 [erts-8.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir (1.3.3) - press Ctrl+C to exit (type h() ENTER for help)
fuzzy bunnies
```

And we see our message printed and know we have that available.

### `h`
`h` is one of the most useful tools our Elixir shell gives us.
Due to the language's fantastic first class support for documentation, the docs for any code can be reached using this helper.
To see it in action is simple:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

And now we can even combine this with the autocomplete features of our shell.
Imagine we were exploring Map for the first time:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
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
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

And as you can see, we not only found out what was offered by the module but exactly how to work what we were after with a working example!

### `i`
Since we already have another tool to learn about this and its valid Elixir code, why not use `h` to learn about `i`? Here we go:

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

So now we have a bunch more information about `Map`, including all the way down to where its source is stored and the modules it references.
This is quite useful when exploring custom and foreign data types and new functions.
The individual headings can be dense, but at a high level we can gather some relevent information:

- Its an atom data type
- Where the source code is
- The version, and compile options
- A general description
- How to access it
- What other modules it references

This is a lot to work with, and much better than going in blind.

### `r`
`r` is our helper for recompiling a given module.
Say you have changed some code and simply want to run the new function you added, you could save the file then run:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `s`
`s` gives us type spec information for a given module or function.
This way we can know what it is expecting:

```elixir
iex> s Map.merge/2
@spec merge(map(), map()) :: map()

# it also works on entire modules
iex> s Map
@spec get(map(), key(), value()) :: value()
@spec put(map(), key(), value()) :: map()
# ...
@spec get(map(), key()) :: value()
@spec get_and_update!(map(), key(), (value() -> {get, value()})) :: {get, map()} | no_return() when get: term()
```

### `t`
`t` Tells us about Types available in a given module:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

And now we know that Map defines key and value types in its implementation.
If we go and look at the source of `Map`:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

This is a simple example, stating that keys and values per the implementation can be any type, but it is useful to know.

## Conclusion
By leveraging all these built-in niceties, it can become a lot easier to explore and write new code. IEx is very robust, and does a lot to empower developers. With these tools in your toolbox, exploring and building should be even more fun!
