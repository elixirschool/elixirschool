---
version: 0.9.0
layout: page
title: Δομές Ελέγχου
category: basics
order: 5
lang: gr
---

Σε αυτό το μάθημα θα δούμε τις δομές ελέγχου που μας παρέχει η Elixir.

{% include toc.html %}

## `if` και `unless`

Λογικά έχετε συναντήσει την `if/2` ξάνα, και αν έχετε χρησιμοποιήσει την Ruby είστε εξοικειομένοι με την `unless/2`.  Στην Elixir δουλεύουν σχεδόν το ίδιο, αλλά είναι ορισμένες ως μακροεντολές, όχι σαν δομές της γλώσσας.  Μπορείτε να βρείτε την υλοποίησή τους στην [ενότητα Kernel](http://elixir-lang.org/docs/stable/elixir/#!Kernel.html).

Θα πρέπει να σημειώθεί ότι στην Elixir, οι μόνες τιμές που περνάνε ως false είναι η `nil` και η δυαδική `false`.

```elixir
iex> if String.valid?("Hello") do
...>   "Έγκυρο αλφαριθμητικό."
...> else
...>   "Άκυρο Αλφαριθμητικό."
...> end
"Έγκυρο αλφαριθμητικό."

iex> if "μια αλφαριθμητική τιμή" do
...>   "Αληθής"
...> end
"Αληθής"
```

Η `unless/2` είναι παρόμοια με την `if/2`, εκτός του ότι λειτουργεί όταν είναι αρνητικός ο έλεγχος:

```elixir
iex> unless is_integer("γεια") do
...>   "Δεν είναι ακέραιος"
...> end
"Δεν είναι ακέραιος"
```

## `case`

Αν είναι απαραίτητο να αντιπαραβάλουμε πολλαπλά πρότυπα μπορούμε να χρησιμοποιήσουμε την `case`:

```elixir
iex> case {:ok, "Γειά σου κόσμε!"} do
...>   {:ok, result} -> result
...>   {:error} -> "Ωχ όχι!"
...>   _ -> "Όλα τα υπόλοιπα"
...> end
"Γειά σου κόσμε!"
```

Η μεταβλητή `_` είναι μια σημαντική προσθήκη στις εντολές `case`.  Χωρίς αυτήν, μια αποτυχία να βρεθεί αντιπαραβολή θα σηκώσει ένα σφάλμα:

```elixir
iex> case :even do
...>   :odd -> "Μονός"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Μονός"
...>   _ -> "Όχι Μονός"
...> end
"Όχι Μονός"
```

Μπορείτε να σκέφτεστε την μεταβλητή `_` σαν το `else` το οποίο θα αντιπαραβάλει όλα τα υπόλοιπα.

Εφόσον η `case` βασίζεται στην αντιπαραβολή προτύπων, ισχύουν όλοι οι κανόνες και περιορισμοί.  Αν σκοπεύετε να αντιπαραβάλετε υπάρχουσες μεταβλητές πρέπει να χρησιμοποιήσετε τον τελεστή καρφίτσας `^`:

```elixir
iex> pie = 3.14
 3.14
iex> case "μηλόπιτα" do
...>   ^pie -> "Όχι και τόσο νόστιμη"
...>   pie -> "Βάζω στοίχημα ότι η #{pie} είναι πεντανόστιμη"
...> end
"Βάζω στοίχημα ότι η μηλόπιτα είναι πεντανόστιμη"
```

Ακόμα ένα πολύ καλό χαρακτηριστικό της `case` είναι η υποστήριξή της για ρήτρες προστασίας:

_Αυτό το παράδειγμα προέρχεται κατευθείαν από τον επίσημο οδηγό της Elixir, [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case)._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Ελέγξτε τα επίσημα έγγραφα για τις [Εκφράσεις που επιτρέπονται στις ρήτρες προστασίας](http://elixir-lang.org/getting-started/case-cond-and-if.html#expressions-in-guard-clauses).

## `cond`

Όταν χρειάζεται να αντιπαραβάλουμε συνθήκες αντί για τιμές μπορούμε να στραφούμε στην `cond`.  Αυτή είναι όμοια με τις `else if` και `elsif` από άλλες γλώσσες:

_Αυτό το παράδειγμα προέρχεται κατευθείαν από τον επίσημο οδηγό της Elixir, [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond)._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

Όπως η `case`, η `cond` θα σηκώσει ένα σφάλμα αν δεν υπάρχει αντιπαραβολή.  Για να το ελέγξουμε αυτό, μπορούμε να ορίσουμε ένα σετ συνθηκών σε `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

Η ειδική μορφή της `with` είναι χρήσιμη όταν θέλετε να χρησιμοποιήσετε μια ένθετη εντολή `case` ή σε περιπτώσεις που δεν μπορούν να σωληνωθούν μαζί.  H έκφραση `with` συντίθεται με την λέξη κλειδί, τις γεννήτριες, και τέλος μια έκφραση.

Θα συζητήσουμε τις γεννήτριες περισσότερο στο μάθημα Κατανόηση Λιστών αλλά για τώρα πρέπει μόνο να ξέρουμε ότι χρησιμοποιούν αντιπαραβολή προτύπων για να συγκρίνουν την δεξιά μεριά του `<-` με την αριστερή.

Θα ξεκινήσουμε με ένα απλό παράδειγμα της `with` και τότε θα δούμε κάτι περισσότερο:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
%{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Στην περίπτωση που μια έκφραση αποτυγχάνει να αντιπαραβληθεί, η τιμή που δεν αντιπαραβάλεται επιστρέφεται:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

Τώρα ας δούμε ένα μεγαλύτερο παράδειγμα χωρίς την `with` και τότε θα δούμε πως θα την ανακατασκευάσουμε:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(resource, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)
      error -> error
    end
  error -> error
end
```

Όταν εισάγουμε την `with`, καταλήγουμε με κώδικα που είναι έυκολο να καταλάβουμε και έχει λιγότερες γραμμές:

```elixir
with
  {:ok, user} <- Repo.insert(changeset),
  {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token),
  do: important_stuff(jwt, full_claims)
```
