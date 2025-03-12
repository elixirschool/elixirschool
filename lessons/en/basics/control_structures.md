%{
  version: "1.2.0",
  title: "Control Structures",
  excerpt: """
  In this lesson we will look at the control structures available to us in Elixir.
  """
}
---

## if

You may have encountered `if/2` before. In Elixir it works much the same way but is defined as a macro, not language constructs; you can find the implementation in the [Kernel module](https://hexdocs.pm/elixir/Kernel.html).

It should be noted that in Elixir, the only falsey values are `nil` and the boolean `false`.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

## case

If it's necessary to match against multiple patterns we can use `case/2`:

```elixir
iex> status = {:ok, "Hello World"}
{:ok, "Hello World"}
iex> case status do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

The `_` variable is an important inclusion in `case/2` statements. Without it, failing to find a match will raise an error:

```elixir
iex> result = :even
:even
iex> case result do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Consider `_` as the `else` that will match "everything else".

Since `case/2` relies on pattern matching, all of the same rules and restrictions apply.
If you intend to match against existing variables you must use the pin `^/1` operator:

```elixir
iex> pie = 3.14
 3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

Another neat feature of `case/2` is its support for guard clauses:

_This example comes directly from the official Elixir [Getting Started](https://elixir-lang.org/getting-started/case-cond-and-if.html#case) guide._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Check the official docs for [Expressions allowed in guard clauses](https://hexdocs.pm/elixir/patterns-and-guards.html#list-of-allowed-functions-and-operators).

## cond

When we need to match conditions rather than values we can turn to `cond/1`; this is akin to `else if` or `elsif` from other languages:

_This example comes directly from the official Elixir [Getting Started](https://elixir-lang.org/getting-started/case-cond-and-if.html#cond) guide._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

Like `case/2`, `cond/1` will raise an error if there is no match.
To handle this, we can define a condition set to `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## with

The construct `with/1` is useful when you might use a nested `case/2` statement or situations that cannot cleanly be piped together. The `with/1` expression is composed of the keywords, the generators, and finally an expression.

We'll discuss generators more in the [list comprehensions lesson](/en/lessons/basics/comprehensions), but for now we only need to know they use [pattern matching](/en/lessons/basics/pattern_matching) to compare the right side of the `<-` to the left.

We'll start with an example of `with/1` and then look at something more:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

In the event that an expression fails to match, the non-matching value will be returned:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Now let's look at a larger example without `with/1` and then see how we can refactor it:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

When we introduce `with/1` we end up with code that is clearer and has fewer lines:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```

As of Elixir 1.3, `with/1` statements support `else`:

```elixir
iex> import Integer
Integer
iex> m = %{a: 1, c: 3}
%{a: 1, c: 3}
iex> a =
...>   with {:ok, number} <- Map.fetch(m, :a),
...>     true <- is_even(number) do
...>       IO.puts "#{number} divided by 2 is #{div(number, 2)}"
...>       :even
...>   else
...>     :error ->
...>       IO.puts("We don't have this item in map")
...>       :error
...> 
...>     _ ->
...>       IO.puts("It is odd")
...>       :odd
...>   end
It is odd
:odd
```

`else` helps to handle errors by providing `case`-like pattern matching. The first non-matched expression is passed to `else`
