%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2019-01-19],
  tags: ["general"],
  title: "Understanding Recursion with Elixir",
  excerpt: """
  De-mystify the concept of recursion and gain a deeper understanding of how and why to use it by writing our very own recursive function in Elixir.
  """
}

---

"Recursion" can be a scary word for those of us unfamiliar with its applications. In this post, we'll de-mystify the concept of recursion and gain a deeper understanding of how and why to use it by writing our very own recursive function in Elixir.

## What is Recursion

In short, "recursion" is when a function calls itself. First we'll look at a contrived example. Later on in this post we'll build a more practical recursive function.

Below we've defined a function `RecursionPractice.hello_world/0`, that calls itself:

```elixir
defmodule RecursionPractice do
  def hello_world do
    IO.puts("Hello, World!")
    hello_world()
  end
end
```

If you think that invoking our `RecursionPractice.hello_world/0` function would cause `"Hello, World!"` to get puts'd out to the terminal infinitely--you're right! The `hello_world` function does two things:

1. Puts out "Hello, World!"
2. Call `hello_world/0` (again)

When `hello_world/0` is invoked again, it will do two things:

1. Puts out "Hello, World!"
2. Call `hello_world/0` (again)

And so on. While "a function that calls itself" is the basic definition of recursion, its _not_ how we want to implement a recursive function.

Any recursive function needs a way to _stop calling itself_ under a certain condition. This condition is often referred to as the **base case**. Let's create a base case for our `RecursionPractice.hello_world/0` function. We'll count the number of times we call the function and stop calling it once we've reached 10.

```elixir
def hello_world(count \\ 0) do
  IO.puts("Hello, World!")
  if count < 10 do
    new_count = count + 1
    hello_world(new_count)
  end
end
```

The `if` condition controls our recursive function for us. _If_ the count is less than 10, increment the count by 1 and call `hello_world/1` again. Otherwise, _don't do anything_, i.e. stop calling the recursive function!

We can refactor this code with the help of [guard clauses](https://elixirschool.com/en/lessons/basics/functions/#guards). Instead of writing an `if` condition inside of our function, we'll define another version of the `RecursionPractice.hello_world/1` function to handle our base case. This version will run _when_ the count is greater than or equal to 10.

```elixir
defmodule RecursionPractice do
  def hello_world(count \\ 0)
  def hello_world(count) when count >= 10, do: nil

  def hello_world(count) do
    IO.puts("Hello, World!")
    new_count = count + 1
    hello_world(new_count)
  end
end
```

*Note that we've moved the default argument definition into a function head. If you're defining a function with multiple clauses and a default value, the default value definition belongs in a function head. Learn more about default arguments, function heads and function clauses in [this Elixir School lesson.](https://elixirschool.com/en/lessons/basics/functions/#default-arguments)*



## Why is it Useful?

Recursion is useful anytime we need to repeat an action under a certain condition. Anytime you want to use a `while` or `until` loop, you can probably implement your solution with recursion.

How do you decide to use a recursive approach over an iterative approach like a `while` loop? Reach for recursion when writing a recursive function produces simpler, easier to read code than a looping approach. Be careful though, if you write a recursive function without a "base case", or stopping point, you'll end up with a stack overflow error--you'll call the function _forever_!

## Building a Recursive Function with Elixir

Now that we have a better understanding of what recursion is and how it works, let's build a more practical recursive function.

Elixir's `List` module provides us with a number of handy functions for operating on lists, including a `List.delete/2` function that works like this:

Given a list and an element in that list, return a new list that does not contain the _fist occurrence_ of the given element. For example:

```elixir
List.delete(["Apple", "Pear", "Grapefruit"], "Pear")
=> ["Apple", "Grapefruit"]
```

However, we'll see that if the given list contains more than one appearance of `"Pear"`, `List.delete/2` only removes the _first_ `"Pear"`

```elixir
List.delete(["Apple", "Pear", "Grapefruit", "Pear"], "Pear")
["Apple", "Grapefruit", "Pear"]
```

What if we want to remove _all_ occurrences of a particular element from our list? The `List` module doesn't implement such a function. Let's build our own!

Our desired behavior looks like this:

```elixir
List.delete(["Apple", "Pear", "Grapefruit", "Pear"], "Pear")
["Apple", "Grapefruit"]
```

Before we start building our function, let's take a look at how we can use recursion and pattern matching to operate on Elixir lists.

### Using Recursion on a List
> Lists in Elixir are effectively linked lists, which means they are internally represented in pairs containing the head and the tail of a list. - Hex Docs

This means we can use [pattern matching](https://elixirschool.com/en/lessons/basics/pattern-matching/) to grab the first element, or the "head" of the list:

```elixir
iex> [head | tail] = [1,2,3]
iex> head
1
iex> tail
[2,3]
```

Using this pattern matching approach, we can operate on each member of a list:

```
iex> list = [1,2,3,4]
[1, 2, 3, 4]
iex> [head | tail] = list
[1, 2, 3, 4]
iex> head
1
iex> tail
[2, 3, 4]
iex> [head | tail] = tail
[2, 3, 4]
iex> head
2
iex> tail
[3, 4]
iex> [head | tail] = tail
[3, 4]
iex> head
3
iex> tail
[4]
iex> [head | tail] = tail
[4]
iex> head
4
iex> tail
[]
```

Using this approach, let's define a custom function to recurse over each element in a list.
Our function will grab the `head` of the list and `puts` it out to the terminal. Then, we'll take the `tail` and split it up into its _own_ `head` and `tail`. We'll keep doing this until the list is empty.

```elixir
defmodule MyList do
  def my_each([head | tail]) do
    IO.puts(head)
    if tail != [] do
      my_each(tail)
    end
  end
end
```

Our **base case** occurs when the `tail` is empty, i.e. when there are no more elements in the list. We can leverage [Elixir's ability to pattern match function arity](https://elixirschool.com/en/lessons/basics/functions/#functions-and-pattern-matching) to clean this up a bit.

Instead of implementing an `if` condition inside our recursive function, we'll define another version of our function that will get run when `my_each` is called with an argument of an empty list. So, if `my_each` is called with an argument of a list that isn't empty, the first version of the function will run. It will grab the `head` of the list and `puts` it out. Then it will call `my_each` _again_ with an argument of the `tail` of the list. If and when the tail is empty, the second version of the function will run. In this case, we will _not_ call `my_each` again.

```elixir
defmodule MyList do
  def my_each([head | tail]) do
    IO.puts(head)
    my_each(tail)
  end

  def my_each([]), do: nil
end
```

Let's see it in action:

```elixir
iex> MyList.my_each([1,2,3,4])
1
2
3
4
```

Now that we have a handle on using recursion and pattern matching with Elixir lists, let's get back to our recursive "delete all" function.

### Defining a Recursive `delete_all/2` Function

#### Desired Behavior

Before we start coding, let's map out how our function needs to behave. Since Elixir is a functional language, we _won't_ be mutating the original list. Instead, we'll build a new list comprised of all of the elements from the original list, _minus_ all elements that match the element we want to exclude.

Our approach will work something like this:

* Look at the head of the list. If that element is equal to the value whose occurrences we want to remove, we will *not* grab the element to add to the new list.
* If that element is *not* equal to the value we want to remove, we will add it to the new list.
* In either case, we'll grab the tail of the list and repeat the previous step.
* Once the tail is empty, i.e. we've looked at every element in the list, stop recursing.

#### Let's Build It!

First, we'll define a `MyList.delete_all/2` function that takes in two arguments: the original list and the element whose occurrences we want to delete.

```elixir
defmodule MyList
  def delete_all(list, el) do
    # coming soon!
  end
end
```

However, we need access to a new, empty list that we'll populate with the elements of the original list we're _not_ deleting. So, we'll define a version of `delete_all` that takes in _three_ arguments: the original list, the element who occurrences we want to delete, and the new empty list.

`MyList.delete_all/2` will call the `MyList.delete_all/3` function. This saves the user from having to call `delete_all` with a third argument of an empty list and allows us to provide a nice tidy API.

```elixir
defmodule MyList
  def delete_all(list, el) do
    delete_all(list, el, [])
  end

  def delete_all([head | list], el, new_list) do
  end
end
```

The `MyList.delete_all/3` function's first job is to determine whether or not the first element in the current list, the `head` of the list, is the same value as the element we want to remove.

If so, we *won't* add it to our new list. Instead, we'll call `MyList.delete_all/3` again with the remainder of the current list, the `tail`, and pass in our `new_list` unchanged. We can accomplish this with a guard clause:

```elixir
def delete_all([head | tail], el, new_list) when head === el do
  delete_all(tail, el, new_list)
end
```

If the head of the current list is *not* equal to the value we want to remove, however, we *do* want to add it to our `new_list` before moving on.

We'll define another `delete_all/3` function, this time without a guard clause, to meet this condition:

```elixir
def delete_all([head | tail], el, new_list) do
  delete_all(tail, el, [head | new_list])
end
```

We add the current `head` to our new list like this:

```elixir
[ head | new_list ]
```

and we call `delete_all/3` again, passing it the remainder of the list (`tail`), the element to delete and the updated `new_list`.

When should we stop recursing? In other words, what is the base case that will cause us to stop calling `delete_all/3`? When we've recursed over all of the elements in the original list, such that the `tail` is empty, we'll _stop_ calling `delete_all/3` and instead return the new list. Let's define one final `delete_all/3` function to match this condition:

```elixir
def delete_all([], el, new_list) do
  new_list
end
```

The only problem with this approach is that it builds and returns a new list in which all of the elements we kept from the original list are populated in reverse order. This is because by building out our new list like this:

```elixir
[ head | new_list ]
```

We are adding the element we want to keep to the _front_ of our new list, instead of the end.

We can fix this by using `Enum.reverse` on the `new_list` once we've reached our empty list base case:

```elixir
def delete_all([], el, new_list) do
  Enum.reverse(new_list)
end  
```

If we put it all together, we'll have:

```elixir
defmodule MyList do
  def delete_all(list, el) do
    delete_all(list, el, [])
  end

  def delete_all([head | tail], el, new_list) when head === el do
    delete_all(tail, el, new_list)
  end

  def delete_all([head | tail], el, new_list) do
    delete_all(tail, el, [head | new_list])
  end

  def delete_all([], el, new_list) do
    Enum.reverse(new_list)
  end  
end
```

We can even take this one step further and replace our guard clause with Elixir's ability to pattern match function arity. Instead of using the guard clause to run a certain version of our function when `head === el`, we can write the function like this:

```elixir
def delete_all([el | tail], el, new_list) do
  delete_all(tail, el, new_list)
end
```

Now we should be able to call our function:

```elixir
iex> MyList.delete_all(["Apple", "Pear", "Grapefruit", "Pear"], "Pear")
["Apple", "Grapefruit"]
```

And that's it!
