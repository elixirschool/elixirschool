%{
  version: "2.0.0",
  title: "Basics",
  excerpt: """
  Getting started, basic data types, and basic operations.
  """
}
---

## Getting Started

### Installing Elixir

Installation instructions for each operating system can be found in the official [Elixir Installation Guide](https://hexdocs.pm/elixir/introduction.html#installation). The guide covers package managers for all major platforms including macOS (via Homebrew), Ubuntu/Debian (via apt), Windows (via Chocolatey), and more.

After Elixir is installed, you can verify the installation and check the version:

```bash
$ elixir --version
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit:ns]

Elixir 1.16.0 (compiled with Erlang/OTP 26)
```

Don't worry about understanding all the details in this output - it shows that both Erlang (which Elixir runs on) and Elixir are properly installed.

### Trying Interactive Mode

Elixir comes with IEx (Interactive Elixir), a powerful shell that allows us to evaluate Elixir expressions as we go. This is one of the best ways to learn and experiment with the language.

To get started, let's run `iex`:

```bash
$ iex
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit:ns]

Interactive Elixir (1.16.0) - press Ctrl+C to exit (type h() ENTER for help)
iex>
```

**Note**: On Windows, you may need to type `iex.bat` depending on your installation method.

Let's try some basic expressions to get a feel for the language:

```elixir
iex> 2 + 3
5
iex> 2 + 3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Don't worry if you don't understand every expression yet - we'll cover all of these concepts in detail. The important thing is to get comfortable with the interactive environment.

## Basic Data Types

Elixir has several basic data types that form the foundation of the language. Let's explore each one with practical examples.

### Integers

Integers in Elixir are straightforward and support arbitrarily large values:

```elixir
iex> 255
255
iex> 1_000_000
1000000
```

Elixir supports different number bases out of the box:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

**Tip**: You can use underscores in large numbers to improve readability, as shown with `1_000_000` above.

### Floats

Floating point numbers in Elixir require a decimal point after at least one digit. They have 64-bit double precision and support scientific notation:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### Booleans

Elixir supports `true` and `false` as booleans. An important concept in Elixir is that everything is considered "truthy" except for `false` and `nil`:

```elixir
iex> true
true
iex> false
false
iex> is_boolean(true)
true
iex> is_boolean(1)
false
```

### Atoms

Atoms are constants where their name is their value. If you're familiar with Ruby, these are similar to symbols. They're commonly used to tag return values and represent state:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
iex> :ok
:ok
iex> {:ok, "result"}
{:ok, "result"}
```

The booleans `true` and `false` are actually atoms `:true` and `:false`:

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Module names in Elixir are also atoms. `MyApp.MyModule` is a valid atom, even if no such module has been declared yet:

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atoms are also used to reference modules from Erlang libraries:

```elixir
iex> :crypto.strong_rand_bytes(3)
<<23, 104, 108>>
```

### Strings

Strings in Elixir are UTF-8 encoded and wrapped in double quotes:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
iex> "🎉"
"🎉"
```

Strings support line breaks and escape sequences:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
iex> "He said, \"Hello!\""
"He said, \"Hello!\""
```

## Basic Operations

### Arithmetic

Elixir supports the basic arithmetic operators you'd expect:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

**Important**: The `/` operator always returns a float. For integer division or remainder operations, Elixir provides dedicated functions:

```elixir
iex> div(10, 3)
3
iex> rem(10, 3)
1
```

### Boolean Logic

Elixir provides boolean operators that work with any data type:

```elixir
iex> -20 || true
-20
iex> false || 42
42
iex> 42 && true
true
iex> 42 && nil
nil
iex> !42
false
iex> !false
true
```

In Elixir, the concept of "truthiness" is simple: only `false` and `nil` are considered falsy. Everything else, including `0`, `""` (empty string), and `[]` (empty list), is truthy.

There are three additional operators that require boolean values as their first argument:

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (BadBooleanError) expected a boolean on left-side of "and", got: 42
```

**Note**: `and`, `or`, and `not` are stricter about their arguments compared to `&&`, `||`, and `!`.

### Comparison

Elixir provides all the comparison operators you'd expect:

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

For strict comparison of integers and floats, use `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

A unique feature of Elixir is that any two types can be compared, which is useful for sorting:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

The sort order is: `number < atom < reference < function < port < pid < tuple < map < list < bitstring`

### String Interpolation

String interpolation in Elixir uses the `#{}` syntax, similar to Ruby:

```elixir
iex> name = "Sean"
"Sean"
iex> "Hello #{name}"
"Hello Sean"
iex> "The result is #{2 + 2}"
"The result is 4"
```

### String Concatenation

String concatenation uses the `<>` operator:

```elixir
iex> name = "Sean"
"Sean"
iex> "Hello " <> name
"Hello Sean"
```

## Working with IEx

### Getting Help

IEx provides excellent built-in help. Type `h()` for general help, or `h/1` with a function name for specific documentation:

```elixir
iex> h()
# General help information

iex> h(Enum.map)
# Documentation for Enum.map function
```

### Tab Completion

IEx supports tab completion. Try typing `String.` and then pressing Tab to see available functions:

```elixir
iex> String. # press Tab
at/2         bag_distance/2   capitalize/2     chunk/2
codepoints/1 contains?/2      downcase/1       duplicate/2
# ... and many more
```

### Recompiling Code

When working on a project, you can recompile your code without restarting IEx:

```elixir
iex> recompile()
```

### Accessing Documentation

You can access documentation for any module or function right from IEx:

```elixir
iex> h(String.split)

  def split(string, pattern \\ " ", options \\ [])

  @spec split(
          t(),
          pattern() | [pattern()],
          keyword()
        ) :: [t()]

Splits string into substrings at each occurrence of one or more
patterns.

# ... rest of documentation
```

## Next Steps

Now that you've learned the basics of Elixir's data types and operations, you're ready to dive deeper into more complex data structures like lists, tuples, and maps in our [Collections](/en/lessons/basics/collections) lesson.

Remember: the best way to learn Elixir is to experiment. Keep IEx open and try variations of the examples you've seen. Don't be afraid to break things - it's all part of the learning process!