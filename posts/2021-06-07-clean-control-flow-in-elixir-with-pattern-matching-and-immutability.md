---
author: Cristine Guadelupe
author_link: https://github.com/cristineguadelupe
categories: general
date: 2021-06-07
layout: post
title: "Clean Control Flow in Elixir with Pattern Matching and Immutability"
excerpt: >
  Learn how to use pattern matching instead of guard clauses to implement really clean control flow in Elixir.
---
One of the features that fascinate me most about Elixir is pattern matching. I always wonder if there is a way to solve what I need using it and I love exploring it. When you combine the beauty of pattern matching with the power of immutability some things almost seem magical but they are not!
It is not my focus to cover everything about pattern matching and immutability but instead to demonstrate how we can use pattern matching instead of guard clauses to implement clean control flows in Elixir.

For this post we'll focus on implementing logic for the tabletop game Battleship. The first rule we'll implement is simple: a player cannot go twice in a row. One way to solve this is to track the last player that performed a move.
With this information we now have two possibilities: If the player who is trying to make a move is the same as the last player who take action we will just ignore the move. Otherwise we can will compute the move.

Depending on our experience with Elixir we might reach for a conditional as the first solution, something like:

```elixir 
def maybe_move(player, last_player) do
    if player != last_player do
        player
        |> make_a_move()
        |> set_as_last_player()
    else
      :ignored
    end
end
```

Or even pattern matching with guard clause

```elixir
def maybe_move(player, last_player) when player == last_player do
    :ignored
end

def maybe_move(player, last_player) do
    player
    |> make_a_move()
    |> set_as_last_player()
end
```

But it is possible to combine the pattern matching we already used in the guard clause solution with the power of immutability to come up with an even more alchemistic solution!

```elixir
def maybe_move(last_player, last_player) do
    :ignored
end

def maybe_move(player, last_player) do
    player
    |> make_a_move()
    |> set_as_last_player()
end
```

Wait a second, what have we done here?

We define the first version of the `maybe_move` function to take in a first and second argument named `last_player`. This means the function will only match if the player provided as a first argument matches the player provided as a second argument
Thanks to immutability, when we call both arguments by the same name Elixir will check if they are actually the same!
We could easily call both arguments player or even something like player_is_the_last_player. It doesn't matter! The rule is just that if we want to ensure that there is equality, we call both arguments by the same name!

**Ok, it's time to play using our nice little code!**

Let's say we have `player1` and `player2`, `player1` made the most recent move and therefore is our last_player and now `player2` will try to move!

So we will call the function `maybe_move(player2, player1)` where `player2` is the player who wants to make a move and `player1` is our last_player

We have two `maybe_move` functions both with arity 2, so Elixir will try to pattern match from top to bottom, i.e. the first function it will try to match will be 

```elixir
def maybe_move(last_player, last_player) do
    :ignored
end
```

Our first argument is `player2` and Elixir will bind it with `last_player = player2` and since our second argument is also a `last_player`, Elixir will use the `^` (pin operator) to check if the previous bind is valid for the second argument instead of trying to rebind it.

```elixir
last_player = player2
ˆlast_player = player1
```

As player2 is different from player1, we will not have a valid pattern match and therefore Elixir will move on to try to match with the next function!

**Our next match attempt!**

```elixir
def maybe_move(player, last_player) do
    player
    |> make_a_move()
    |> set_as_last_player()
end
```

Now the behavior will be different, we are asking Elixir to match two different arguments. That is, to make a bind for each one.

```elixir
player = player2
last_player = player1
```

With a valid match, our function will run! Player2 will make a move and then will be registered as our new `last_player`!

What if player2 tries another move in a row?
Well, we will call our first `maybe_move` function again and try a match. Player2 wants to make a move and is also `last_player`, so we get the following call:

`maybe_move(player2, player2)`

Trying to match it with the first maybe_move function we get the following match:

```elixir
def maybe_move(last_player, last_player) do
    :ignored
end
```

```elixir
last_player = player2
ˆlast_player = player2
```

Which is a valid match! And since our function just ignores the move attempt, nothing will happen until another player attempts a move!
That's it! We've learned how pattern matching and data immutability together can provide an elegant solution to control flows, another tool in our Elixir toolbox!

## Resources

If want to learn more about Pattern Matching you can find amazing materiais here on ElixirSchool!

* [Pattern Matching](https://elixirschool.com/en/lessons/basics/pattern-matching/)
* [Functions and Pattern Matching](https://elixirschool.com/en/lessons/basics/functions/#functions-and-pattern-matching)
