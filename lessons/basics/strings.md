---
layout: page
title: Strings
category: basics
order: 14
lang: en
---

What are Strings in Elixir, Char lists, Graphemes and Codepoints.

## Table of Contents

- [Strings in Elixir](#strings-in-elixir)
- [Char lists](#char-lists)
- [Graphemes and Codepoints](#graphemes)
- [String functions](#string-functions)
  - [Length](#length)
  - [Replace](#replace)
  - [Duplicate](#duplicate)
- [Exercises](#exercises)
  - [Anagrams](#anagrams)

## Strings in Elixir

Elixir strings are nothing but a sequence of bytes. Let's look at an example:

```elixir
iex> string = <<104,101,108,108,111>>
"hello"
```

>NOTE: Using << >> syntax we are saying to the compiler that the elements inside those symbols are bytes.

## Char lists

Internally, Elixir strings are represented with a sequence of bytes rather than an array of characters, and also has a char list type (characters list). Elixir strings are created with double quotes, while char lists are with single quotes.

What's the difference between them? Each value from a char list is the ASCII value from the character. Let's dig in:

```elixir
iex> char_list = 'hello'
'hello'

iex> Enum.reduce(char_list, "", fn char, acc -> acc <> to_string(char) <> "," end)
"104,101,108,108,111,"
```

When programming in Elixir, we are not usually using char lists but Strings. The char lists support is given because are required by some Erlang modules.

## Graphemes and codepoints

Codepoints are just simple Unicode characters, which may be represented by one or two bytes. For example, characters with a tilde or accents: `á, ñ, è`. Graphemes consists on multiple codepoints that look as a simple character.

The String module already provides two methods to obtain them, `graphemes/1` and `codepoints/1`. Let's look at the example:

```elixir
iex> string = "\u0061\u0301"
"á"

iex> String.codepoints string
["a", "́"]

iex> String.graphemes string
["á"]
```

## String functions

Let's review some of the most important and useful function the String module has for us.

##### `length/1`

Returns the number of Graphemes in the string.

```elixir
iex> String.length "Hello"
5
```

##### `replace/4`

Returns a new string replacing a current pattern in the string for some new replacement string.

```elixir
iex> String.replace("Hello", "e", "a")
"Hallo"
```

##### `duplicate/2`

Returns a new string repeated n times.

```elixir
iex> String.duplicate "Oh my ", 3
"Oh my Oh my Oh my "
```

##### `split/2`

Returns an array of strings splitted by pattern

```elixir
iex> String.split("Hello World", " ")
["Hello", "World"]
```

## Exercises

Let's just get in action with two simple exercises to demostrate we are ready to go with Strings!

### Anagrams

A and B are considered anagrams if there's a way that rearranging A or B, we can make them equals. For example: 
A = super
B = perus 

If we re-arrange the characters on String A, we can get the string B, and viceversa.

So, what could be the way to check if two strings are Anagrams in Elixir?

The easiest solution is to order the strings alphabetically and check if they are equals. Let's check the next example:

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

After it, we are just calling a function that orders the strings in alphabetically order, first doing the string downcase and then using `String.graphemes`, which returns an array with the Graphemes of the string. Pretty straight right?

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
