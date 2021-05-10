%{
  version: "1.0.2",
  title: "Εκτελέσιμα",
  excerpt: """
  Για να φτιάξουμε εκτελέσιμα στην Elixir θα χρησιμοποιήσουμε την escript.  Η Escript παράγει ένα εκτελέσιμο το οποίο μπορεί να τρέξει σε οποιοδήποτε σύστημα έχει εγκατασταθεί η Erlang.
  """
}
---

## Αρχή

Για να δημιουργήσετε ένα εκτελέσιμο με την escript υπάρχουν ελάχιστα πράγματα που πρέπει να κάνουμε: να υλοποιήσουμε μια συνάρτηση `main/1` και να αναβαθμίσουμε το Mixfile μας.

Θα ξεκινήσουμε με τη δημιουργία μιας ενότητας που θα παίξει το ρόλο σημείου εισόδου στο εκτελέσιμό μας.  Εκεί θα υλοποιήσουμε την `main/1`:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    # Κάντε τα δικά σας
  end
end
```

Στη συνέχεια θα χρειαστεί να αναβαθμίσουμε το Mixfile μας για να προσθέσουμε την επιλογή `:escript` για το project μας μαζί με τον ορισμό του `:main_module` μας:

```elixir
defmodule ExampleApp.Mixfile do
  def project do
    [app: :example_app, version: "0.0.1", escript: escript()]
  end

  defp escript do
    [main_module: ExampleApp.CLI]
  end
end
```

## Επεξεργασία Ορισμάτων

Με την εφαρμογή μας εγκατεστημένη μπορούμε να προχωρήσουμε στην επεξεργασία των ορισμάτων της γραμμής εντολών.  Για να το κάνουμε αυτό θα χρησιμοποιήσουμε την συνάρτηση `OptionParser.parse/2` της Elixir με την επιλογή `:switches` για την ένδειξη ότι η σημαία μας είναι δυαδική:

```elixir
defmodule ExampleApp.CLI do
  def main(args \\ []) do
    args
    |> parse_args()
    |> response()
    |> IO.puts()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

    {opts, List.to_string(word)}
  end

  defp response({opts, word}) do
    if opts[:upcase], do: String.upcase(word), else: word
  end
end
```

## Χτίσιμο

Όταν τελειώσουμε με την ρύθμιση της εφαρμογής μας για τη χρήση της escript, το χτίσιμο του εκτελέσιμού μας είναι πανεύκολο με το Mix:

```bash
$ mix escript.build
```

Για να το δοκιμάσουμε:

```bash
$ ./example_app --upcase Γεια
ΓΕΙΑ

$ ./example_app Γεια
Γεια
```

Αυτό ήταν.  Χτίσαμε το πρώτο μας εκτελέσιμο στην Elixir χρησιμοποιώντας την escript.
