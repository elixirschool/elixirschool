---
layout: page
title: Strings
category: basics
order: 14
lang: en
---

Strings, Char Lists, Graphemes and Codepoints.

{% include toc.html %}

## Strings

Elixir strings are nothing but a sequence of bytes. Let's look at an example:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
```

>NOTE: Using << >> syntax we are saying to the compiler that the elements inside those symbols are bytes.

## Char Lists

Internally, Elixir strings are represented with a sequence of bytes rather than an array of characters. Elixir also has a char list type (characters list). Elixir strings are enclosed with double quotes, while char lists are enclosed with single quotes.

What's the difference? Each value from a char list is the ASCII value from the character. Let's dig in:

```elixir
iex> char_list = 'hello'
'hello'

iex> [hd|tl] = char_list
'hello'

iex> {hd, tl}
{104, 'ello'}

iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

When programming in Elixir, we usually use Strings, not char lists. The char lists support is mainly included because it is required for some Erlang modules.

## Graphemes and Codepoints

Codepoints are just simple Unicode characters, which may be represented by one or two bytes. For example, characters with a tilde or accents: `á, ñ, è`. Graphemes consists on multiple codepoints that look as a simple character.

The String module already provides two methods to obtain them, `graphemes/1` and `codepoints/1`. Let's look at an example:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## String Functions

Let's review some of the most important and useful functions of the String module.  This lesson will only cover a subset of the available functions; to see a complete set of functions visit the official [`String`](http://elixir-lang.org/docs/v1.0/elixir/String.html) docs.

### `length/1`

Returns the number of Graphemes in the string.

```elixir
iex> String.length "Hello"
5
```

### `replace/3`

Returns a new string replacing a current pattern in the string for some new replacement string.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

### `duplicate/2`

Returns a new string repeated n times.

```elixir
iex> String.duplicate("Oh my ", 3)
"Oh my Oh my Oh my "
```

### `split/2`

Returns a list of strings splitted by pattern.

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Exercises

Let's walk through a simple exercises to demonstrate we are ready to go with Strings!

### Anagrams

A and B are considered anagrams if there's a way that rearranging A or B, we can make them equals. For example: 

+ A = super
+ B = perus 

If we re-arrange the characters on String A, we can get the string B, and viceversa.

So, how could we check if two strings are Anagrams in Elixir?  The easiest solution is to just sort the graphemes of each string alphabetically and then check if they both lists are equal. Let's try that:

```elixir
defmodule Anagram do
  def anagrams?(a, b) when is_binary(a) and is_binary(b) do
    sort_string(a) == sort_string(b)
  end

  def sort_string(string) do
    string
    |> String.downcase
    |> String.graphemes
    |> Enum.sort
  end
end
```

Let's first give a watch to `anagrams?/2`. We are checking whether the parameters we are receiving are binaries or not. That's the way we check if a parameter is a String in elixir.

After it, we are just calling a function that orders the strings in alphabetically order, first doing the string downcase and then using `String.graphemes`, which returns a list with the Graphemes of the string. Pretty straight right?

Let's check the output on iex:

```elixir
iex> Anagram.anagrams?("Hello", "ohell")
true

iex> Anagram.anagrams?("María", "íMara")
true

iex> Anagram.anagrams?(3, 5)
** (FunctionClauseError) no function clause matching in Anagram.anagrams?/2
    iex:2: Anagram.anagrams?(3, 5)
```

As you can see, the last call to `anagrams?` cause a FunctionClauseError. This error is telling us that there is not a function in our module that meets the pattern of receiving two non-binary arguments, and that's exactly what we want, to just receive two strings, and nothing more. 
