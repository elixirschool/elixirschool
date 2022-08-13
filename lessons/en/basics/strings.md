%{
  version: "1.2.0",
  title: "Strings",
  excerpt: """
  Strings, Char Lists, Graphemes and Codepoints.
  """
}
---

## Strings

Elixir strings are nothing but a sequence of bytes.
Let's look at an example:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
iex> string <> <<0>>
<<104, 101, 108, 108, 111, 0>>
```

By concatenating the string with the byte `0`, IEx displays the string as a binary because it is not a valid string anymore.
This trick can help us view the underlying bytes of any string.

>NOTE: Using << >> syntax we are saying to the compiler that the elements inside those symbols are bytes.

## Charlists

Internally, Elixir strings are represented with a sequence of bytes rather than an array of characters.
Elixir also has a char list type (character list).
Elixir strings are enclosed with double quotes, while char lists are enclosed with single quotes.

What's the difference? Each value in a charlist is the Unicode code point of a character whereas in a binary, the codepoints are encoded as UTF-8.
Let's dig in:

```elixir
iex> 'hełło'
[104, 101, 322, 322, 111]
iex> "hełło" <> <<0>>
<<104, 101, 197, 130, 197, 130, 111, 0>>
```

`322` is the Unicode codepoint for ł but it is encoded in UTF-8 as the two bytes `197`, `130`.

You can get a character’s code point by using `?`

```elixir
iex> ?Z
90
```

This allows you to use the notation `?Z` rather than 'Z' for a symbol.

When programming in Elixir, we usually use strings, not charlists.
The charlist support is mainly included because it is required for some Erlang modules.

For further information, see the official [`Getting Started Guide`](http://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## Graphemes and Codepoints

Codepoints are just simple Unicode characters which are represented by one or more bytes, depending on the UTF-8 encoding.
Characters outside of the US ASCII character set will always encode as more than one byte.
For example, Latin characters with a tilde or accents (`á, ñ, è`) are typically encoded as two bytes.
Characters from Asian languages are often encoded as three or four bytes.
Graphemes consist of multiple codepoints that are rendered as a single character.

The String module already provides two functions to obtain them, `graphemes/1` and `codepoints/1`.
Let's look at an example:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## String Functions

Let's review some of the most important and useful functions of the String module.
This lesson will only cover a subset of the available functions.
To see a complete set of functions visit the official [`String`](https://hexdocs.pm/elixir/String.html) docs.

### length/1

Returns the number of Graphemes in the string.

```elixir
iex> String.length "Hello"
5
```

### replace/3

Returns a new string replacing a current pattern in the string with some new replacement string.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### duplicate/2

Returns a new string repeated n times.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### split/2

Returns a list of strings split by a pattern.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Exercise

Let's walk through a simple exercise to demonstrate we are ready to go with Strings!

### Anagrams

A and B are considered anagrams if there's a way to rearrange A or B making them equal.
For example:

+ A = super
+ B = perus

If we re-arrange the characters on String A, we can get the string B, and vice versa.

So, how could we check if two strings are Anagrams in Elixir?  The easiest solution is to just sort the graphemes of each string alphabetically and then check if both the lists are equal.
Let's try that:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase()
    |> String.graphemes()
    |> Enum.sort()
  end
end
```

Let's first look at `anagrams?/2`.
We are checking whether the parameters we are receiving are binaries or not.
That's the way we check if a parameter is a String in Elixir.

After that, we are calling a function that orders the string alphabetically.
It first converts the string to lowercase and then uses `String.graphemes/1` to get a list of the graphemes in the string.
Finally, it pipes that list into `Enum.sort/1`.
Pretty straightforward, right?

Let's check the output on iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2

    The following arguments were given to Anagram.anagrams?/2:

        # 1
        3

        # 2
        5

    iex:11: Anagram.anagrams?/2
```

As you can see, the last call to `anagrams?` caused a FunctionClauseError.
This error is telling us that there is no function in our module that meets the pattern of receiving two non-binary arguments, and that's exactly what we want, to just receive two strings, and nothing more.
