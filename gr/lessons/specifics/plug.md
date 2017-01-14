---
layout: page
title: Plug
category: specifics
order: 1
lang: gr
---

Αν είστε εξοικειομένοι με τη Ruby μπορείτε να σκεφτείτε το Plug σαν το Rack με λίγο Sinatra.  Παρέχει εναν προσδιορισμό για στοιχεία εφαρμογών web και αντάπτορες για εξυπηρετητές web.  Παρόλο που δεν είναι μέρος του πυρήνα της Elixir, είναι ένα επίσημο Elixir project.

{% include toc.html %}

## Εγκατάσταση

Η εγκατάσταση είναι πανεύκολη με το mix.  Για να εγκαταστήσουμε το Plug, χρειάζεται να κάνουμε δύο μικρές αλλαγές στο αρχείο μας `mix.exs`.  Το πρώτο πράγμα που πρέπει να κάνουμε είναι να προσθέσουμε το Plug και έναν εξυπηρετητή web (θα χρησιμοποιήσουμε τον Cowboy) στο αρχείο μας σαν εξαρτήσεις:

```elixir
defp deps do
  [{:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"}]
end
```

Το τελευταίο πράγμα που χρειάζεται να κάνουμε είναι να προσθέσουμε τον εξυπηρετητή web και το Plug στην εφαρμογή OTP μας:

```elixir
def application do
  [applications: [:cowboy, :logger, :plug]]
end
```

## Προσδιορισμός

Για να ξεκινήσουμε να φτιάχνουμε Plugs, θα πρέπει να ξέρουμε, και να εμμένουμε, στις προδιαγραφές Plug.  Ευτυχώς για εμάς, υπάρχουν μόνο δύο συναρτήσεις που είναι απαραίτητες: οι `init/1` και `call/2`.

Η συνάρτηση `init/1` χρησιμοποιείται για να αρχικοποιήσει τις επιλογές του Plug μας, οι οποίες περνάνε σαν το δεύτερο όρισμα στην συνάρτηση `call/2` μας.  Επιπρόσθετα στις αρχικοποιημένες επιλογές, η `call/2` δέχεται ένα `%Plug.Conn` σαν το πρώτο όρισμα και αναμένεται να επιστρέψει μια σύνδεση.

Ορίστε ένα απλό Plug που επιστρέφει "Γειά σου κόσμε!";

```elixir
defmodule HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Γειά σου κόσμε!")
  end
end
```

## Δημιουργία ενός Plug

Για αυτό το παράδειγμα θα δημιουργήσουμε ένα Plug για να επιβεβαιώσουμε αν μια αίτηση έχει κάποιο σετ απαιτούμενων παραμέτρων.  Υλοποιώντας την επικύρωσή μας σε ένα Plug μπορούμε να βεβαιωθούμε ότι μόνο έγκυρες αιτήσεις θα τα καταφέρουν να περάσουν στην εφαρμογή μας.  Αναμένουμε το Plug μας να αρχικοποιηθεί με δύο επιλογές: τις `:paths` και `:fields`.  Αυτές θα αναπαριστούν τα μονοπάτια που εφαρμόζουμε τη λογική μας και ποιά πεδία να απαιτήσουμε.

_Σημείωση_: Τα Plugs εφαρμόζονται σε όλες τις αιτήσεις, γι' αυτό θα φιλτράρουμε τις αιτήσεις και θα εφαρμόσουμε τη λογική μας σε ένα υποσύνολο αυτών.  Για να αγνοήσουμε μια αίτηση απλά μεταφέρουμε την αίτηση.

Θα ξεκινήσουμε κοιτάζοντας το ολοκληρωμένο Plug μας και μετά θα συζητήσουμε πως λειτουργεί.  Θα το δημιουργήσουμε στο `lib/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
  import Plug.Conn

  defmodule IncompleteRequestError do
    @moduledoc """
    Σηκώνεται ένα σφάλμα όταν ένα απαιτούμενο πεδίο λείπει
    """

    defexception message: "", plug_status: 400
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.body_params, opts[:fields])
    conn
  end

  defp verify_request!(body_params, fields) do
    verified = body_params
               |> Map.keys
               |> contains_fields?(fields)
    unless verified, do: raise IncompleteRequestError
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

Το πρώτο πράγμα που πρέπει να σημειώσουμε είναι ότι ορίσαμε μια νέα εξαίρεση, την `IncompleteRequestError` και ότι μια από τις επιλογές της είναι η `:plug_status`.  Όταν είναι διαθέσιμη, αυτή η επιλογή χρησιμοποιείται από το Plug για να ορίσει τον κωδικό κατάστασης HTTP στην περίπτωση μιας εξαίρεσης.

Το δεύτερο μέρος του Plug μας είναι η συνάρτηση `call/2`.  Εδώ είναι που αποφασίζουμε αν θα εφαρμόσουμε ή όχι την λογική επικύρωσης.  Μόνο όταν η διαδρομή της αίτησης περιλαμβάνεται στην επιλογή μας `:paths`, τότε θα καλέσουμε την `verify_request!/2`.

Το τελευταίο μέρος του plug μας είναι η ιδιωτική συνάρτηση `verify_request!/2` η οποία επικυρώνει αν τα απαιτούμενα `:fields` είναι όλα παρόντα.  Σε περίπτωση που κάποια λείπουν, σηκώνουμε το σφάλμα `IncompleteRequestError`.

## Χρήση του Plug.Router

Τώρα που έχουμε το plug μας `VerifyRequest`, μπορούμε να συνεχίσουμε στον δρομολογητή μας.  Όπως θα δούμε, δεν χρειαζόμαστε κάποιο σκελετό εφαρμογών όπως το Sinatra στην Elixir από τη στιγμή που το έχουμε μαζί με το Plug.

Για να ξεκινήσουμε ας δημιουργήσουμε ένα αρχείο στο `lib/plug/router.ex` και ας αντιγράψουμε τα ακόλουθα σε αυτό:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Καλώς Ήρθατε")
  match _, do: send_resp(conn, 404, "Ουπς!")
end
```

Αυτός είναι ο τελείως βασικός δρομολογητής αλλά ο κώδικας θα πρέπει να είναι αρκετά αυτονόητος.  Συμπεριλάβαμε μερικές μακροεντολές μέσω της `use Plug.Router` και τότε ορίσαμε δύο προεγκατεστημένα Plugs: τα `:match` και `:dispatch`.  Υπάρχουν δύο ορισμένες διαδρομές, μια για το χειρισμό αιτήσεων GET στην ριζική διαδρομή και τη δεύτερη για το ταίριασμα όλων των άλλων αιτήσεων ώστε να επιστρέφουμε ένα μήνυμα 404.

Ας προσθέσουμε το Plug μας στο δρομολογητή:

```elixir
defmodule Example.Plug.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug VerifyRequest, fields: ["content", "mimetype"],
                      paths:  ["/upload"]
  plug :match
  plug :dispatch

  get "/", do: send_resp(conn, 200, "Welcome")
  post "/upload", do: send_resp(conn, 201, "Uploaded")
  match _, do: send_resp(conn, 404, "Oops!")
end
```

Αυτό ήταν!  Ρυθμίσαμε το Plug μας να επιβεβαιώνει ότι όλες οι αιτήσεις στη διαδρομή `/upload` θα περιλαμβάνουν τα `"content"` και `"mimetype"`.  Μόνο τότε θα εκτελεστεί ο κώδικας δρομολόγησης.

Για τώρα το καταληκτικό σημείο `/upload` δεν είναι και πολύ χρήσιμο αλλά είδαμε πως να δημιουργήσουμε και ενσωματώσουμε το Plug μας.

## Τρέχοντας την εφαρμογή web μας

Πριν τρέξουμε την εφαρμογή μας χρειαζόμαστε να εγκαταστήσουμε και ρυθμίσουμε τον εξυπηρετητή web μας, ο οποίο για τώρα είναι ο Cowboy.  Για τώρα θα κάνουμε απλά τις αλλαγές στον κώδικα για να τρέξουμε τα πάντα και θα τα αναλύσουμε σε μεταγενέστερα μαθήματα.

Ας αρχίσουμε αναβαθμίζοντας το κομμάτι `application` του αρχείου μας `mix.exs` για να πούμε στην Elixir για την εφαρμογή μας και να ορίσουμε μια μεταβλητή περιβάλλοντος (env).  Με αυτές τις αλλαγές ο κώδικάς μας θα πρέπει να δείχνει κάπως έτσι:

```elixir
def application do
  [applications: [:cowboy, :plug],
   mod: {Example, []},
   env: [cowboy_port: 8080]]
end
```

Στη συνέχεια χρειαζόμαστε να αναβαθμίσουμε το `lib/example.ex` ώστε να ξεκινήσουμε και επιτηρήσουμε τον Cowboy:

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Plug.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

> (Προεραιτικά) προσθέστε το `:cowboy_port` στο `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Τώρα για να τρέξουμε την εφαρμογή μας μπορούμε να χρησιμοποιήσουμε:

```shell
$ mix run --no-halt
```

## Δοκιμή ενός Plug

Η δοκιμή των Plugs είναι αρκετά προφανής χάρη στο `Plug.Test`.  Περιλαμβάνει έναν αριθμό βοηθητικών συναρτήσεων για να κάνει εύκολες τις δοκιμές.

Δείτε αν μπορείτε να ακολουθήσετε αυτή τη δοκιμή δρομολογητή:

```elixir
defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Plug.Router

  @content "<html><body>Γειά!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn = conn(:get, "/", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn = conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
           |> put_req_header("content-type", "application/x-www-form-urlencoded")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn = conn(:get, "/missing", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

## Διαθέσιμα Plugs

Υπάρχει ένας αριθμός από Plugs διαθέσιμα από την αρχή.  Η πλήρης λίστα μπορεί να βρεθεί στα έγγραφα Plug [εδώ](https://github.com/elixir-lang/plug#available-plugs).
