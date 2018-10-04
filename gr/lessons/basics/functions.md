---
version: 1.0.1
title: Συναρτήσεις
---

Στην Elixir όπως και σε άλλες συναρτησιακές γλώσσες, οι συναρτήσεις είναι απόλυτα υποστηριζόμενες.  Θα μάθουμε για τους τύπους των συναρτήσεων στην Elixir, τι τις κάνει διαφορετικές και πως να τις χρησιμοποιούμε.

{% include toc.html %}

## Ανώνυμες Συναρτήσεις

Όπως εννοεί το όνομα, μια ανώνυμη συνάρτηση δεν έχει όνομα.  Όπως είδαμε στο μάθημα `Enum`, αυτές συνήθως στέλνονται σε άλλες συναρτήσεις.  Για να ορίσουμε μια ανώνυμη συνάρτηση στην Elixir χρειαζόμαστε τις λέξεις κλειδί `fn` και `end`.  Μέσα σε αυτές μπορούμε να ορίσουμε οποιοδήποτε αριθμό παραμέτρων και σωμάτων συναρτήσεων χωρισμένα με το `->`.

Ας δούμε ένα βασικό παράδειγμα:

```elixir
iex> sum = fn (a, b) -> a + b end
iex> sum.(2, 3)
5
```

### Η Συντομογραφία &

Η χρήση ανώνυμων συναρτήσεων είναι τόσο κοινή πρακτική στην Elixir που υπάρχει συντομογραφία για αυτές:

```elixir
iex> sum = &(&1 + &2)
iex> sum.(2, 3)
5
```

Όπως πιθανότατα θα μαντέψατε ήδη, στην σύντομη έκδοση οι παράμετροι μας είναι διαθέσιμοι σαν `&1`, `&2`, `&3` και ούτω καθεξής.

## Αντιπαραβολή Προτύπων

Η αντιπαραβολή προτύπων δεν περιορίζεται μόνο στις μεταβλητές στην Elixir, μπορεί να εφαρμοστεί στις υπογραφές συναρτήσεων όπως θα δούμε σε αυτή την ενότητα.

Η Elixir χρησιμοποιεί αντιπαραβολή προτύπων για να αναγνωρίσει το πρώτο σετ παραμέτων που ταιριάζουν και καλεί το αντίστοιχο σώμα:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Διαχείριση αποτελέσματος..."
...>   {:error} -> IO.puts "Προέκυψε ένα σφάλμα!"
...> end

iex> some_result = 1
iex> handle_result.({:ok, some_result})
Διαχείριση αποτελέσματος...

iex> handle_result.({:error})
Προέκυψε ένα σφάλμα!
```

## Ονομασμένες Συναρτήσεις

Μπορούμε να ορίσουμε συναρτήσεις με ονόματα ώστε να μπορούμε αργότερα με ευκολία να αναφερθούμε σε αυτές.  Οι ονομασμένες συναρτήσεις ορίζονται μέσα σε μια ενότητα (module) χρησιμοποιώντας την λέξη κλειδί `def`.  Θα μάθουμε περισσότερα για τις ενότητες στα επόμενα μαθήματα, για την ώρα θα εστιάσουμε μόνο στις ονομασμένες συναρτήσεις.

Οι συναρτήσεις που ορίζονται μέσα σε μια ενότητα είναι διαθέσιμες για χρήση σε άλλες ενότητες.  Αυτή είναι μια εξαιρετικά σημαντική δομή στην Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Γειά σου, " <> name
  end
end

iex> Greeter.hello("Sean")
"Γειά σου, Sean"
```

Αν το σώμα της συνάρτησης αποτελείται από μόνο μία γραμμή, μπορούμε να το συντομεύσουμε περαιτέρω με την `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Γειά σου, " <> name
end
```

Οπλισμένοι με τις γνώσεις μας στην αντιπαραβολή προτύπων, ας δούμε το θέμα της αναδρομής χρησιμοποιώντας ονομασμένες συναρτήσεις:

```elixir
defmodule Length do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end

iex> Length.of []
0
iex> Length.of [1, 2, 3]
3
```

### Ονομασία Συναρτήσεων και Τάξη

Αναφέραμε νωρίτερα ότι οι συναρτήσεις ονομάζονται από το συνδυασμό του δωσμένου ονόματος και την τάξη (αριθμός των ορισμάτων). Αυτό σημαίνει ότι μπορείτε να κάνετε πράγματα όπως αυτό:

```elixir
defmodule Greeter2 do
  def hello(), do: "Hello, anonymous person!"   # hello/0
  def hello(name), do: "Hello, " <> name        # hello/1
  def hello(name1, name2), do: "Hello, #{name1} and #{name2}"
                                                # hello/2
end

iex> Greeter2.hello()
"Hello, anonymous person!"
iex> Greeter2.hello("Fred")
"Hello, Fred"
iex> Greeter2.hello("Fred", "Jane")
"Hello, Fred and Jane"
```

Στο παραπάνω παράδειγμα έχουμε παραθέσει τα ονόματα συναρτήσεων σε σχόλια. Η πρώτη υλοποίηση δεν δέχεται ορίσματα, έτσι είναι γνωστή σαν `hello/0`. Η δεύτερη δέχεται ένα όρισμα, έτσι είναι γνωστή σαν `hello/1`, και ούτω καθεξής. Αντίθετα με την υπερφόρτωση συναρτήσεων σε κάποιες άλλες γλώσσες, αυτές τις σκεφτόμαστε σαν _διαφορετικές_ συναρτήσεις μεταξύ τους. (Η αντιπαραβολή προτύπων, που αναφέραμε λίγο πριν, εφαρμόζεται μόνο όταν παρέχονται πολλαπλοί ορισμοί για ορισμούς συναρτήσεων με τον _ίδιο_ αριθμό ορισμάτων.)

### Ιδιωτικές Συναρτήσεις

Όταν δεν θέλουμε άλλες ενότητες να έχουν πρόσβαση σε μια συγκεκριμένη συνάρτηση, μπορούμε να κάνουμε την συνάρτηση ιδιωτική.  Οι ιδιωτικές συναρτήσεις μπορούν μόνο να κληθούν μέσα από την ίδια τους την ενότητα.  Στην Elixir τις ορίζουμε με την `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase <> name
  defp phrase, do: "Γειά σου, "
end

iex> Greeter.hello("Sean")
"Γειά σου, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Προστάτες

Πρόσφατα αναφερθήκαμε στους προστάτες στο μάθημα [Δομές Ελέγχου](../control-structures), τώρα θα δούμε πως μπορούμε να τους εφαρμόσουμε σε ονομασμένες συναρτήσεις.  Όταν η Elixir έχει αντιπαραβάλει μια συνάρτηση, όλοι οι υπάρχοντες προστάτες θα ελεχθούν.

Στο παράδειγμα που ακολουθεί έχουμε δύο συναρτήσεις με την ίδια υπογραφή, στηριζόμαστε στους προστάτες για να προσδιορίσουμε ποιά θα χρησιμοποιήσουμε βασιζόμενοι στον τύπο των παραμέτρων:

```elixir
defmodule Greeter do
  def hello(names) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello
  end

  def hello(name) when is_binary(name) do
    phrase() <> name
  end

  defp phrase, do: "Γειά, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Γειά, Sean, Steve"
```

### Προκαθορισμένες Παράμετροι

Αν θέλουμε μια προκαθορισμένη τιμή για μια παράμετρο χρησιμοποιούμε το συντακτικό `παράμετρος \\ τιμή`:

```elixir
defmodule Greeter do
  def hello(name, language_code \\ "en") do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("gr"), do: "Γειά σου, "
end

iex> Greeter.hello("Sean", "en")
"Hello, Sean"

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.hello("Sean", "gr")
"Γειά σου, Sean"
```

Όταν συνδυάσουμε το παράδειγμα προστάτη με τις προκαθορισμένες παραμέτρους, συναντάμε ένα πρόβλημα.  Ας δούμε πως θα έμοιαζε κάτι τέτοιο:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en") when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code \\ "en") when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("gr"), do: "Γειά σου, "
end

** (CompileError) iex:31: definitions with multiple clauses and default values require a header. Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Στην Elixir δεν αρέσουν οι προκαθορισμένες παράμετροι σε πολλαπλά αντιπαραβαλόμενες συναρτήσεις, μπορεί να δημιουργήσει σύγχυση.  Για να το χειριστούμε προσθέτουμε μια κεφαλή συνάρτησης με τις προκαθορισμένες παράμετρους μας:

```elixir
defmodule Greeter do
  def hello(names, language_code \\ "en")

  def hello(names, language_code) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(language_code)
  end

  def hello(name, language_code) when is_binary(name) do
    phrase(language_code) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Γειά σου, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"

iex> Greeter.hello ["Sean", "Steve"], "gr"
"Γειά σου, Sean, Steve"
```
