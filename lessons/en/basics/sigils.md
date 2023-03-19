%{
  version: "1.0.2",
  title: "Sigils",
  excerpt: """
  Working with and creating sigils.
  """
}
---

## Sigils Overview

Elixir provides an alternative syntax for representing and working with literals.
A sigil will start with a tilde `~` followed by a character.
The Elixir core provides us with some built in sigils however, it is possible to create our own when we need to extend the language.

A list of available sigils include:

- `~C` Generates a character list **with no** escaping or interpolation
- `~c` Generates a character list **with** escaping and interpolation
- `~R` Generates a regular expression **with no** escaping or interpolation
- `~r` Generates a regular expression **with** escaping and interpolation
- `~S` Generates a string **with no** escaping or interpolation
- `~s` Generates a string **with** escaping and interpolation
- `~W` Generates a word list **with no** escaping or interpolation
- `~w` Generates a word list **with** escaping and interpolation
- `~N` Generates a `NaiveDateTime` struct
- `~U` Generates a `DateTime` struct (since Elixir 1.9.0)

A list of delimiters include:

- `<...>` A pair of pointy brackets
- `{...}` A pair of curly brackets
- `[...]` A pair of square brackets
- `(...)` A pair of parentheses
- `|...|` A pair of pipes
- `/.../` A pair of forward slashes
- `"..."` A pair of double quotes
- `'...'` A pair of single quotes

### Char List

The `~c` and `~C` sigils generate character lists respectively.
For example:

```elixir
iex> ~c/2 + 7 = #{2 + 7}/
'2 + 7 = 9'

iex> ~C/2 + 7 = #{2 + 7}/
'2 + 7 = \#{2 + 7}'
```

We can see the lowercased `~c` interpolates the calculation, whereas the uppercased `~C` sigil does not.
We will see that this uppercase / lowercase sequence is a common theme throughout the built in sigils.

### Regular Expressions

The `~r` and `~R` sigils are used to represent Regular Expressions.
We create them either on the fly or for use within the `Regex` functions.
For example:

```elixir
iex> re = ~r/elixir/
~r/elixir/

iex> "Elixir" =~ re
false

iex> "elixir" =~ re
true
```

We can see that in the first test for equality, that `Elixir` does not match with the regular expression.
This is because it is capitalized.
Because Elixir supports Perl Compatible Regular Expressions (PCRE), we can append `i` to the end of our sigil to turn off case sensitivity.

```elixir
iex> re = ~r/elixir/i
~r/elixir/i

iex> "Elixir" =~ re
true

iex> "elixir" =~ re
true
```

Further, Elixir provides the [Regex](https://hexdocs.pm/elixir/Regex.html) API which is built on top of Erlang's regular expression library.
Let's use `Regex.split/2` with a regex sigil:

```elixir
iex> string = "100_000_000"
"100_000_000"

iex> Regex.split(~r/_/, string)
["100", "000", "000"]
```

As we can see, the string `"100_000_000"` is split on the underscore thanks to our `~r/_/` sigil.
The `Regex.split` function returns a list.

### String

The `~s` and `~S` sigils are used to generate string data.
For example:

```elixir
iex> ~s/the cat in the hat on the mat/
"the cat in the hat on the mat"

iex> ~S/the cat in the hat on the mat/
"the cat in the hat on the mat"
```

What is the difference? The difference is similar to the Character List sigil that we looked at.
The answer is interpolation and the use of escape sequences.
If we take another example:

```elixir
iex> ~s/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir school"

iex> ~S/welcome to elixir #{String.downcase "SCHOOL"}/
"welcome to elixir \#{String.downcase \"SCHOOL\"}"
```

### Word List

The word list sigil can come in handy from time to time.
It can save both time, keystrokes and arguably reduce the complexity within the codebase.
Take this simple example:

```elixir
iex> ~w/i love elixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love elixir school/
["i", "love", "elixir", "school"]
```

We can see that what is typed between the delimiters is separated by whitespace into a list.
However, there is no difference between these two examples.
Again, the difference comes with the interpolation and escape sequences.
Take the following example:

```elixir
iex> ~w/i love #{'e'}lixir school/
["i", "love", "elixir", "school"]

iex> ~W/i love #{'e'}lixir school/
["i", "love", "\#{'e'}lixir", "school"]
```

### NaiveDateTime

A [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html) can be useful for quickly creating a struct to represent a `DateTime` **without** a timezone.

For the most part, we should avoid creating a `NaiveDateTime` struct directly.
However, it is useful for pattern matching.
For example:

```elixir
iex> NaiveDateTime.from_iso8601("2015-01-23 23:50:07") == {:ok, ~N[2015-01-23 23:50:07]}
```

### DateTime

A [DateTime](https://hexdocs.pm/elixir/DateTime.html) can be useful for quickly creating
a struct to represent a `DateTime` **with** a UTC timezone. Since it's in the UTC timezone
and your string might represent a different timezone, a 3rd item is returned that represents
the offset in seconds.

For example:

```elixir
iex> DateTime.from_iso8601("2015-01-23 23:50:07Z") == {:ok, ~U[2015-01-23 23:50:07Z], 0}
iex> DateTime.from_iso8601("2015-01-23 23:50:07-0600") == {:ok, ~U[2015-01-24 05:50:07Z], -21600}
```

## Creating Sigils

One of the goals of Elixir is to be an extendable programming language.
It should come as no surprise then that you can easily create your own custom sigils.
In this example, we will create a sigil to convert a string to uppercase.
As there is already a function for this in the Elixir Core (`String.upcase/1`), we will wrap our sigil around that function.

```elixir

iex> defmodule MySigils do
...>   def sigil_p(string, []), do: String.upcase(string)
...> end

iex> import MySigils
nil

iex> ~p/elixir school/
ELIXIR SCHOOL
```

First we define a module called `MySigils` and within that module, we created a function called `sigil_p`.
As there is no existing `~p` sigil in the existing sigil space, we will use it.
The `_p` indicates that we wish to use `p` as the character after the tilde.
The function definition must take two arguments, an input and a list.
