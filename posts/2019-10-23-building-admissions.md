%{
  author: "Sean Callan",
  author_link: "https://github.com/doomspork",
  date: ~D[2019-10-23],
  tags: ["admissions", "general"],
  title: "Building Elixir School's Admissions portal",
  excerpt: """
  Follow along as we use build Elixir School's Slack invite portal: Admissions.
  """
}

---

If you didn't know, Elixir School has its own Slack where contributors can gather to discuss our organization's content and projects but most importantly, support one another in our Elixir journey. When we set out to create our own Slack we wanted to address a big concern with many public Slacks: the signal to noise ratio is bad, there's just too much spam.

> Have you contributed to an Elixir School project but not joined us on Slack? Head over to https://admissions.elixirschool.com to get your invite today!

So how can we keep our Slack public but prevent spammers from joining and do so in a way that doesn't add work to our maintainers? Our solution: required at least once contribution of any side to any one of our projects.

Achieving this required an application that used GitHub to verify a user's eligibility. This application would come to be known as: Admissions.

> Want to skip ahead and see the final product? The code can be found at https://github.com/elixirschool/admissions.

In this post we're going to explore how Admissions works and how we achieved our goals using Elixir and Phoenix. To start let's look at the expected flow and work from there:

![image](https://user-images.githubusercontent.com/73386/67163591-ff12a280-f32d-11e9-83f9-f033345f559b.png)

In addition to telling us how the application should function, this diagram breaks the flow up into convenient development tasks. Working from this diagram let's explore the individual tasks we'll need in order to fulfill our high level requirements:

1. Allow a user to sign in using GitHub and capture their access token. We can leverage [Ueberauth](https://github.com/ueberauth/ueberauth) and its [GitHub strategy](https://github.com/ueberauth/ueberauth_github) to do the heavy lifting for us.
2. With the user's access token use the GitHub API to see if the user has contributed to an organization's project. To avoid having to spend time writing our own GitHub API client we're going to make use of [Tentacat](https://github.com/edgurgel/tentacat).
3. Using the result of the API search, process the user's result
   1. In the event a user **is** a contributor, have them confirm the email address they want to use for Slack, use the Slack API to send an invite, and finally congratulate them.
   2. If they **have not** contributed we need to notify them of their ineligibility

### Login with GitHub

Starting from a new Phoenix project (`mix phx.new admissions`)  we looked at how to support GitHub login. For that we need a new dependency: `ueberauth_github`:

```elixir
  defp deps do
    [
      {:gettext, "~> 0.11"},
      {:phoenix, "~> 1.4.0"},
      {:phoenix_html, "~> 2.11"},
      {:plug_cowboy, "~> 2.0"},
      {:ueberauth_github, "~> 0.7.0"},

      {:phoenix_live_reload, "~> 1.2", only: :dev}
    ]
  end
```

> We won't need to include `ueberauth` itself, as a dependency  of `ueberauth_github` it is included for us.

> Helpful tip: Did you know you can use `mix hex.info <package name>` to get the latest version? Try it!

With our application empowered with our new dependency what's left to do? Plenty! To finish our integration with Ueberauth we had a few subtasks:

1. Create a `AuthController` that'll handle the callback phase of the OAuth request.

2. Include our new controller and route in our `router.ex` file.

3. Put the required configuration for Ueberauth in our `config/config.exs` file.

4. Add a button to the UI for login. While we won't spend time in this article building the UI, we will touch on the required pieces.

5. Setting up your application on GitHub. Here you'll also need to retrieve your `CLIENT_ID` and `CLIENT_SECRET` .

   > GitHub setup and configuration goes beyond this article. If you aren't quite sure what to do, head over to GitHub's Developer article [Authorizing OAuth Apps](https://developer.github.com/apps/building-oauth-apps/authorizing-oauth-apps/)

Onward!

#### Our new controller

Completing our first subtask requires we create a new controller for Ueberauth that will handle the OAuth callback from GitHub in the event of successful login. The only hard requirement for our controller is that we include the Ueberauth plug:

```elixir
defmodule AdmissionsWeb.AuthController do
  use AdmissionsWeb, :controller

  plug Ueberauth
end
```

With the plug in place, we'll define a function to handle our requests. We've elected to name that function `callback/2`. This function needs to retrieve the user details Ueberauth has so conveniently placed into the `Plug.Conn` assigns for us. The fields we're concerned with are the user's email and GitHub nickname:

```elixir
defmodule AdmissionsWeb.AuthController do
  use AdmissionsWeb, :controller

  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: ueberauth_auth}} = conn, _params) do
    %{info: %{email: email, nickname: nickname}} = ueberauth_auth
  end
end
```

There's no need to concern ourselves _in this instance_ with a match error because all successful logins will contain the aforementioned fields.

Now that we've got what we need, we need to forward the user on to the next step in the process: determining eligibility. To ensure we've got what we need in the next step, we chose to put our GitHub data into the session and then redirect the user to the eligibility check:

```elixir
defmodule AdmissionsWeb.AuthController do
  use AdmissionsWeb, :controller

  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: ueberauth_auth}} = conn, _params) do
    %{info: %{email: email, nickname: nickname}} = ueberauth_auth

    conn
    |> put_session(:github, %{email: email, nickname: nickname, token: token})
    |> redirect(to: Routes.registrar_path(conn, :eligibility))
  end
end
```

With that in place we're done with our controller and can move on to the next subtask, updating our `router.ex`. We'll be implementing our `eligibility` request handler shortly.

#### Updating Phoenix's router

Updating the router for Ueberauth is a fairly easy and straightforward change. At the bottom of our `router.ex` we added the following scope block:

```elixir
scope "/auth", AdmissionsWeb do
  pipe_through :browser

  get "/github", AuthController, :request
  get "/github/callback", AuthController, :callback
end
```

We added 2 routes but only 1 request handler, `callback/2` in our controller so what gives? Remember `plug Ueberauth` from our controller? Our good friend Ueberauth takes care of that request phase of the OAuth exchange saving us the hassle.

At this stage we're almost done with our integration. Now we can move on to configuring Ueberauth for our application.

#### Ueberauth configuration

The Ueberauth GitHub strategy's documentation provided us everything we needed. Since we need the user's email and profile access we had to update our scopes to `user:email,user:profile` per GitHub's documentation.

The resulting changes to our `config.exs` looked like this:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email,user:profile", send_redirect_uri: false]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")
```

With `System.get_env/1` we avoid checking secret values into source control in addition to supporting changes to those values at runtime. We populate the `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` system ENVs in a later step using values retrieved from our GitHub application settings.

> Confused about compile and runtime configuration? Check out our blog post [Configuration Demystified](https://elixirschool.com/blog/configuration-demystified/) to learn more.

An optional but strongly encouraged configuration is to update the `oauth2` serializer to use the newer JSON library [Jason](https://github.com/michalmuskala/jason):

```elixir
config :oauth2,
  serializers: %{
    "application/json" => Jason
  }
```

To do this we added `jason` to our `mix.exs` just as we did before with `ueberauth_github`.

#### Sign-in button

To kick off the auth flow for GitHub logins we need the user to click a link for the earlier request route we defined. To do that we added the following HTML to our `index.html.eex` file:

```html
<a class="button is-info is-medium" href="/auth/github">
  <span class="icon">
    <i class="fab fa-github"></i>
  </span>
  <span>Sign-in with GitHub</span>
</a>
```

Now that our UI is updated we can call our Ueberauth integration code complete! The last step for us was setting up the application on GitHub. Once complete we pulled the `CLIENT_ID` and `CLIENT_SECRET` from the application settings and added them to our ENV.

A user can now sign-in with a valid GitHub account. We need to handle the next step in the process: eligibility.

### Verifying contributor status

At this stage in the request our user has successfully authenticated with GitHub and now we need to determine if they've contributed to any of our repositories. To achieve this we need to leverage the GitHub API. For this portion of the application the high level of what we're doing looks like:

![image](https://user-images.githubusercontent.com/73386/67163600-19e51700-f32e-11e9-89c3-a14b6a9bde8d.png)

In the interest of not reinventing the wheel we opted for the [Tentacat](https://github.com/edgurgel/tentacat) library. At this point in our journey our `mix.exs` dependencies looked like this:

```elixir
  defp deps do
    [
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.4.0"},
      {:phoenix_html, "~> 2.11"},
      {:plug_cowboy, "~> 2.0"},
      {:tentacat, "~> 1.5"},
      {:ueberauth_github, "~> 0.7.0"},

      {:phoenix_live_reload, "~> 1.2", only: :dev}
    ]
  end
```

With our new dependency in place we can fetch (`mix deps.get`) and get on our way. Keeping our controller's simple and focused on presentation is a goal we always shoot for so we decided to implement the eligibility code in a separate module outside of the web portion of our application.

We've called this new module `Registrar` in keeping with our college theme, it can be found in the `lib/admissions/registrar.ex` file.

>  ### reg·is·trar
>
> 1. An official in a college or university who is responsible for keeping student records.

Given the flow above we determined the best way to achieve this would be to check a list of repositories in our organization (with support for multiple organizations) for contributors who matched our user's GitHub nickname. To this end we knew we'd need to store the organization's name and its repositories. For this we opted to use a map where an organization name's is the key and the value is a list of repositories. To avoid any type casting we elected to store everything as strings, the end result of which was added to our `config.exs`:

```elixir
config :admissions, repositories: %{
  "elixirschool" => ["elixirschool", "admissions", "extracurricular", "homework"]
}
```

> To support some future plans we opted to support multiple organizations. This also allows other organizations and companies to leverage the Admissions.

When implementing the actual checks we found breaking things up into a few functions worked best to keep the code clean and readable. We ended up with 4 functions in our new `lib/admissions/registrar.ex` file:

1. Our only public function `eligibile?/1` takes a nickname.
2. A private function `org_contributor?/3` which takes the GitHub API client we'll create with the token, the user's nickname, and lastly a key-value pair from our `config :admissions, repositories` map.
3. A function to check each repository's contributors for our user: `contributor?/4`. We'll need the GitHub API client, nickname, organization, and a repository.
4. Lastly, a function to retrieve our configuration from above: `organizations/0`. We prefer to use functions in place of module attributes when loading configuration values.

To get it out of the way tackled the easiest function, `organization/0`, where we do no more than get our configuration:

```elixir
def organizations, do: Application.get_env(:admissions, :repositories)
```

With our configuration available we can iterate over the organizations and look for contributor status. For that we'll need to create a Tentacat GitHub API client. Let's take a peek at what we ended up with in our `eligible?/2` function:

```elixir
def eligible?(nickname) do
  client = Client.new()
  Enum.any?(organizations(), &org_contributor?(client, nickname, &1))
end
```

Here we create a `Tentacat.Client` and iterate over configured organizations using `Enum.any?/2`. We don't much care for complex anonymous functions so we elected to create `org_contributor/2` . This function is simple enough: Take single organization from our configuration and iterate through the repositories looking for a match:

```elixir
defp org_contributor?(client, nickname, {org, repos}) do
  Enum.any?(repos, &contributor?(client, nickname, org, &1))
end
```

Last but not least is our `contributor?/4` function that does the real work.  We have to retrieve the list of contributors for a repository and verify whether or not our nickname is present in the list. Thanks to Tentacat this is fairly easy using the `Tentacat.Repositories.Contributors` module and `list/3` function which returns a tuple including a list of our contributors, the other values we can ignore:

```elixir
defp contributor?(client, nickname, org, repo) do
  case Contributors.list(client, org, repo) do
    {_status, contributors, _response} ->
      Enum.any?(contributors, &(Map.get(&1, "login") == nickname))
    _ ->
      false
  end
end
```

The contributor list is a collection of maps containing _all_ of the information pertaining to a GitHub user but we're most interested in the`"login"` key, the user's nickname.

Now we can finally answer the question: Are they a contributor?

### Processing the user's request

Now that we know whether or not the user is a contributor we need to do something with that. If they **are not** a contributor they can't proceed and we should tell them as much. However, if they **are** a contributor then we need to verify their email address so we can send them an invitation via the Slack API. Visualized, our flow looks something like this:

![image](https://user-images.githubusercontent.com/73386/67163615-35502200-f32e-11e9-8204-294d73790e0c.png)

#### Handling eligibility

Using our new `Registrar.eligible?/1` function we'll implement the `RegistrarController`'s `eligibility/2` route handler we briefly discussed earlier. This will be the point in our flow where our user's path diverge based on their contributor status. We concluded the simplest approach for this would be deciding the view template based on the answer to our question, with eligible users seeing `eligible.html` which includes the email address verification step and `ineligible.html` for all others.

To accomplish our goal we retrieve our user's information from our session, call into our new `eligible?/1` function, decide on our template, and finally call `render/3` with our connection, template, and the user's email and GitHub username:

```elixir
def eligibility(conn, _params) do
  %{email: email, nickname: nickname} = get_session(conn, :github)

  template = if Registrar.eligible?(nickname), do: "eligible.html", else: "ineligible.html"

  render(conn, template, %{email: email, nickname: nickname})
end
```

With our new function in place we added the new `/eligibility` route to the `router.ex` file, this time adding the `:auth` pipeline to limit access to only authenticated users. While we're in the router file we can add the next route we'll need, a `POST` for the email address submission:

```elixir
scope "/", AdmissionsWeb do
  pipe_through [:browser, :auth]

  get "/eligibility", RegistrarController, :eligibility
  post "/register", RegistrarController, :register
end
```

At this point non-contributors have been handled, they're encouraged to find opportunities to contribute and try again later. Our contributors have 1 final step left: verifying the email address they'd like their invite sent to.

#### Slack invitation

We have reached our very final step: inviting contributors to Slack! To do this will require the use of the official Slack API and the `users.admin.invite` function they provide. This request must be a form POST with the user's email we collected in the last step and our organization's Slack token, there are some optional Slack settings you can include as well.

> You can find more on the Slack API in the official documentation at https://api.slack.com/

Once we handled our response we had a working API client:

```elixir
defmodule Admissions.Slack do
  @invite_url "https://elixirschool.slack.com/api/users.admin.invite"

  def invite(email) do
    email
    |> slack_invite()
    |> slack_response()
  end

  defp slack_invite(email) do
    data = [email: email, set_active: true, token: slack_token()]
    HTTPoison.post(@invite_url, {:form, data})
  end

  defp slack_response({:ok, %{body: body}}) do
    case Jason.decode(body) do
      {:ok, %{"ok" => true}} -> :ok
      {:ok, %{"error" => reason}} -> {:error, reason}
    end
  end

  defp slack_response({:error, _reason}) do
    {:error, "unexpected_error"}
  end

  defp slack_token, do: System.get_env("SLACK_TOKEN")
end
```

With an API client in hand all that remains is implementing the `/register` route handler. To do this we outlined what was expected of our new function and set to work building it:

1. Knowing our request a body has the `"email"` key, pattern matching is used to get the value we care about: their email address.
2. Our new Slack API client is used to trigger and invite
3. We handle the result
   1. On success we show them a welcome page
   2. On failure we show them an error message. The Slack documentation outlines a few error codes we'll match on and translate into human readable messages: `already_in_team`, `already_invited`, `invalid_email`, and lastly the `unexpected_error` we returned in the client.

Once we'd decided on the work updating the `RegistrarController` was straight forward:

```elixir
def register(conn, %{"email" => email}) do
  case Slack.invite(email) do
    :ok ->
      render(conn, "welcome.html")
    {:error, reason} ->
      message = translated_message(reason)
      render(conn, "error.html", message: message)
  end
end

defp translated_message("already_in_team"), do: "Already in team"
defp translated_message("already_invited"), do: "Already invited"
defp translated_message("invalid_email"), do: "Invalid email address"
defp translated_message("unexpected_error"), do: "Unexpected error"
```

We've already added a route for this function so we're done. Like done done. We have a functioning application that requires sign in with GitHub, confirms their contributor status, and invites them to Slack when appropriate. Since the organizations are configurable there's no stopping other organizations from using Admissions, how cool!

Have you contributed to an Elixir School project but not yet joined Slack? Head over to [http://admissions.elixirschool.com](http://admissions.elixirschool.com/) and check your eligibility!

Interested in seeing the code in it's entirity? Looking for a contribution opportunity to unlock Slack access? You can find the project on GitHub at https://github.com/elixirschool/admissions.
