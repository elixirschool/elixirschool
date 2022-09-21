%{
  version: "1.0.1",
  title: "Bypass",
  excerpt: """
  When testing our applications there are often times we need to make requests to external services.
  We may even want to simulate different situations like unexpected server errors.
  Handling this in an efficient way doesn't come easy in Elixir without a little help.

In this lesson we're going to explore how [bypass](https://github.com/PSPDFKit-labs/bypass) can help us quickly and easily handle these requests in our tests
  """
}
---

## What is Bypass?

[Bypass](https://github.com/PSPDFKit-labs/bypass) is described as "a quick way to create a custom plug that can be put in place instead of an actual HTTP server to return prebaked responses to client requests."

What does that mean?
Under-the-hood Bypass is an OTP application that masquerades as an external server listening for and responding to requests.
By responding with pre-defined responses we can test any number of possibilities like unexpected service outages and errors along with the expected scenarios we'll encounter, all without making a single external request.

## Using Bypass

To better illustrate the features of Bypass we'll be building a simple utility application to ping a list of domains and ensure they're online.
To do this we'll create new supervisor project and a GenServer to check the domains on a configurable interval.
By leveraging Bypass in our tests we'll be able to verify our application will work in many different outcomes.

_Note_: If you wish to skip ahead to the final code, head over to the Elixir School repo [Clinic](https://github.com/elixirschool/clinic) and have a look.

By this point we should be comfortable creating new Mix projects and adding our dependencies so we'll focus instead of the pieces of code we'll be testing.
If you do need a quick refresher, refer to the [New Projects](https://elixirschool.com/en/lessons/basics/mix/#new-projects) section of our [Mix](https://elixirschool.com/en/lessons/basics/mix) lesson.

Let's start by creating a new module that will handle making the requests to our domains.
With [HTTPoison](https://github.com/edgurgel/httpoison) let's create a function, `ping/1`, that takes a URL and returns `{:ok, body}` for HTTP 200 requests and `{:error, reason}` for all others:

```elixir
defmodule Clinic.HealthCheck do
  def ping(urls) when is_list(urls), do: Enum.map(urls, &ping/1)

  def ping(url) do
    url
    |> HTTPoison.get()
    |> response()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, body}
  defp response({:ok, %{status_code: status_code}}), do: {:error, "HTTP Status #{status_code}"}
  defp response({:error, %{reason: reason}}), do: {:error, reason}
end
```

You'll notice we are _not_ making a GenServer and that's for good reason:
By separating our functionality (and concerns) from the GenServer, we are able to test our code without the added hurdle of concurrency.

With our code in place we need to start on our tests.
Before we can use Bypass we'll need to ensure it's running.
To do that, let's update `test/test_helper.exs` look like this:

```elixir
ExUnit.start()
Application.ensure_all_started(:bypass)
```

Now that we know Bypass will be running during our tests let's head over to `test/clinic/health_check_test.exs` and finish our setup.
To prepare Bypass for accepting requests we need to open the connect with `Bypass.open/1`, which can be done in our test setup callback:

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end
end
```

For now we'll rely on Bypass using it's default port but if we needed to change it (which we'll be doing in a later section), we can supply `Bypass.open/1` with the `:port` option and a value like `Bypass.open(port: 1337)`.
Now we're ready to put Bypass to work.
We'll start with a successful request first:

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  alias Clinic.HealthCheck

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "request with HTTP 200 response", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}")
  end
end
```

Our test is simple enough and if we run it we'll see it passes but let's dig in and see what each portion is doing.
The first thing we see in our test is the `Bypass.expect/2` function:

```elixir
Bypass.expect(bypass, fn conn ->
  Plug.Conn.resp(conn, 200, "pong")
end)
```

`Bypass.expect/2` takes our Bypass connection and a single arity function which is expected to modify a connection and return it, this is also an opportunity to make assertions on the request to verify it's as we expect.
Let's update our test url to include `/ping` and assert both the request path and HTTP method:

```elixir
test "request with HTTP 200 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    assert "GET" == conn.method
    assert "/ping" == conn.request_path
    Plug.Conn.resp(conn, 200, "pong")
  end)

  assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}/ping")
end
```

The last part of our test we use `HealthCheck.ping/1` and assert the response is as expected, but what's `bypass.port` all about?
Bypass is actually listening to a local port and intercepting those requests, we're using `bypass.port` to retrieve the default port since we didn't provide one in `Bypass.open/1`.

Next up is adding test cases for errors.
We can start with a test much like our first with some minor changes: returning 500 as the status code and assert the `{:error, reason}` tuple is returned:

```elixir
test "request with HTTP 500 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    Plug.Conn.resp(conn, 500, "Server Error")
  end)

  assert {:error, "HTTP Status 500"} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

There's nothing special to this test case so let's move on to the next: unexpected server outages.
Τhese are the requests we're most concerned with.
To accomplish this we won't be using `Bypass.expect/2`, instead we're going to rely on `Bypass.down/1` to shut down the connection:

```elixir
test "request with unexpected outage", %{bypass: bypass} do
  Bypass.down(bypass)

  assert {:error, :econnrefused} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

If we run our new tests we'll see everything passes as expected!
With our `HealthCheck` module tested we can move on to testing it together with our GenServer based-scheduler.

## Multiple external hosts

For our project we'll keep the scheduler barebones and rely on `Process.send_after/3` to power our reoccuring checks, for more on the `Process` module take a look at the [documentation](https://hexdocs.pm/elixir/Process.html).
Our scheduler requires three options: the collection of sites, the interval of our checks, and the module that implements `ping/1`.
By passing in our module we further decouple our functionality and our GenServer, enabling us to better test each in isolation:

```elixir
def init(opts) do
  sites = Keyword.fetch!(opts, :sites)
  interval = Keyword.fetch!(opts, :interval)
  health_check = Keyword.get(opts, :health_check, HealthCheck)

  Process.send_after(self(), :check, interval)

  {:ok, {health_check, sites}}
end
```

Now we need to define the `handle_info/2` function for the `:check` message sent `send_after/2`.
To keep things simple we'll pass our sites to `HealthCheck.ping/1` and log our results to either `Logger.info` or in the case of errors `Logger.error`.
We'll setup our code in a way that will enable us to improve the reporting capabilities at a later time:

```elixir
def handle_info(:check, {health_check, sites}) do
  sites
  |> health_check.ping()
  |> Enum.each(&report/1)

  {:noreply, {health_check, sites}}
end

defp report({:ok, body}), do: Logger.info(body)
defp report({:error, reason}) do
  reason
  |> to_string()
  |> Logger.error()
end
```

As discussed we pass our sites to `HealthCheck.ping/1` then iterate the results with `Enum.each/2` applying our `report/1` function against each.
With these functions in place our scheduler is done and we can focus on testing it.

We won't focus too much on unit testing the schedulers since that won't require Bypass, so we can skip to the final code:

```elixir
defmodule Clinic.SchedulerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  defmodule TestCheck do
    def ping(_sites), do: [{:ok, "pong"}, {:error, "HTTP Status 404"}]
  end

  test "health checks are run and results logged" do
    opts = [health_check: TestCheck, interval: 1, sites: ["http://example.com", "http://example.org"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "pong"
    assert output =~ "HTTP Status 404"
  end
end
```

We rely on a test implementation of our health checks with `TestCheck` alongside `CaptureLog.capture_log/1` to assert that the appropriate messages are logged.

Now we have working `Scheduler` and `HealthCheck` modules, let's write an integration test to verify everything works together.
We'll need Bypass for this test and we'll have to handle multiple Bypass requests per test, let's see how we do that.

Remember the `bypass.port` from earlier?  When we need to mimic multiple sites, the `:port` option comes in handy.
As you've probably guessed, we can create multiple Bypass connections each with a different port, these would simulate independent sites.
We'll start by reviewing our updated `test/clinic_test.exs` file:

```elixir
defmodule ClinicTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  test "sites are checked and results logged" do
    bypass_one = Bypass.open(port: 1234)
    bypass_two = Bypass.open(port: 1337)

    Bypass.expect(bypass_one, fn conn ->
      Plug.Conn.resp(conn, 500, "Server Error")
    end)

    Bypass.expect(bypass_two, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    opts = [interval: 1, sites: ["http://localhost:1234", "http://localhost:1337"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "[info]  pong"
    assert output =~ "[error] HTTP Status 500"
  end
end
```

There shouldn't be anything too surprisingly in the above test.
Instead of creating a single Bypass connection in `setup`, we're creating two within our test and specifying their ports as 1234 and 1337.
Next we see our `Bypass.expect/2` calls and finally the same code we have in `SchedulerTest` to start the scheduler and assert we log the appropriate messages.

That's it!  We've built a utility to keep us informed if there are any issues with our domains and we've learned how to employ Bypass to write better tests with external services.
