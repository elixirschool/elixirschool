%{
  author: "Kevin Mathew",
  author_link: "https://github.com/kevinam99",
  tags: ["testing", "ExUnit"],
  date: ~D[2023-03-19],
  title: "Run specific test cases with ExUnit",
  excerpt: """
  Learn how you can easily run one specific test case or a group test cases in Elixir without having to run through the whole test suites and custom workarounds.
  """
}
---

When starting with Elixir, I was amazed how easy it was to write tests in Elixir with ExUnit and be able to do true TDD. This was fine till I was working on my own projects where the size was small and didn't have many components. But as I got to working full time, it became difficult to test specific functionalities that I wrote in a big codebase. 

I found myself commenting out tests that I want to skip which made the whole process tedious and I was back in iex testing functions manually. 
My woes ended when I found these two ways of running specific test cases and I hope this helps as much as it helped me.

Imagine a test file with several tests but you want to run the test case only for the `add/2` function that simply adds two numbers and gives a result.

```elixir
test "it adds two numbers correctly" do
  assert add(2, 2) == 4
end
```

There are three ways to go about this:
### 1. Specify the line number of the test in the `mix test` command.
If the above test case is on, say, line 100 in the test file, then run your command as

```shell
$ mix test ./path/to/test/file/math_test.exs:100

```
This will run the test case on line 100 and skip all other tests. Of course, the basic setup will be done. Boom! Saved so much time and back to being productive.

Now, while this is a good solution, it's temporary and relies on the line number remaining the same. If the test case moves to a different line, either the intended test case won't run or all tests will get skipped because no test case was found on that line. Let's talk about how to get around those.


### 2. Use the `@tag` attribute
Consider the same test case as above but with a small change

```elixir
@tag run: true
test "it adds two numbers correctly" do
  assert add(2, 2) == 4
end 
```
The command to run in this case would be 

```shell
$ mix test ./path/to/test/file/math_test.exs --only run:true
```

This command will find the tag you've specified and run the relevant test. This approach is line agnostic and just requires the correct tag. The tag could be any key value pair which makes most sense in your project but make sure to use `@tag`. This can be further extended and added to other tests that you'd like to run together. This is helpful when those test cases might be scattered across the test file.

But what if the tests you want to run are already in togethere successively and you don't want to tag them repeatedly? This is where the `describe` macro helps.

### 3. The `describe` macro
It is a good practice to group test cases that test the same functionality using the `describe` macro.
  
Example:
```elixir
describe "math functions" do
  test "it adds two numbers correctly" do
    assert add(2, 2) == 4
  end 

  test "it returns an error tuple when dividing by 0" do
    assert divide(2, 0) == {:error, "Cannot divide by 0"}
  end

  test "it computes the max value correctly" do
    assert max(4, 2) == 4
  end 
end

```

Here, you just want to test there math functions only but without the hassle of running the `mix test` command with the line number three times and without writing the tag three times. What you would do is similar to what we discussed in the first approach, the line number, expect this time, it would be the line number of the `describe`. 

You can use `@tag` to run different specific `describe`s in a test. The `mix test` command will still be the same as seen in the first two approaches.

That's it! Hope this was helpful and has made testing your application even easier.

## Conclusion

ExUnit is a powerful and simple tool to make testing your Elixir applications easy and robust. The options it provides offers stellar productivity when working on features and testing them without wasting any time.

The two things we discussed was using the line number of the test case or `describe` and using the `@tag` attribute. Keep in mind that you can use any tag as long as you specify `@tag` and the right name in your `mix test` command. 

Also, a reminder about doctests. Write doctests to save your team and yourself the pain of remembering what a function does and returns. Doctests also give a free test ;)

Bonus tip: If you're running an umbrella project or just want to run all the tests having the same tags, just run the same `mix test` command with the `--only` flag but
without specifying the path to the test file.