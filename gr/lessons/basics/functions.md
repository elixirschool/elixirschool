---
version: 1.2.0
title: Συναρτήσεις
---

Στην Elixir όπως και σε άλλες συναρτησιακές γλώσσες, οι συναρτήσεις είναι απόλυτα υποστηριζόμενες.
Θα μάθουμε για τους τύπους των συναρτήσεων στην Elixir, τι τις κάνει διαφορετικές και πως να τις χρησιμοποιούμε.

{% include toc.html %}

## Ανώνυμες Συναρτήσεις

Όπως εννοεί το όνομα, μια ανώνυμη συνάρτηση δεν έχει όνομα.
Όπως είδαμε στο μάθημα `Enum`, αυτές συνήθως στέλνονται σε άλλες συναρτήσεις.
Για να ορίσουμε μια ανώνυμη συνάρτηση στην Elixir χρειαζόμαστε τις λέξεις κλειδιά `fn` και `end`.
Μέσα σε αυτές μπορούμε να ορίσουμε οποιοδήποτε αριθμό παραμέτρων και σωμάτων συναρτήσεων χωρισμένα με το `->`.

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

Η Elixir χρησιμοποιεί αντιπαραβολή προτύπων για να αναγνωρίσει το πρώτο σετ παραμέτρων που ταιριάζουν και καλεί το αντίστοιχο σώμα:

```elixir
iex> handle_result = fn
...>   {:ok, result} -> IO.puts "Handling result..."
...>   {:ok, _} -> IO.puts "This would be never run as previous will be matched beforehand."
...>   {:error} -> IO.puts "An error has occurred!"
...> end

iex> some_result = 1
1
iex> handle_result.({:ok, some_result})
Handling result...
:ok
iex> handle_result.({:error})
An error has occurred!
```

## Ονομασμένες Συναρτήσεις

Μπορούμε να ορίσουμε συναρτήσεις με ονόματα ώστε να μπορούμε αργότερα με ευκολία να αναφερθούμε σε αυτές.
Οι ονομασμένες συναρτήσεις ορίζονται μέσα σε μια ενότητα (module) χρησιμοποιώντας την λέξη κλειδί `def`.
Θα μάθουμε περισσότερα για τις ενότητες στα επόμενα μαθήματα, για την ώρα θα εστιάσουμε μόνο στις ονομασμένες συναρτήσεις.

Οι συναρτήσεις που ορίζονται μέσα σε μια ενότητα είναι διαθέσιμες για χρήση σε άλλες ενότητες.
Αυτή είναι μια εξαιρετικά σημαντική δομή στην Elixir:

```elixir
defmodule Greeter do
  def hello(name) do
    "Hello, " <> name
  end
end

iex> Greeter.hello("Sean")
"Hello, Sean"
```

Αν το σώμα της συνάρτησης αποτελείται από μόνο μία γραμμή, μπορούμε να το συντομεύσουμε περαιτέρω με την `do:`:

```elixir
defmodule Greeter do
  def hello(name), do: "Hello, " <> name
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

Αναφέραμε νωρίτερα ότι οι συναρτήσεις ονομάζονται από το συνδυασμό του δωσμένου ονόματος και την τάξη (αριθμός των ορισμάτων).
Αυτό σημαίνει ότι μπορείτε να κάνετε πράγματα όπως αυτό:

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

Στο παραπάνω παράδειγμα έχουμε παραθέσει τα ονόματα συναρτήσεων σε σχόλια.
Η πρώτη υλοποίηση δεν δέχεται ορίσματα, έτσι είναι γνωστή σαν `hello/0`. Η δεύτερη δέχεται ένα όρισμα, έτσι είναι γνωστή σαν `hello/1`, και ούτω καθεξής.
Αντίθετα με την υπερφόρτωση συναρτήσεων σε κάποιες άλλες γλώσσες, αυτές τις σκεφτόμαστε σαν _διαφορετικές_ συναρτήσεις μεταξύ τους.
(Η αντιπαραβολή προτύπων, που αναφέραμε λίγο πριν, εφαρμόζεται μόνο όταν παρέχονται πολλαπλοί ορισμοί για ορισμούς συναρτήσεων με τον _ίδιο_ αριθμό ορισμάτων.)

### Συναρτήσεις και Αντιπαραβολή Προτύπων

Στο παρασκήνιο, οι συναρτήσεις αντιπαραβάλουν τα ορίσματα με τα οποία καλούνται.

Για παράδειγμα αν χρειαζόμασταν μια συνάρτηση που θα δεχόταν ένα χάρτη αλλά ενδιαφερόμασταν μόνο σε ένα συγκεκριμένο κλειδί του χάρτη.
Μπορούμε να αντιπαραβάλουμε το όρισμα στην παρουσία αυτού του κλειδιού με αυτό τον τρόπο:

```elixir
defmodule Greeter1 do
  def hello(%{name: person_name}) do
    IO.puts "Hello, " <> person_name
  end
end
```

Τώρα ας πούμε πως έχουμε ένα χάρτη που περιγράφει ένα άτομο που λέγεται Fred:

```elixir
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

Αυτά είναι τα αποτελέσματα που θα πάρουμε αν καλέσουμε την `Greeter1.hello/1` με τον χάρτη `fred`:

```elixir
# call with entire map
...> Greeter1.hello(fred)
"Hello, Fred"
```

Τι συμβαίνει όταν καλέσουμε τη συνάρτηση με ένα χάρτη που _δεν_ περιέχει το κλειδί `:name`;

```elixir
# call without the key we need returns an error
...> Greeter1.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter1.hello/1

    The following arguments were given to Greeter1.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:12: Greeter1.hello/1

```

Ο λόγος για αυτή τη συμπεριφορά είναι ότι η Elixir αντιπαραβάλει τα ορίσματα με τα οποία η συνάρτηση καλείται απέναντι στην τάξη με την οποία η συνάρτηση ορίζεται.

Ας σκεφτούμε πως δείχνουν τα δεδομένα όταν φτάνουν στην `Greeter1.hello/1`:

```Elixir
# incoming map
iex> fred = %{
...> name: "Fred",
...> age: "95",
...> favorite_color: "Taupe"
...> }
```

Η `Greeter1.hello/1` περιμένει ένα όρισμα σαν αυτό:

```elixir
%{name: person_name}
```

Στην `Greeter1.hello/1`, ο χάρτης που περνάμε (`fred`) αντιπαραβάλεται με το όρισμά μας (`%{name: person_name}`):

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Βρίσκει ότι υπάρχει κλειδί που αντιστοιχεί στο `name` στον εισερχόμενο χάρτη.
Έχουμε ταίριασμα! Και σαν αποτέλεσμα απο αυτό το επιτυχές ταίριασμα, η τιμή του κλειδιού `:name` στο χάρτη στα δεξιά (π.χ. ο χάρτης `fred`) ορίζεται στη μεταβλητή στα αριστερά (`person_name`).

Τώρα, τι θα γινόταν αν θέλαμε να ορίσουμε το όνομα του Fred στην μεταβλητή `person_name` αλλά επίσης θέλαμε να διατηρήσουμε τον πλήρη χάρτη του ατόμου; Ας πούμε ότι θέλουμε να τρέξουμε την `IO.inspect(fred)` αφού τον χαιρετίσουμε.
Σε αυτό το σημείο, επειδή αντιπαραβάλαμε μόνο το κλειδί `:name` του χάρτη, και έτσι καταχωρήσαμε μόνο την τιμή αυτού του κλειδιού σε μεταβλητή, η συνάρτηση δεν έχει γνώση από το υπόλοιπο του Fred.

Για να τον διατηρήσουμε, πρέπει να καταχωρήσουμε τον πλήρη χάρτη στην δική του μεταβλητή ώστε να μπορέσουμε να τον χρησιμοποιήσουμε.

Ας ξεκινήσουμε μια νέα συνάρτηση:

```elixir
defmodule Greeter2 do
  def hello(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Θυμηθείτε ότι η Elixir θα αντιπαραβάλει το όρισμα καθώς έρχεται στη συνάρτηση.
Έτσι σε αυτή την περίπτωση, κάθε πλευρά θα αντιπαραβληθεί απέναντι στο εισερχόμενο όρισμα και θα οριστεί σε οτιδήποτε ταιριάζει.
Ας πάρουμε τη δεξιά πλευρά πρώτα:

```elixir
person = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Τώρα, η μεταβλητή `person` έχει οριστεί στον πλήρη χάρτη fred.
Πάμε στην επόμενη αντιπαραβολή:

```elixir
%{name: person_name} = %{name: "Fred", age: "95", favorite_color: "Taupe"}
```

Τώρα, αυτή είναι ίδια με την αρχική `Greeter1` συνάρτηση όπου ταιριάζουμε το χάρτη και κρατάμε μόνο το όνομα του Fred.
Αυτό που πετυχαίνουμε είναι δύο μεταβλητές που μπορούμε να χρησιμοποιήσουμε αντί για μία:

1. `person`, που αντιστοιχεί σε `%{name: "Fred", age: "95", favorite_color: "Taupe"}`
2. `person_name`, που αντιστοιχεί σε `"Fred"`

Έτσι όταν τώρα καλέσουμε την `Greeter2.hello/1`, μπορούμε να χρησιμοποιήσουμε όλες τις πληροφορίες του Fred:

```elixir
# call with entire person
...> Greeter2.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
# call with only the name key
...> Greeter2.hello(%{name: "Fred"})
"Hello, Fred"
%{name: "Fred"}
# call without the name key
...> Greeter2.hello(%{age: "95", favorite_color: "Taupe"})
** (FunctionClauseError) no function clause matching in Greeter2.hello/1

    The following arguments were given to Greeter2.hello/1:

        # 1
        %{age: "95", favorite_color: "Taupe"}

    iex:15: Greeter2.hello/1
```

Έτσι είδαμε ότι η Elixir αντιπαραβάλει σε πολλαπλά επίπεδα επειδή κάθε όρισμα αντιπαραβάλεται με τα εισερχόμενα δεδομένα ανεξάρτητα, αφήνοντάς μας με τις μεταβλητές που μπορούμε στη συνέχεια να χρησιμοποιήσουμε μέσα στη συνάρτησή μας.

Αν αλλάξουμε τη σειρά των `%{name: person_name}` και `person` στη λίστα, θα πάρουμε το ίδιο αποτέλεσμα επειδή κάθε ένα αντιπαραβάλεται με το Fred ξεχωριστά.

Αλλάζοντας τη σειρά μεταβλητής και χάρτη:

```elixir
defmodule Greeter3 do
  def hello(person = %{name: person_name}) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
```

Και την καλούμε με τα ίδια δεδομένα που χρησιμοποιήσαμε στην `Greeter2.hello/1`:

```elixir
# call with same old Fred
...> Greeter3.hello(fred)
"Hello, Fred"
%{age: "95", favorite_color: "Taupe", name: "Fred"}
```

Θυμηθείτε ότι παρόλο που το `%{name: person_name} = person` δείχνει σαν να γίνεται αντιπαραβολή του `%{name: person_name}` με την μεταβλητή `person`, στην πραγματικότητα _κάθε_ μια από αυτές αντιπαραβάλονται στo εισερχόμενo όρισμα.

**Σύνοψη:** Οι συναρτήσεις αντιπαραβάλουν τα εισερχόμενα δεδομένα σε κάθε ένα από τα ορίσματα ανεξάρτητα.
Μπορούμε να το χρησιμοποιήσουμε αυτό για να ορίζουμε τιμές σε ξεχωριστές μεταβλητές μέσα στη συνάρτηση.

### Ιδιωτικές Συναρτήσεις

Όταν δεν θέλουμε άλλες ενότητες να έχουν πρόσβαση σε μια συγκεκριμένη συνάρτηση, μπορούμε να κάνουμε την συνάρτηση ιδιωτική.
Οι ιδιωτικές συναρτήσεις μπορούν μόνο να κληθούν μέσα από την ίδια τους την ενότητα.
Στην Elixir τις ορίζουμε με την `defp`:

```elixir
defmodule Greeter do
  def hello(name), do: phrase() <> name
  defp phrase, do: "Hello, "
end

iex> Greeter.hello("Sean")
"Hello, Sean"

iex> Greeter.phrase
** (UndefinedFunctionError) function Greeter.phrase/0 is undefined or private
    Greeter.phrase()
```

### Προστάτες

Πρόσφατα αναφερθήκαμε στους προστάτες στο μάθημα [Δομές Ελέγχου](../control-structures), τώρα θα δούμε πως μπορούμε να τους εφαρμόσουμε σε ονομασμένες συναρτήσεις.
Όταν η Elixir έχει αντιπαραβάλει μια συνάρτηση, όλοι οι υπάρχοντες προστάτες θα ελεχθούν.

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

  defp phrase, do: "Hello, "
end

iex> Greeter.hello ["Sean", "Steve"]
"Hello, Sean, Steve"
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

Όταν συνδυάσουμε το παράδειγμα προστάτη με τις προκαθορισμένες παραμέτρους, συναντάμε ένα πρόβλημα.
Ας δούμε πως θα έμοιαζε κάτι τέτοιο:

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

** (CompileError) iex:31: definitions with multiple clauses and default values require a header.
Instead of:

    def foo(:first_clause, b \\ :default) do ... end
    def foo(:second_clause, b) do ... end

one should write:

    def foo(a, b \\ :default)
    def foo(:first_clause, b) do ... end
    def foo(:second_clause, b) do ... end

def hello/2 has multiple clauses and defines defaults in one or more clauses
    iex:31: (module)
```

Στην Elixir δεν αρέσουν οι προκαθορισμένες παράμετροι σε πολλαπλά αντιπαραβαλόμενες συναρτήσεις, μπορεί να δημιουργήσει σύγχυση.
Για να το χειριστούμε προσθέτουμε μια κεφαλή συνάρτησης με τις προκαθορισμένες παράμετρους μας:

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
