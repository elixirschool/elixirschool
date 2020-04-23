---
author: Sophie DeBenedetto
author_link: https://github.com/sophiedebenedetto
categories: general
tags: ['plug', 'authentication']
date:   2018-11-29
layout: post
title:  JWT Auth in Elixir with Joken
excerpt: >
  Use Joken and JOSE for a light-weight implementation of JWT Auth in your Elixir web application.
---

[JSON Web Tokens](https://jwt.io/introduction/), or JWTs, allow us to authenticate requests between the client and the server by encrypting authentication information into a secure, compact JSON object that is digitally signed. In this post, we'll use the [Joken](https://github.com/bryanjos/joken) library to implement JWT auth in a Phoenix app. We'll focus on JWTs that are signed using a ECDSA private/public key pair, although you can also sign JWTs using an HMAC algorithm.

## Getting Started

First things first, we need to include the Joken package in our application's dependencies:

```elixir
def deps do
  # .. other deps
  {:joken, "~> 2.0-rc0"}
end
```

Run `mix deps.get` and you're ready to use Joken!

## A Note on Encryption

**We'll be decrypting tokens that were generated using an ECDSA private/public key pair.** This means that we'll need access to the public key in order to enact the decryption. Where you store that public key is up to you. You can store it in a `.pem` file, accessible to your application; you can serve it from an endpoint; you can store it in an environment variable--to name a few options.

This post assumes that your code has access to the public portion of the ECDSA private/public key pair in the form of a string that looks something like this:

```
-----BEGIN PUBLIC KEY-----
blahblahblah
yaddayaddayadda
-----END PUBLIC KEY-----
```

## The Decryption Module

We'll define a module, `JwtAuthToken` that is responsible for decrypting a JWT given the token and the public key.

```elixir
defmodule MyAppWeb.JwtAuthToken do
  def decode(jwt_string, public_key) do
    # coming soon!
  end
end
```

The public API of our module is simple. It exposes a function `decode/2` which takes in the arguments of the JWT string and the ECDSA public key string. It will use the public key to decrypt the JWT.

### How Does Joken Decode and Verify?

In order to decode and verify our JWT string, Joken needs two things:

* A `Joken.Token` struct
* A `Joken.Signer` struct

So, we need to use our token _string_ to generate a `Joken.Token` and we need to use our ECDSA public key PEM file to generate a `Joken.Signer` struct. Then, we'll call `Joken.verify/2` with these two structs as arguments.

### Generating the `Joken.Token`

In order to generate this struct, we'll call `Joken.token/1`. We pass in an argument of the JWT string:

```elixir
defmodule MyAppWeb.JwtAuthToken do
  def decode(jwt_string, public_key) do
   jwt_string
   |> Joken.token
  end
end
```
This will return the `Joken.Token` struct in the following format:

```elixir
%Joken.Token{                                                                                                            claims: %{},                                                                                                           claims_generation: %{},
  error: nil,
  errors: [],
  header: %{},
  json_module: Poison,
  signer: nil,
  token: "blah.blah.blah",
  validations: %{}
}
```

#### Validating Token Expiration

We're not quite done with our token struct though. Notice that the `:validations` key points to an empty map. The data stored under `:validations` key of the token struct will be used by `Joken.verify/2` to determine the validity of a decoded token's claims. Our token's encoded claims will include an *expiration date*, under a key of `"exp"`. We *only* want a decoded token to be considered valid if the `"exp"` in the claims has is not in the past. So, we'll leverage `Joken.with_validation` to write a validation function that returns true if the token's claims' `"exp"` is _not_ in the past:

```elixir
defmodule MyAppWeb.JwtAuthToken do
  def decode(jwt_string, public_key) do
   jwt_string
   |> Joken.token
   |> Joken.with_validation("exp", &(&1 > Joken.current_time()))
  end
end
```

Now our token struct looks like this:

```elixir
%Joken.Token{
  claims: %{},
  claims_generation: %{},
  error: nil,
  errors: [],
  header: %{},
  json_module: Poison,
  signer: nil,
  token: "blah.blah.blah",
  validations: %{"exp" => {#Function<6.99386804/1 in :erl_eval.expr/5>, nil}}
}
```

Such that when we later call `Joken.verify/2`, Joken will execute the function stored under the `"exp"` key of the `:validations` struct with an argument of the value stored under the `"exp"` of the decoded token's claims.

If this function returns `true`, Joken will expose the decoded token's claims:

```elixir
%Joken.Token{
  claims: %{
    "aud" => ["user"],
    "email" => "guy@email.com.com",
    "exp" => 1540399830,
    "iat" => 1540392630,
    "nbf" => 1540392630,
    "sub" => "ea375e5a-f918-4017-a5ee-1fc8b641ef84"
  },
  claims_generation: %{},
  error: nil,
  errors: [],
  header: %{},
  json_module: Poison,
  signer: <coming soon!>,
  token: "blah.blah.blah",
  validations: %{
    "exp" => {#Function<0.91892837/1 in DeployerWeb.JwtAuthToken.decode/2>, nil}
  }
}
```

If it returns `false`, Joken will return the token struct _without_ the decoded claims and _with_ an error message:

```elixir
%Joken.Token{
  claims: %{},
  claims_generation: %{},
  error: "Invalid payload",
  errors: ["Invalid payload"],
  header: %{},
  json_module: Poison,
  signer: <coming soon!>,
  token: "blah.blah.blah",
  validations: %{
    "exp" => {#Function<0.91892837/1 in DeployerWeb.JwtAuthToken.decode/2>, nil}
  }
}
```

Now that we have our token struct ready to go, we can generate the `Joken.Signer` struct.

### Generating the `Joken.Signer`

In order to generate the signer struct, we need to build our ECDSA public key struct. We can doing this using `JOSE`.

#### Generating the ECDSA Signing Key with `JOSE`

[`JOSE`](https://github.com/potatosalad/erlang-jose) stands for JSON Object Signing and Encryption. Its a set of standards developed by the JOSE Working Group. The `JOSE` package is a dependency of Joken, so we don't need to install it ourselves via our application dependencies.

Joken needs our public key in the form of a map in order to use it to decrypt our token. We'll use the `JOSE.JWK` (JWK stands for JSON Web Key) module to turn our public key string into a map.

Let's define a private helper function, `signing_key` in our `MyAppWeb.JwtAuthToken` module:

```elixir
defmodule MyAppWeb.JwtAuthToken do
  ...

  defp signing_key(public_key) do
    { _, key_map } = public_key
      |> JOSE.JWK.from_pem
      |> JOSE.JWK.to_map
    key_map
  end
end
```

The first function call, `JOSE.JWK.from_pem` converts our public key PEM binary into a `JOSE.JWK`. The second function call, `JOSE.JWK.to_map` (you guessed it) converts that `JOSE.JWK` into a map. So, we end up with a tuple that looks like this:

{% raw %}
```elixir
{%{kty: :jose_jwk_kty_ec},
 %{
   "crv" => "P-256",
   "kty" => "EC",
   "x" => "xxxx",
   "y" => "xxxx"
 }}
```
{% endraw %}

Where the second element of the tuple is the ECDSA public key map. Joken will use this map as a key when generating an ECDSA signer.

#### Generating the Signer

`Joken.Signer` is the JWK (JSON Web Key) and JWS (JSON Web Signature) configuration of Joken. The signer allows us to generate a token signature or read the token signature during decryption. We want to generate an ECDSA signer with our public key. Then, we can use this signer to decrypt our token.

We'll define another private helper function, `signer/1`, to do this:

```elixir
defmodule MyAppWeb.JwtAuthToken do
  ...
  defp signer(public_key_string) do
    public_key_string
    |> signing_key
    |> Joken.es256
  end

  defp signing_key(public_key_string) do
    { _, key_map } = public_key_string
      |> JOSE.JWK.from_pem
      |> JOSE.JWK.to_map
    key_map
  end
end
```

Here, we use the `Joken.es256` function, with the argument of our public key map, to generate an ECDSA token signer. The `es256` function wraps a call to [`Joken.Signer.es/2`](https://hexdocs.pm/joken/Joken.Signer.html#es/2) which takes in the algorithm type and the key map and returns the signer.

Now that we have our ECDSA signer, we're ready to decode our token!

### Decoding the Token with the Token and the Signer

```elixir
defmodule MyApp.Web.JwtAuthToken do
  def decode(jwt_string, public_key_string) do
    jwt_string
    |> Joken.token
    |> Joken.with_validation("exp", &(&1 > Joken.current_time()))
    |> Joken.with_signer(signer(public_key_string))
    |> Joken.verify
  end

  defp signer(public_key_string) do
    public_key_string
    |> signing_key
    |> Joken.es256
  end

  defp signing_key(public_key_string) do
    { _, key_map } = public_key_string
      |> JOSE.JWK.from_pem
      |> JOSE.JWK.to_map
    key_map
  end
end
```

Now we can easily decrypt JWTs like this:

```elixir
JwtAuthToken.decode(jwt_string, public_key)
=> {
     :success,
     %{
       token: "blah.blah.blah",
       claims: %{sub: "1234", email: "guy@email.com"}
     }
   }
```

Let's use our decoder in a custom plug to prevent anyone without a valid JWT from accessing our app's endpoints.

## The Auth Plug

We'll build a custom plug, `JwtAuthPlug`, that we'll place in the pipeline of our authenticated routes:

```elixir
# router.ex
...
pipeline :api do
  plug :accepts, ["json"]
  plug MyAppWeb.JwtAuthPlug
end
```

Our plug is pretty simple, it will:

1. Grab the JWT from the request's cookie
2. Call on our `JwtAuthToken.decode/2` function to decode it

If it can successfully decode the JWT, it will allow the request through. If not, it will return a `401` unauthorized status

Let's get started!

### Defining the Custom Plug

Defining a custom plug is pretty simple. We need to `import Plug.Conn` to get access to some helpful connection-interaction functions. Then, we need an `init` function and a `call` function.

```elixir
defmodule MyAppWeb.JwtAuthPlug do
  import Plug.Conn
  alias MyAppWeb.JwtAuthToken

  def init(opts), do: opts

  def call(conn, _opts) do
    # coming soon!
  end
end
```

### Getting the JWT from the Cookie

We'll define a helper function, `jwt_from_cookie`, that will pluck the JWT string from the request cookie:

```elixir
defmodule MyAppWeb.JwtAuthPlug do
  import Plug.Conn
  alias MyAppWeb.JwtAuthToken

  ...

  defp jwt_from_cookie(conn) do
    conn
    |> Plug.Conn.get_req_header("cookie")
    |> List.first
    |> Plug.Conn.Cookies.decode
    |> token_from_map(conn)
  end

  defp token_from_map(%{"session_jwt" => jwt}, _conn), do: jwt

  defp token_from_map(_cookie_map, conn) do
    conn
    |> forbidden
  end

  defp forbidden(conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.render(MyAppWeb.ErrorView, "401.html")
    |> halt
  end
end
```

Here, we use a convenient `Plug.Conn` function to get value of the Cookie request header: `Plug.Conn.get_req_header`. Then, we use another function, `Plug.Conn.Cookies.decode` to turn that value (a string separated by `,`, `, ` or `;`) into a map. Lastly, we pattern-match the JWT out of the map.

Now that we have our JWT, let's decode it!

### Decoding the JWTs

```elixir
defmodule MyAppWeb.JwtAuthPlug do
  import Plug.Conn
  alias MyAppWeb.JwtAuthToken

  def call(conn, _opts) do
    case JwtAuthToken.decode(jwt_from_map, public_key) do
      { :success, %{token: token, claims: claims} } ->
        conn |> success(claims)
      { :error, error } ->
        conn |> forbidden
    end
  end

  defp public_key do
    # your public key string that you read from a PEM file or stored in an env var or fetched from an endpoint
  end

  defp success(conn, token_payload) do
    assign(conn, :claims, token_payload.claims)
    |> assign(:jwt, token_payload.token)
  end
end
```

And that's it!

## Conclusion

Joken makes it easy to decode JWTs in your Phoenix application. By generating your own ECDSA signer using `JOSE`, and building a simple custom plug, you can keep your routes secure. Happy coding!
