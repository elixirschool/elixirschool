---
version: 1.1.0
title: Τεκμηρίωση
---

Τεκμηρίωση κώδικα Elixir.

{% include toc.html %}

## Σχολιασμός

Το πόσο πολύ και το τι ακριβώς ορίζει την ποιοτική τεκμηρίωση, είναι ένα αμφισβητήσιμο θέμα στον προγραμματιστικό κόσμο.
Πάντως, μπορούμε όλοι να συμφωνήσουμε ότι η τεκμηρίωση είναι σημαντική για εμάς και όσους δουλεύουν στην βάση κώδικά μας.

Η Elixir χειρίζεται την τεκμηρίωση σαν *πελάτη πρώτης κατηγορίας*, παρέχοντας διάφορες λειτουργίες για την πρόσβαση και τη δημιουργία τεκμηρίωσης για τα projects μας.
O πυρήνας της Elixir μας παρέχει πολλές διαφορετικές ιδιότητες για να σχολιάσουμε μια βάση κώδικα.
Ας δούμε 3 τρόπους:

  - `#` - Για τεκμηρίωση στην ίδια γραμμή
  - `@moduledoc` - Για τεκμηρίωση σε επίπεδο ενότητας
  - `@doc` - Για τεκμηρίωση σε επίπεδο συνάρτησης.

### Τεκμηρίωση στην ίδια γραμμή

Πιθανότατα ο πιο απλός τρόπος να σχολιάσουμε τον κώδικά μας με σχόλια στην ίδια γραμμή.
Παρόμοια με την Ruby ή την Python, τα σχόλια της Elixir χαρακτηρίζονται με το σύμβολο `#`, γνωστό και ως *δίεση* ή σαν *pound* και *hash*, ανάλογα με την καταγωγή σας.

Για παράδειγμα το ακόλουθο Script Elixir (greeting.exs):

```elixir
# Outputs 'Hello, chum.' to the console.
IO.puts("Hello, " <> "chum.")
```

Η Elixir, όταν τρέξει το script θα αγνοήσει οτιδήποτε μετά το `#` και μέχρι το τέλος της γραμμής, μεταχειρίζοντας το σαν δεδομένα για πέταμα.
Μπορεί να μην προσθέτει αξία στην εκτέλεση ή στην επίδοση του script, αλλά όταν δεν είναι τόσο εμφανές τι συμβαίνει, ένας προγραμματιστής θα πρέπει να ξέρει διαβάζοντας το σχόλιό σας.
Προσέξτε μην το παρακάνετε με τα σχόλια ίδιας γραμμής! Το να γεμίζετε με σκουπίδια μια βάση κώδικα μπορεί να γίνει εφιάλτης για κάποιους.
Καλύτερα να χρησιμοποιείται με μέτρο.

### Τεκμηρίωση Ενοτήτων

Ο σχολιαστής `@moduledoc` επιτρέπει την τεκμηρίωση σε επίπεδο ενότητας.
Συνήθως βρίσκεται ακριβώς από κάτω από τη δήλωση `defmodule` στην κορυφή του αρχείου.
Το παρακάτω παράδειγμα δείχνει ένα σχόλιο μιας γραμμής μέσα στο σχολιαστή `@moduledoc`.

```elixir
defmodule Greeter do
  @moduledoc """
  Provides a function `hello/1` to greet a human
  """

  def hello(name) do
    "Hello, " <> name
  end
end
```

Εμείς (ή άλλοι) μπορούμε να έχουμε πρόσβαση στην τεκμηρίωση χρησιμοποιώντας τη βοηθητική συνάρτηση `h` μέσα στο IEx.
Μπορούμε να το δούμε και μόνοι μας αν προσθέσουμε το 'Greeter' σε ένα καινούριο αρχείο, 'greeter.ex' και το κάνουμε compile:

```elixir
iex> c("greeter.ex", ".")
[Greeter]

iex> h Greeter

                Greeter

Provides a function hello/1 to greet a human
```

_Σημείωση_ : δεν είναι απαραίτητο να κάνουμε compile τα αρχεία μας χειροκίνητα όπως προηγουμένως αν δουλεύουμε στα πλαίσια ενός mix project. Μπορείτε να χρησιμοποιήσετε την εντολή 'iex -S mix' για να εκκινήσετε την κοσνόλα IEx για το τρέχον project αν δουλεύετε σε ενα mix project.

### Τεκμηρίωση συναρτήσεων

Όπως η Elixir μας δίνει τη δυνατότητα για τεκμηρίωση επιπέδου ενότητας, επίσης δίνει παρόμοιους σχολιαστές για τη τεκμηρίωση συναρτήσεων.
Ο σχολιαστής `@doc` μας επιτρέπει την τεκμηρίωση σε επίπεδο συνάρτησης.
Ο σχολιαστής `@doc` βρίσκεται ακριβώς από πάνω από τη συνάρτηση που σχολιάζει.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Παράμετροι

    - name: String that represents the name of the person.

  ## Παραδείγματα

      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

Αν μπούμε στο IEx ξανά και χρησιμοποιήσουμε την εντολή βοήθειας (`h`) στη συνάρτηση με το όνομα της ενότητας πιο πριν, θα δούμε το ακόλουθο:

```elixir
iex> c("greeter.ex")
[Greeter]

iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

  • name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"

iex>
```

Παρατηρείτε πως μπορείτε να χρησιμοποιήσετε σημάνσεις μέσα στην τεκμηρίωση και το τερματικό θα τις εμφανίσει;  Εκτός από το να είναι πολύ συναρπαστικές και μια καινοτομική προσθήκη στο οικοσύστημα της Elixir, γίνεται πολύ πιο σημαντική όταν ασχοληθούμε με το ExDoc για να παράγουμε τεκμηρίωση σε HTML δυναμικά.

**Σημείωση**: το σχόλιο '@spec' χρησιμοποιείται για την στατική ανάλυση κώδικα
Για να μάθετε περισσότερα για αυτό, επισκεφτείτε το μάθημα [Προδιαγραφές και τύποι](../../advanced/typespec).

## ExDoc

Το ExDoc είναι ένα επίσημο project της Elixir το οποίο μπορείτε να το βρείτε στο [GitHub](https://github.com/elixir-lang/ex_doc).
Παράγει **HTML (HyperText Markup Language) και ζωντανή τεκμηρίωση** για τα projects της Elixir.
Ας φτιάξουμε πρώτα ένα Mix project για την εφαρμογή μας:

```bash
$ mix new greet_everyone

* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/greet_everyone.ex
* creating test
* creating test/test_helper.exs
* creating test/greet_everyone_test.exs

Your Mix project was created successfully.
You can use "mix" to compile it, test it, and more:

    cd greet_everyone
    mix test

Run "mix help" for more commands.

$ cd greet_everyone

```

Τώρα αντιγράψτε και επικολλήστε τον κώδικά σας από το μάθημα για τον σχολιαστή `@doc` σε ένα αρχείο που ονομάζεται `lib/greeter.ex` και βεβαιωθείτε ότι όλα δουλεύουν από τη γραμμή εντολών.
Τώρα που δουλεύουμε μέσα σε ένα project Mix πρέπει να ξεκινήσουμε το IEx λίγο διαφορετικά, χρησιμοποιώντας την αλληλουχία εντολών `iex -S mix`:

```elixir
iex> h Greeter.hello

                def hello(name)

Prints a hello message

Parameters

• name: String that represents the name of the person.

Examples

    iex> Greeter.hello("Sean")
    "Hello, Sean"

    iex> Greeter.hello("pete")
    "Hello, pete"
```

### Εγκατάσταση

Λαμβάνοντας υπόψιν μας ότι όλα είναι οκ, και ότι βλέπουμε την έξοδο από πάνω σημαίνει ότι είμαστε έτοιμοι να εγκαταστήσουμε το ExDoc.
Μέσα στο αρχείο `mix.exs` προσθέστε την απαιτούμενη εξάρτηση `:ex_doc` για να ξεκινήσετε.

```elixir
def deps do
  [{:earmark, "~> 0.1", only: :dev}, {:ex_doc, "~> 0.11", only: :dev}]
end
```

Καθορίζουμε το ζευγάρι κλειδί-τιμή `only: :dev` καθώς δεν θέλουμε να κατεβάσουμε και να συντάξουμε τις εξαρτήσεις αυτές σε ένα περιβάλλον παραγωγής.

Το 'ex_doc' θα προσθέσει μια ακόμη βιβλιοθήκη για εμάς, το Earmark.

Το Earmark είναι ένας αναλυτής Markdown για την Elixir ο οποίος χρησιμοποιεί το ExDoc για να μετατρέψει την τεκμηρίωσή μας μέσα στα `@moduledoc` και `@doc` για να έχουμε πανέμορφη στην εμφάνιση HTML.

Είναι σημαντικό να σημειώσουμε σε αυτό το σημείο ότι δεν είστε υποχρεωμένοι να χρησιμοποιήσετε το Earmark.  Μπορείτε να αλλάξετε το εργαλείο σήμανσης με άλλα όπως το Cmark, πάντως θα χρειαστείτε να κάνετε λίγες παραπάνω ρυθμίσεις για τις οποίες μπορείτε να διαβάσετε [εδώ](https://hexdocs.pm/ex_doc/ExDoc.Markdown.html#module-using-cmark).
Για αυτό το φροντιστήριο θα μείνουμε με το Earmark.

### Παραγωγή Τεκμηρίωσης

Συνεχίζοντας, από τη γραμμή εντολών τρέξτε τις ακόλουθες δύο εντολές:

```bash
$ mix deps.get # φέρνει τα ExDoc + Earmark.
$ mix docs # φτιάχνει την τεκμηρίωση

Docs successfully generated.
View them at "doc/index.html".
```

Λογικά, αν όλα πήγαν καλά, θα πρέπει να βλέπετε ένα παρόμοιο μήνυμα με το μήνυμα εξόδου στο από πάνω παράδειγμα.
Ας δούμε τώρα μεσα στο Mix project μας και θα πρέπει να δούμε ότι υπάρχει ένας ακόμα φάκελος που ονομάζεται **doc/**.
Μέσα του βρίσκεται η δημιουργημένη τεκμηρίωσή μας.
Αν επισκεφθούμε την σελίδα index στο browser μας θα πρέπει να δούμε τα παρακάτω:

![ExDoc Screenshot 1]({% asset documentation_1.png @path %})

We can see that Earmark has rendered our markdown and ExDoc is now displaying it in a useful format.

![ExDoc Screenshot 2]({% asset documentation_2.png @path %})

Μπορούμε να το διαθέσουμε στο GitHub, στο website μας, πιο ειδικά στα [HexDocs](https://hexdocs.pm/).

## Καλές Πρακτικές

Η προσθήκη τεκμηρίωσης θα πρέπει να προστίθεται στις οδηγίες καλών πρακτικών μιας γλώσσας.
Επειδή η Elixir είναι μια σχετικά νέα γλώσσα, πολλά πρότυπα έχουν ακόμα να ανακαλυφθούν όσο το οικοσύστημα μεγαλώνει.
Η κοινότητα πάντως έχει κάνει προσπάθειες να καθιερώσει καλές πρακτικές.
Για να διαβάσετε περισσότερα για τις καλές πρακτικές δείτε τον [Οδηγό Στυλ της Elixir](https://github.com/niftyn8/elixir_style_guide).

  - Πάντα να τεκμηριώνετε μία ενότητα.

```elixir
defmodule Greeter do
  @moduledoc """
  This is good documentation.
  """

end
```

  - Αν δεν σκοπέυετε να τεκμηριώσετε μία ενότητα, **μην** την αφήνετε κενή.
  Σκεφτείτε να σχολιάσετε την ενότητα σαν `false` ως εξής:

```elixir
defmodule Greeter do
  @moduledoc false

end
```

 - Όταν αναφέρεστε σε συναρτήσεις μέσα στην τεκμηρίωση ενότητας, χρησιμοποιήστε βαρείες ως εξής:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  Αυτή η ενότητα επίσης έχει μια συνάρτηση `hello/1`
  """

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Χωρίστε τον κώδικά σας με το `@moduledoc` με μία γραμμή ως εξής:

```elixir
defmodule Greeter do
  @moduledoc """
  ...

  Αυτή η ενότητα επίσης έχει μια συνάρτηση `hello/1`
  """

  alias Goodbye.bye_bye
  # και ούτω καθεξής

  def hello(name) do
    IO.puts("Hello, " <> name)
  end
end
```

 - Χρησιμοποιήστε markdown μέσα στις τεκμηριώσεις.
 Με αυτόν τον τρόπο θα είναι πιο ευανάγνωστες είτε μέσω του IEx, ή του ExDoc.

```elixir
defmodule Greeter do
  @moduledoc """
  ...
  """

  @doc """
  Prints a hello message

  ## Parameters

    - name: String that represents the name of the person.

  ## Examples
  
      iex> Greeter.hello("Sean")
      "Hello, Sean"

      iex> Greeter.hello("pete")
      "Hello, pete"

  """
  @spec hello(String.t()) :: String.t()
  def hello(name) do
    "Hello, " <> name
  end
end
```

 - Προσπαθήστε να συμπεριλάβετε μερικά παραδείγματα στην τεκμηρίωσή σας.
Αυτό σας επιτρέπει να παράγετε αυτόματα τεστ από τα παραδείγματα κώδικα που βρίσκονται σε μία ενότητα, συνάρτηση, ή μακροεντολή με το [ExUnit.DocTest][].
Για να γίνει αυτό, πρέπει να καλέσετε την μακροεντολή `doctest/1` από την περίπτωση του τεστ και να γράψετε τα παραδείγματά σας με βάση κάποιες οδηγίες, οι οποίες αναλύονται στην [επίσημη τεκμηρίωση][ExUnit.DocTest]

[ExUnit.DocTest]: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
