---
author: Cristine Guadelupe
author_link: https://github.com/cristineguadelupe
categories: general
date: 2021-03-06
layout: post
title: "Clean Control Flow in Elixir with Pattern Matching and Immutability"
excerpt: >
  Learn how to you use pattern matching instead of guard clauses to implement really clean control flow in Elixir.
---
One of the features that fascinate me most about Elixir is pattern matching. I always wonder if there is a way to solve what I need using it, and I love exploring it. When you combine the beauty of pattern matching with the power of immutability, some things almost seem magical. But they are not!
It is not my focus to cover everything about pattern matching and immutability on this post. My goal here is to show you how we can use pattern matching instead of guard clauses to implement really clean control flow in Elixir.

Let's say you're building the game of battleship and you need to build some logic that says the same player can't attack twice in a row. One way to solve the problem is to register the identifier of the last player that performed an attack.
With this information we now have two possibilities, if the player who is trying to make a new attack is the same as the last one that was registered as the last shooter, we will just ignore the attack. Otherwise, if the attack is coming from another player, we will compute the attack.

Depending on your elixir knowledge, you might think of some conditional as the first solution, something like:

```elixir 
def maybe_attack(player, last_shooter) do
    if player != last_shooter do
        player
        |> make_an_attack()
        |> set_as_last_shooter()
    else
      ignore()
    end
end
```

Or even pattern matching with guard clause

```elixir
def maybe_attack(player, last_shooter) when player == last_shooter do
    ignore()
end

def maybe_attack(player, last_shooter) do
    player
    |> make_an_attack()
    |> set_as_last_shooter()
end
```

But it is possible to combine the pattern matching we already used in the guard clause solution with the power of immutability to come up with an even more alchemistic solution!

```elixir
def maybe_attack(last_shooter, last_shooter) do
    ignore()
end

def maybe_attack(player, last_shooter) do
    player
    |> make_an_attack()
    |> set_as_last_shooter()
end
```

Wait a second, what have we done here?

We define the first version of the `maybe_attack` function to take in a first and second argument named `last_shooter`. This means the function will only match if the player provided as a first argument matches the player provided as a second argument
Thanks to immutability, when we call both arguments by the same name Elixir will check if they are actually the same!
We could easily call both arguments player or even something like player_is_the_last_shooter. It doesn't matter! The rule is just that if we want to ensure that there is equality, we call both arguments by the same name!

**Ok, it's time to play using our nice little code!**

Let's say we have `player1` and `player2`, `player1` made the most recent attack and therefore is our last_shooter and now `player2` will try to attack!

So we will call the function `maybe_attack(player2, player1)` where `player2` is the player who wants to make an attack and `player1` is our last_shooter

We have two `maybe_attack` functions both with arity 2, so Elixir will try to pattern match from top to bottom, i.e. the first function it will try to match will be 

```elixir
def maybe_attack(last_shooter, last_shooter) do
    ignore()
end
```

Our first argument is `player2` and Elixir will bind it with `last_shooter = player2` and since our second argument is also a `last_shooter`, Elixir will use the `^` (pin operator) to check if the previous bind is valid for the second argument instead of trying to rebind it.

```elixir
last_shooter = player2
ˆlast_shooter = player1
```

As player2 is different from player1, we will not have a valid pattern match and therefore Elixir will move on to try to match with the next function!

**Our next match attempt!**

```elixir
def maybe_attack(player, last_shooter) do
    player
    |> make_an_attack()
    |> set_as_last_shooter()
end
```

Now the behavior will be different, we are asking Elixir to match two different arguments. That is, to make a bind for each one.

```elixir
player = player2
last_shooter = player1
```

With a valid match, our function will run! Player2 will make an attack and then will be registered as our new `last_shooter`!

What if player2 tries another attack in a row?
Well, we will call our first `maybe_attack` function again and try a match. Player2 wants to make an attack and is also `last_shooter`, so we get the following call

`maybe_attack(player2, player2)`

Trying to match it with the first maybe_attack function we get the following match

```elixir
def maybe_attack(last_shooter, last_shooter) do
    ignore()
end
```

```elixir
last_shooter = player2
ˆlast_shooter = player2
```

Which is a valid match! And since our function just ignores the attack attempt, nothing will happen until another player attempts an attack!

## Resources

If want to learn more about Pattern Matching you can find amazing materiais here on ElixirSchool!

* [Pattern Matching](https://elixirschool.com/en/lessons/basics/pattern-matching/)
* [Functions and Pattern Matching](https://elixirschool.com/en/lessons/basics/functions/#functions-and-pattern-matching)
