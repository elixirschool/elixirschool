---
version: 1.1.2
title: Plug
---

Αν είστε εξοικειομένοι με τη Ruby μπορείτε να σκεφτείτε το Plug σαν το Rack με λίγο Sinatra.
Παρέχει εναν προσδιορισμό για στοιχεία εφαρμογών web και αντάπτορες για εξυπηρετητές web.
Παρόλο που δεν είναι μέρος του πυρήνα της Elixir, είναι ένα επίσημο Elixir project.

Θα ξεκινήσουμε με τη δημιουργία μίας μινιμαλιστικής εφαρμογής βασισμένης στο Plug.
Στη συνέχεια, θα μάθουμε για το δρομολογητή του Plug και πως να προσθέσετε ένα Plug σε μια υπάρχουσα εφαρμογή web.

{% include toc.html %}

## Προαπαιτούμενα

Αυτός ο οδηγός υποθέτει ότι έχετε ήδη εγκαταστήσει την Elixir 1.4 ή υψηλότερη και το `mix`.

Αν δεν έχετε ξεκινήσει ένα project ήδη, δημιουργήστε ένα ως εξής:

```shell
$ mix new example
$ cd example
```

## Εξαρτήσεις

Η προσθήκη εξαρτήσεων είναι πανεύκολη με το mix.
Για να εγκαταστήσουμε το Plug, χρειάζεται να κάνουμε δύο μικρές αλλαγές στο αρχείο μας `mix.exs`.
Το πρώτο πράγμα που πρέπει να κάνουμε είναι να προσθέσουμε το Plug και έναν εξυπηρετητή web (θα χρησιμοποιήσουμε τον Cowboy) στο αρχείο μας σαν εξαρτήσεις:

```elixir
defp deps do
  [
    {:cowboy, "~> 1.1.2"},
    {:plug, "~> 1.3.4"}
  ]
end
```

Στη γραμμή εντολών, τρέξτε την ακόλουθη εργασία mix για να κατεβάσετε τις νέες αυτές εξαρτήσεις:

```shell
$ mix deps.get
```

## Προσδιορισμός

Για να ξεκινήσουμε να φτιάχνουμε Plugs, θα πρέπει να ξέρουμε, και να εμμένουμε, στις προδιαγραφές Plug.
Ευτυχώς για εμάς, υπάρχουν μόνο δύο συναρτήσεις που είναι απαραίτητες: οι `init/1` και `call/2`.

Ορίστε ένα απλό Plug που επιστρέφει "Γειά σου κόσμε!";

```elixir
defmodule Example.HelloWorldPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Γειά σου κόσμε!")
  end
end
```

Αποθηκεύστε το αρχείο στο `lib/example/hello_world_plug.ex`.

Η συνάρτηση `init/1` χρησιμοποιείται για να αρχικοποιήσει τις επιλογές του Plug μας. Καλείται από το δέντρο επιτήρησης μας, το οποίο εξηγείται στο επόμενο τμήμα. Για τώρα, θα είναι μια άδεια Λίστα η οποία αγνοείται.

Η τιμή που επιστρέφεται από την `init/1` περνάει σαν το δεύτερο όρισμα στην συνάρτηση `call/2` μας.

Η συνάρτηση `call/2` καλείται για κάθε νέα αίτηση που έρχεται στον εξυπηρετητή μας, τον Cowboy.
Δέχεται μία δομή σύνδεσης `%Plug.Conn` σαν το πρώτο όρισμα και αναμένεται να επιστρέψει μια δομή σύνδεσης `%Plug.Conn{}`.

## Ρύθμιζοντας την Ενότητα Εφαρμογής του Project

Απο τη στιγμή που ξεκινάμε μια εφαρμογή Plug από την αρχή, πρέπει να ορίσουμε την ενότητα εφαρμογής.
Ενημερώστε το `lib/example.ex` ώστε να ξεκινάει και επιτηρεί το Cowboy:

```elixir
defmodule Example do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.HelloWorldPlug, [], port: 8080)
    ]

    Logger.info("Η εφαρμογή ξεκίνησε")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Αυτό επιτηρεί το Cowboy, και με τη σειρά του επιτηρεί το `HelloWorldPlug` μας.

Στην κλήση της `Plug.Adapters.Cowboy.child_spec/4`, το τρίτο όρισμα θα περαστεί στην `Example.HelloWorldPlug.init/1`.

Δεν έχουμε τελειώσει ακόμα. Ανοίξτε ξανά το `mix.exs`, και βρείτε τη συνάρτηση `applications`.
Πρέπει να προσθέσουμε ρύθμιση για την ίδια μας την εφαρμογή, η οποία θα πρέπει να την κάνει να ξεκινάει αυτόματα.

Ας το αναβαθμίσουμε τώρα να κάνει ακριβώς αυτό:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []}
  ]
end
```

Είμαστε έτοιμοι να δοκιμάσουμε αυτόν τον μινιμαλιστικό, βασισμένο στο plug, web server.
Στη γραμμή εντολών τρέξτε:

```shell
$ mix run --no-halt
```

Όταν ολοκληρωθεί η σύνταξη, και εμφανιστεί το `[info] Η εφαρμογή ξεκίνησε`, ανοίξτε έναν web
browser στη σελίδα `127.0.0.1:8080`. Θα πρέπει να εμφανίζει:

```
Γειά σου κόσμε!
```

## Plug.Router

Για τις περισσότερες εφαρμογές, όπως μια σελίδα web ή ένα REST API, θα θέλετε ένα δρομολογητή να δρομολογεί τις αιτήσεις για διαφορετικές διαδρομές και ρήματα HTTP σε διαφορετικούς χειριστές.
Το `Plug` παρέχει ένα δρομολογητή για αυτό. Όπως θα δούμε, δεν χρειαζόμαστε ένα σκελετό εφαρμογής σαν το Sinatra στην Elixir από τη στιγμή που το έχουμε με το Plug.

Για αρχή ας δημιουργήσουμε το αρχείο `lib/example/router.ex` και ας αντιγράψουμε τα ακόλουθα σε αυτό:

```elixir
defmodule Example.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Καλώς ήρθατε"))
  match(_, do: send_resp(conn, 404, "Ουπς!"))
end
```

Αυτός είναι ο πλέον μινιμαλιστικός δρομολογητής αλλά ο κώδικας θα πρέπει να είναι αρκετά αυτονόητος.
Έχουμε συμπεριλάβει μερικές μακροεντολές μέσω της `use Plug.Router` και μετά ορίσαμε δύο από τα προυπάρχοντα Plugs: τα `:match` και `:dispatch`.
Υπάρχουν δύο ορισμένες διαδρομές, μία για το χειρισμό αιτήσεων GET στην πηγαία διαδρομή (root) και η δεύτερη για το ταίριασμα όλων των άλλων αιτήσεων ώστε να επιστρέψουμε ένα μήνυμα 404.

Πίσω στο `lib/example.ex`, πρέπει να προσθέσουμε τον `Example.Router` μας στο δέντρο επιτήρησης του εξυπηρετητή web.
Αλλάξτε το plug `Example.HelloWorldPlug` με το νέο μας δρομολογητή:

```elixir
def start(_type, _args) do
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 8080)
  ]

  Logger.info("Η εφαρμογή ξεκίνησε")
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Εκκινήστε τον εξυπηρετητή πάλι, αφού πρώτα σταματήσετε τον προηγούμενο αν ακόμα τρέχει (πατήστε `Ctrl+C` δύο φορές).

Τώρα στο web browser, πηγαίνετε στη διαδρομή `127.0.0.1:8080`.
Θα πρέπει να εμφανίσει το `Καλώς ήρθατε`.
Τότε, πηγαίνετε στη τοποθεσία `127.0.0.1:8080/waldo`, ή οποιοδήποτε άλλη διαδρομή.
Θα πρέπει να εμφανίζει `Ουπς!` με μια απάντηση 404.

## Προσθήκη ενός άλλου Plug

Είναι σύνηθες να δημιουργούμε Plugs για τη διακοπή όλων των αιτήσεων ή ενός υποσυνόλου αιτήσεων, για να χειριστεί τη λογική κοινών αιτήσεων.

Για αυτό το παράδειγμα θα δημιουργήσουμε ένα Plug για να επιβεβαιώσουμε αν η αίτηση έχει ένα σετ απαιτούμενων παραμέτρων.
Με την υλοποίηση της επικύρωσης σε ένα Plug μπορούμε να βεβαιωθούμε ότι μόνο έγκυρες αιτήσεις θα καταφέρουν να περάσουν στην εφαρμογή μας.
Θα περιμένουμε το Plug μας να αρχικοποιηθεί με δύο επιλογές: την `:paths` και την `:fields`.
Αυτές θα αναπαριστούν τις διαδρομές που εφαρμόζουμε τη λογική μας και ποιά πεδία να απαιτήσουμε.

_Σημείωση_: Τα Plugs εφαρμόζονται σε όλες τις αιτήσεις, γι'αυτό και θα φιλτράρουμε τις αιτήσεις και θα εφαρμόσουμε τη λογική μας μόνο σε ένα υποσύνολό τους.
Για να αγνοήσουμε μια αίτηση απλά θα μεταβιβάσουμε τη σύνδεση.

Θα ξεκινήσουμε υλοποιώντας το Plug μας και μετά θα συζητήσουμε πως λειτουργεί.
Θα το δημιουργήσουμε στο `lib/plug/verify_request.ex`:

```elixir
defmodule Example.Plug.VerifyRequest do
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
    verified =
      body_params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(IncompleteRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
```

Το πρώτο πράγμα που πρέπει να σημειώσουμε είναι ότι ορίσαμε μια νέα εξαίρεση, την `IncompleteRequestError` και ότι μια από τις επιλογές της είναι η `:plug_status`.
Όταν είναι διαθέσιμη, αυτή η επιλογή χρησιμοποιείται από το Plug για να ορίσει τον κωδικό κατάστασης HTTP στην περίπτωση μιας εξαίρεσης.

Το δεύτερο μέρος του Plug μας είναι η συνάρτηση `call/2`.
Εδώ είναι που αποφασίζουμε αν θα εφαρμόσουμε ή όχι την λογική επικύρωσης.
Μόνο όταν η διαδρομή της αίτησης περιλαμβάνεται στην επιλογή μας `:paths`, τότε θα καλέσουμε την `verify_request!/2`.

Το τελευταίο μέρος του plug μας είναι η ιδιωτική συνάρτηση `verify_request!/2` η οποία επικυρώνει αν τα απαιτούμενα `:fields` είναι όλα παρόντα.
Σε περίπτωση που κάποια λείπουν, σηκώνουμε το σφάλμα `IncompleteRequestError`.

Ορίσαμε το Plug μας να επικυρώνει ότι όλες οι αιτήσεις στη διαδρομή `/upload` συμπεριλαμβάνει τα `"content"` και `"mimetype"`.
Μόνο τότε θα εκτελεστεί ο κώδικας της διαδρομής.

Στη συνέχεια, πρέπει να ενημερώσουμε το δρομολογητή για το νέο Plug.
Επεξεργαστείτε το `lib/example/router.ex` και κάντε τις κάτωθι αλλαγές:

```elixir
defmodule Example.Router do
  use Plug.Router

  alias Example.Plug.VerifyRequest

  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])

  plug(
    VerifyRequest,
    fields: ["content", "mimetype"],
    paths: ["/upload"]
  )

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  post("/upload", do: send_resp(conn, 201, "Uploaded"))
  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

## Κάνοντας τη θύρα HTTP παραμετροποιήσημη

Όταν ορίσαμε την ενότητα `Example` και την εφαρμογή, η θύρα HTTP γράφτηκε απευθείας στον κώδικά μας μέσα στην ενότητα.
Θεωρείται καλή πρακτική το να κάνουμε τη θύρα παραμετροποιήσημη αποθηκεύοντάς την σε ένα αρχείο παραμετροποίησης.

Ας ξεκινήσουμε αλλάζοντας το κομμάτι `application` του `mix.exs` ώστε να πούμε στην Elixir για την εφαρμογή μας και να ορίσουμε μια μεταβλητή περιβάλλοντος εφαρμογής.
Έχοντας κάνει αυτές τις αλλαγές, ο κώδικάς μας θα πρέπει να δείχνει ως εξής:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {Example, []},
    env: [cowboy_port: 8080]
  ]
end
```

Η εφαρμογή μας παραμετροποιέιται με τη γραμμή `mod: {Example, []}`.
Παρατηρήστε ότι επίσης ξεκινάμε την εφαρμογή `logger`.

Στη συνέχεια πρέπει να αλλάξουμε το `lib/example.ex` ώστε να διαβάζει την τιμή ρύθμισης της θύρας, και να την περάσουμε στο Cowboy.

```elixir
defmodule Example do
  use Application

  def start(_type, _args) do
    port = Application.get_env(:example, :cowboy_port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: port)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Η τρίτη παράμετρος της `Application.get_env` είναι η προκαθορισμένη τιμή, για όταν η οδηγία ρύθμισης δεν έχει οριστεί.

> (Προεραιτικά) προσθέστε την `:cowboy_port` στο `config/config.exs`

```elixir
use Mix.Config

config :example, cowboy_port: 8080
```

Τώρα για να τρέξουμε την εφαρμογή μας μπορούμε να χρησιμοποιήσουμε:

```shell
$ mix run --no-halt
```

## Δοκιμή ενός Plug

Η δοκιμή των Plugs είναι αρκετά προφανής χάρη στο `Plug.Test`.
Περιλαμβάνει έναν αριθμό βοηθητικών συναρτήσεων για να κάνει εύκολες τις δοκιμές.

γράψτε το ακόλουθο τέστ στο `test/example/router_test.exs`:

```elixir
defmodule Example.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Example.Router

  @content "<html><body>Γειά!</body></html>"
  @mimetype "text/html"

  @opts Router.init([])

  test "returns welcome" do
    conn =
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns uploaded" do
    conn =
      conn(:post, "/upload", "content=#{@content}&mimetype=#{@mimetype}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 201
  end

  test "returns 404" do
    conn =
      conn(:get, "/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
```

Τρέξτε το με αυτή την εντολή:

```shell
$ mix test test/example/router_test.exs
```

## Διαθέσιμα Plugs

Υπάρχει ένας αριθμός από Plugs διαθέσιμα από την αρχή.
Η πλήρης λίστα μπορεί να βρεθεί στα έγγραφα Plug [εδώ](https://github.com/elixir-lang/plug#available-plugs).
