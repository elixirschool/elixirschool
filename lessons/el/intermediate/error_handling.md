%{
  version: "1.1.0",
  title: "Διαχείριση Σφαλμάτων",
  excerpt: """
  Παρόλο που είναι πιο συνηθισμένη η επιστροφή της τούπλας `{:error, reason}`, η Elixir υποστηρίζει εξαιρέσεις και σε αυτό το μάθημα θα δούμε πως να χειριζόμαστε σφάλματα και τους διαφορετικούς μηχανισμούς που μας είναι διαθέσιμοι.
  
  Γενικά η σύμβαση στην Elixir είναι να δημιουργείτε μια συνάρτηση (`example/1`) η οποία επιστρέφει `{:ok, result}` και `{:error, reason}` και μια ξεχωριστή συνάρτηση (`example/1`) που επιστρέφει το "σκέτο" `result` ή σηκώνει ένα σφάλμα.
  
  Αυτό το μάθημα θα εστιάσει στην αλληλεπίδραση με την τελευταία
  """
}
---

## Γενικές συμβάσεις

Η κοινότητα της Elixir έχει κάνει κάποιες συβάσεις σχετικά με τα επιστρεφόμενα σφάλματα:

* Για σφάλματα που αφορούν στην κανονική λειτουργία μιας συνάρτησης (π.χ. κάποιος χρήστης εισήγαγε λάθος τύπο ημερομηνίας), η συνάρτηση επιστρέφει '{:ok, result}' και '{:error, reason}' αντίστοιχα.
* Για σφάλματα που δεν αφορούν στην κανονική λειτουργία (π.χ. την δυνατότητα επεξεργασίας δεδομένων ρυθμήσεων) θα πρέπει να υπάρχει και μία εξαίρεση.

Σε γενικές γραμμές, η διαχείριση των σφαλμάτων γίνεται με [Αντιπαραβολές Προτύπων](/el/lessons/basics/pattern_matching), αλλά σε αυτό το μάθημα, θα επικεντρωθούμε στο δεύτερο σκέλος των Γενικών συμβάσεων - τις εξαιρέσεις.

Συχνά σε public APIs, μπορεί να συναντήσουμε μία παραλαγή σε μια ήδη υπάρχουσα συνάρτηση που περιέχει ένα ! (example!/1), η οποία επιστρέφει το αποτέλεσμα ή μας ενημερώνει για κάποιο σφάλμα.

## Διαχείριση Σφαλμάτων

Πριν μπορέσουμε να διαχειριστούμε τα σφάλματα χρειάζεται να τα δημιουργήσουμε και ο πιο απλός τρόπος να το κάνουμε είναι με την `raise/1`:

```elixir
iex> raise "Oh no!"
** (RuntimeError) Oh no!
```

Αν θέλουμε να ορίσουμε τον τύπο και το μήνυμα, χρειάζεται η χρήση της `raise/2`:

```elixir
iex> raise ArgumentError, message: "the argument value is invalid"
** (ArgumentError) the argument value is invalid
```

Όταν ξέρουμε ότι ένα σφάλμα μπορεί να προκύψει, θα το χειριστούμε με τη χρήση των `try/rescue` και την αντιπαραβολή προτύπων:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> end
An error occured: Oh no!
:ok
```

Είναι δυνατό να αντιπαραβάλουμε πολλαπλά σφάλματα σε μια και μοναδική rescue:

```elixir
try do
  opts
  |> Keyword.fetch!(:source_file)
  |> File.read!()
rescue
  e in KeyError -> IO.puts("missing :source_file")
  e in File.Error -> IO.puts("unable to read source file")
end
```

## After

Κάποιες φορές μπορεί να είναι απαραίτητο να γίνουν κάποιες ενέργειες μετά τις `try/rescue`, άσχετα με το σφάλμα.
Για αυτό έχουμε την `try/after`.
Αν είστε εξοικειομένοι με την Ruby, αυτή είναι όμοια με την `begin/rescue/ensure` ή την `try/catch/finally` στη Java:

```elixir
iex> try do
...>   raise "Oh no!"
...> rescue
...>   e in RuntimeError -> IO.puts("An error occurred: " <> e.message)
...> after
...>   IO.puts "The end!"
...> end
An error occurred: Oh no!
The end!
:ok
```

Είναι πολύ συχνή η χρήση της με αρχεία η συνδέσεις που πρέπει να κλείσουν:

```elixir
{:ok, file} = File.open("example.json")

try do
  # Do hazardous work
after
  File.close(file)
end
```

## Νέα Σφάλματα

Παρόλο που η Elixir περιλαμβάνει έναν αριθμό προκαθορισμένων τύπων λαθών όπως το `RuntimeError`, διατηρούμε τη δυνατότητα να δημιουργήσουμε τα δικά μας αν χρειαζόμαστε κάτι συγκεκριμμένο.
Η δημιουργία ενός νέου σφάλματος είναι έυκολη με την χρήση της μακροεντολής `defexception/1` η οποία βολικά δέχεται την επιλογή `:message` σαν το προκαθορισμένο μήνυμα σφαλμάτων:

```elixir
defmodule ExampleError do
  defexception message: "an example error has occurred"
end
```

Ας δοκιμάσουμε το νέο μας σφάλμα:

```elixir
iex> try do
...>   raise ExampleError
...> rescue
...>   e in ExampleError -> e
...> end
%ExampleError{message: "an example error has occurred"}
```

## Ρίψεις

Ένας άλλος μηχανισμός για την εργασία με σφάλματα στην Elixir είναι οι `throw` και `catch`.
Στην πράξη, αυτές προκύπτουν πολύ σπάνια σε νεότερο κώδικα Elixir αλλά είναι σημαντικό να τις ξέρουμε και να τις κατανοούμε πάραυτα.

Η συνάρτηση `throw/1` δίνει τη δυνατότητα να βγούμε από την εκτέλεση με μια συγκεκριμμένη τιμή την οποία μπορούμε να πίασουμε (`catch`) και χρησιμοποιήσουμε:

```elixir
iex> try do
...>   for x <- 0..10 do
...>     if x == 5, do: throw(x)
...>     IO.puts(x)
...>   end
...> catch
...>   x -> "Caught: #{x}"
...> end
0
1
2
3
4
"Caught: 5"
```

Όπως αναφέρθηκε, οι `throw/catch` είναι αρκετά σπάνιες και τυπικά υπάρχουν σαν προσωρινές λύσεις όταν βιβλιοθήκες αποτυγχάνουν να παρέχουν επαρκή API.

## Έξοδος

Ο τελευταίος μηχανισμός που μας παρέχει η Elixir είναι η `exit`.  Τα σήματα εξόδου προκύπτουν όταν μια διεργασία πεθαίνει και είναι σημαντικό μέρος της ανοχής σφαλμάτων της Elixir.

Για να βγούμε με σαφήνεια χρησιμοποιούμε την `exit/1`:

```elixir
iex> spawn_link fn -> exit("oh no") end
** (EXIT from #PID<0.101.0>) evaluator process exited with reason: "oh no"
```

Παρόλο που είναι πιθανόν να πιάσουμε την έξοδο με τις `try/catch`, αυτό είναι _εξαιρετικά_ σπάνιο.
Σχεδόν σε όλες τις περιπτώσεις είναι επωφελές να αφήσουμε τον διαχειριστή να χειριστεί την έξοδο της διεργασίας:

```elixir
iex> try do
...>   exit "Oh no!"
...> catch
...>   :exit, _ -> "exit blocked"
...> end
"exit blocked"
```
