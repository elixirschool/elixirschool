%{
  author: "Alex Griffith",
  author_link: "https://github.com/alexgriff",
  date: ~D[2018-12-12],
  tags: ["testing", "logging", "TIL"],
  title: "TIL about ExUnit's capture_log option",
  excerpt: """
  Capture the output from Logger to clean up your test runs
  """
}

---

Have you ever run `mix test` and seen red error messages being logged when, in fact, all your tests are passing? This can often occur when adding test coverage for "sad path" code flows that include calls to `Logger.error/1`.

Here's a (slightly contrived) example of some code that demonstrates the problem. The `GithubClient.get_user_repos/1` function takes a GitHub username, makes a request to the GitHub API and returns a list of the user's repositories. Note the call to `Logger.error/1` if the GitHub user is not found:

```elixir
defmodule GithubClient do
  require Logger

  def get_user_repos(username) do
    case HTTPoison.get "https://api.github.com/users/" <> username <> "/repos" do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> decode_response
        |> handle_success(username)
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        body
        |> decode_response
        |> handle_not_found(username)
    end
  end

  def handle_not_found(response, username) do
    Logger.error "User " <> username <> " does not exist"
    {:error, response}
  end

  # ...
end
```

And here's the corresponding ExUnit tests. The details aren't super important, but the tests are  configured to use a [mock server for the test environment](https://medium.com/flatiron-labs/rolling-your-own-mock-server-for-testing-in-elixir-2cdb5ccdd1a0).


```elixir
defmodule GithubClientTest do
  use ExUnit.Case

  describe "get_user_repos/1 with valid username" do
    test "returns the user's repositories" do
      {:ok, ["repo01", "repo02" | _tail]} = GithubClient.get_user_repos("valid_username")
    end
  end

  describe "get_user_repos/1 with invalid username" do
    test "returns an error tuple" do
      {:error, _message} = GithubClient.get_user_repos("invalid_username")
    end
  end
end
```

Great-- the tests pass! Interspersed in the output, though, you'll see the red error logging resulting from the _passing_ test of the 404 not found case:

`17:32:00.090 [error] User invalid_username does not exist`

Right now we only have two tests, but this can get really distracting as the test suite grows. This applies not only to the "sad path" tests that include error logging, but any logging we might do using other functions included with the [`Logger` module](https://hexdocs.pm/logger/Logger.html) like `Logger.info/1` or `Logger.debug/1`


There are a few ways to solve this. To stop logged output from showing up for _all tests_ add `capture_log: true` to your ExUnit config. In a new mix project this would be found in `test/test_helper.exs` and look like:

```elixir
ExUnit.start(capture_log: true)
```

To capture the logs for a specific test module you can add a [`moduletag`](https://hexdocs.pm/ex_unit/ExUnit.Case.html#module-module-and-describe-tags) to the specific test module.

```elixir
defmodule GithubClientTest do
  use ExUnit.Case

  @moduletag capture_log: true
  #...
end
```

And that's it. Look at all that green!
