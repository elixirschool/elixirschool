---
version: 1.1.1
title: StreamData
---

Μια βιβλιοθήκη δοκιμών μονάδων βασισμένη στα παραδείγματα όπως η [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) είναι ένα θαυμάσιο εργαλείο που θα σας βοηθήσει να επιβεβαιώσετε πως ο κώδικάς σας λειτουργεί όπως θα θέλατε.
Ωστόσο, οι δοκιμές μονάδων που βασίζονται σε παραδείγματα, έχουν κάποια μειονεκτήματα:

* Είναι εύκολο να χάσουμε ακραίες περιπτώσεις, καθώς ελέγχουμε μόνο μερικές εισόδους.
* Μπορείτε να γράψετε αυτές τις δοκιμές χωρίς να σκεφτείτε διεξοδικά τις απαιτήσεις σας.
* Αυτές οι δοκιμές μπορεί να είναι πολύ εκτενή όταν έχετε πολλαπλά παραδείγματα για μία συνάρτηση.

Σε αυτό το μάθημα θα εξερευνήσουμε, πως η [StreamData](https://github.com/whatyouhide/stream_data) μπορεί να μας βοηθήσει να ξεπεράσουμε μερικά από αυτά τα μειονεκτήματα.

{% include toc.html %}

## Τι είναι η StreamData;

Η [StreamData](https://github.com/whatyouhide/stream_data) είναι μια βιβλιοθήκη που διενεργεί δοκιμές βάση ιδιότητας χωρίς κατάσταση.

Η βιβλιοθήκη StreamData θα εκτελέσει κάθε δοκιμη [προκαθορισμένα 100 φορές](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options), χρησιμοποιώντας τυχαία δεδομένα κάθε φορά.
Όταν μια δοκιμή αποτύχει, η StreamData θα προσπαθήσει να [συρρικνώσει](https://hexdocs.pm/stream_data/StreamData.html#module-shrinking) την είσοδο στην μικρότερη τιμή που προκαλεί το σφάλμα.
Αυτό μπορεί να σας βοηθήσει όταν πρέπει να κάνετε αποσφαλμάτωση στον κώδικά σας!
Αν μια λίστα 50 αντικειμένων κάνει την συνάρτηση σας μη λειτουργική, και μόνο ένα από τα στοιχεία της λίστας είναι προβληματικό, η StreamData μπορεί να σας βοηθήσει να αναγνωρίσετε το προβληματικό στοιχείο.

Αυτή η βιβλιοθήκη δοκιμών έχει δύο βασικές ενότητες.
[`StreamData`](https://hexdocs.pm/stream_data/StreamData.html) παράγει ακολουθείες τυχαίων δεδομένων.
[`ExUnitProperties`](https://hexdocs.pm/stream_data/ExUnitProperties.html) σας επιτρέπει να διενεργείτε δοκιμές στις συναρτήσεις σας, χρησιμοποιόντας τα παραχθέντα δεδομένα ως εισαγωγές.

Μπορεί να αναρωτιέστε πως μπορύμε να πούμε κάτι ουσιώδες για κάποια συνάρτηση αν δεν ξέρουμε ποιά είναι τα δεδομένα που εισάγονται. Συνεχίστε το διάβασμα!

## Εγκατάσταση της StreamData

Αρχικά, δημιουργήστε ένα νέο mix πρότζεκτ.
Ανατρέξτε στο [Νέα Projects](https://elixirschool.com/gr/lessons/basics/mix/#new-projects) αν χρειάζεστε κάποια βοήθεια.

Στη συνέχεια, προσθέστε την StreamData ως εξάρτηση στο `mix.exs` αρχείο σας:

```elixir
defp deps do
  [{:stream_data, "~> x.y", only: :test}]
end
```

Απλά αντικαταστήστε το `x` και το `y` με την έκδοση της StreamData που εμφανίζεται στις [οδηγίες εγκατάστασης](https://github.com/whatyouhide/stream_data#installation) της βιβλιοθήκης.

Τέλος, τρέξτε αυτή την εντολή από την γραμμή εντολών του τερματικού σας:

```shell
mix deps.get
```

## Χρησιμοποιώντας την StreamData

Για να απεικονίσουμε το χαρακτηρηστικά της StreamData, θα γράψουμε μερικές απλές βοηθητικές συναρτήσεις που επαναλαμβάνουν τιμές.
Ας πούμε πως θέλουμε μια συνάρτηση όπως η [`String.duplicate/2`](https://hexdocs.pm/elixir/String.html#duplicate/2), αλλά να δημιουργεί αντίγραφα από αλφαριθμητικά, λίστες ή τούπλες.

### Αλφαριθμητικά

Αρχικά, ας γράψουμε μια συνάρτηση η οποία αντιγράφει αλφαριθμητικά.
Ποιές θα ήταν κάποιες προυποθέσεις για την συνάρτησή μας;

1. Το πρώτο στοιχείο θα πρέπει να είναι αλφαριθμητικό.
Αυτό είναι το αλφαριθμητικό που θα αντιγράψουμε.
2. Το δεύτερο στοιχείο θα πρέπει να είναι ένας θετικός ακέραιος.
Αυτό θα μας δείχνει πόσες φορές θα αντιγράψουμε το πρώτο στοιχείο.
3. Η συνάρτησή μας θα πρέπει να επίστρέφει αλφαριθμητικό.
Αυτό το νέο αλφαριθμητικό θα είναι το αρχικό αλφαριθμητικό, που θα έχει αναπαραχθεί από μηδέν έως περισσότερες φορές.
4. Αν το αρχικό αλφαριθμητικό είναι κενό, το επιστρεφόμενο αλφαριθμητικο θα πρέπει επίσης να είναι κενό.
5. Αν το δεύτερο στοιχείο είναι `0`, το επιστρεφόμενο αλφαριθμητικό πρέπει να είναι κενό.

Όταν τρέχουμε την συνάρτησή μας, θα θέλουμε να φαίνεται κάπως έτσι:

```elixir
Repeater.duplicate("a", 4)
# "aaaa"
```

Η Elixir έχει μια συνάρτηση, την `String.duplicate/2` η οποία θα το χειριστεί αυτό για εμάς.
Η νέα μας `duplicate/2` απλά θα κάνει αναγωγή σε αυτήν τη συνάρτηση:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end
end
```

Θα είναι εύκολο να δοκιμάσουμε μια ιδανική περίπτωση με την [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html).

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicate/2" do
    test "creates a new string, with the first argument duplicated a specified number of times" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end
  end
end
```

Αυτό παρ'όλα αυτά δεν αποτελεί μια περιεκτική δοκιμή.
Τι θα συμβαίνει στην περίπτωση που το δεύτερο στοιχείο είναι `0`;
Ποιό θα είναι το αποτέλεσμα όταν το πρώτο στοιχείο είναι ένα κενό αλφαριθμητικό;
Τι σημαίνει το να επαναλάβουμε ένα κενό αλφαριθμητικό;
Πως θα λειτουργεί η συνάρτησή μας με χαρακτήρες κωδικοποιημένους σε UTF-8;
Θα λειτουργεί η συνάρτησή μας με εισαγόμενα αλφαριθμητικά μεγάλου μεγέθους;

Θα μπορούσαμε να γράψουμε περισσότερα παραδείγματα για να δοκιμάσουμε ακραίες περιπτώσεις και μεγάλα αλφαρθμητικά.
Ωστόσο, ας δούμε αν μπορούμε να χρησιμοποιήσουμε την StreamData για να δοκιμάσουμε αυτήν τη συνάρτηση πιο αυστηρά, χωρίς πολύ περισσότερο κώδικα.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do

        assert ??? == Repeater.duplicate(str, times)
      end
    end
  end
end
```

Τι κάνει αυτό;

* Αντικαταστήσαμε την `test` με την [`property`](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109).
Αυτό μας δίνει την δυνατότητα να καταγράψουμε το στοιχείο που δοκιμάζουμε.
* Το [`check/1`](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1) είναι μια μακροεντολή που μας επιτρέπει να ρυθμίσουμε τα δεδομένα που θα χρησιμοποιήσουμε στην δοκιμή.
* Η [`StreamData.string/2`](https://hexdocs.pm/stream_data/StreamData.html#string/2) δημιουργεί τυχαία αλφαριθμητικά.
* Μπορούμε να παραλείψουμε το όνομα της ενότητας όταν καλούμε την `string/2` επειδή το `use ExUnitProperties` [εισάγει συναρτήσεις της StreamData](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109).
* Η `StreamData.integer/0` παράγει τυχαίους ακεραίους.
* Το `times >= 0` λειτουργεί ως ρήτρα προστάτη.
Διασφαλίζει ότι οι τυχαίοι ακέραιοι που χρησιμοποιούμε στις δοκιμές μας είναι μεγαλύτεροι ή ίσοι με το μηδέν.
Υπάρχει και η [`SreamData.positive_integer/0`](https://hexdocs.pm/stream_data/StreamData.html#positive_integer/0), αλλά δεν είναι ακριβώς αυτό που θέλουμε, αφότου το `0` είναι μια αποδεκτή τιμή για την συνάρτησή μας.

Το `???`είναι απλά κάποιος ψευδοκώδικας που προσθέσαμε.
Τι ακριβώς θα πρέπει να βεβαιώσουμε ως ισότητα;
Θα _μπορούσαμε_ να γράψουμε:

```elixir
assert String.duplicate(str, times) == Repeater.duplicate(str, times)
```

...αυτό όμως χρησιμοποιεί την πραγματική υλοποίηση της συνάρτησης, κάτι το οποίο δεν είναι χρήσιμο.
Θα μπορούσαμε να χαλαρώσουμε λίγο την βεβαίωση της ισότητάς μας απλά επιβεβαιώνοντας το μήκος του αλφαριθμητικού:

```elixir
expected_length = String.length(str) * times
actual_length =
  str
  |> Repeater.duplicate(times)
  |> String.length()

assert actual_length == expected_length
```

Κάπως καλύτερα, αλλά δεν είναι ιδανικό.
Αυτή η δοκιμή θα ήταν σωστή αν η συνάρτησή μας παρήγαγε τυχαία αλφαριθμητικά σωστού μήκους.

Στην πραγματικότητα θέλουμε να επιβεβαιώνουμε δύο πράγματα:

1. Η συνάρτησή μας παράγει αλφαριθμητικά του σωστού μεγέθους.
2. Τα περιεχόμενα του τελικού αλφαριθμητικού, είναι το αρχικό αλφαριθμητικό το οποίο επαναλαμβάνεται.

Αυτό είναι ένας άλλος τρόπος να [επαναδιατυπώσουμε το στοιχείο](https://www.propertesting.com/book_what_is_a_property.html#_alternate_wording_of_properties).
Ήδη έχουμε κάποιον κώδικα για να επιβεβαιώσουμε το #1.
Για να επιβεβαιώσουμε το #2, ας χωρίσουμε το τελικό αλφαριθμητικό από το αρχικό, και ας επιβεβαιώσουμε ότι μας μένει μια λίστα με κανένα ή περισσότερα κενά αλφαριθμητικά.

```elixir
list =
  str
  |> Repeater.duplicate(times)
  |> String.split(str)

assert Enum.all?(list, &(&1 == ""))
```

Ας συνδιάσουμε τις επιβεβαιώσεις ισότητάς μας:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end
  end
end
```

Όταν το συγκρίνουμε με την αρχική μας δοκιμή, βλέπουμε ότι η έκδοση με την χρήση της StreamData έχει το διπλάσιο μέγεθος.
Ωστόσο, αφού ορίσετε περισσότερες περιπτώσεις στην αρχική δοκιμή...

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicating a string" do
    test "duplicates the first argument a number of times equal to the second argument" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end

    test "returns an empty string if the first argument is an empty string" do
      assert "" == Repeater.duplicate("", 4)
    end

    test "returns an empty string if the second argument is zero" do
      assert "" == Repeater.duplicate("a", 0)
    end

    test "works with longer strings" do
      alphabet = "abcdefghijklmnopqrstuvwxyz"

      assert "#{alphabet}#{alphabet}" == Repeater.duplicate(alphabet, 2)
    end
  end
end
```

Η έκδοση με την χρήση της StreamData είναι στην πραγματικότητα μικρότερη.
Η StreamData καλύπτει επίσης ακραίες περιπτώσεις τις οποίες ένας προγραμματιστής μπορεί να ξεχάσει να δοκιμάσει.

### Λίστες

Τώρα, ας γράψουμε μια συνάρτηση η οποία θα επαναλαμβάνει λίστες.
Θέλουμε η συνάρτηση να λειτουργεί ως εξής:

```elixir
Repeater.duplicate([1, 2, 3], 3)
# [1, 2, 3, 1, 2, 3, 1, 2, 3]
```

Ορίστε μια σωστή, αλλά όχι και τόσο αποδοτική, εφαρμογή:

```elixir
defmodule Repeater do
  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end
end
```

Μια δοκιμή με την χρήστη της StreamData θα ήταν κάπως έτσι:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end
  end
end
```

Χρησιμοποιήσαμε τις `StreamData.list_of/1` και `StreamData.term/0` για να δημιουργήσουμε λίστες τυχαίου μήκους, των οποίων τα στοιχεία είναι οποιουδήποτε τύπου.

Ομοίως με τις δοκιμές βάση ιδιότητας για τα επαναλαμβανόμενα αλφαριθμητικά, συγκρίνουμε το μήκος της νέας λίστας με το προϊόν της αρχικής λίστας και το `times`.
Η δεύτερη βεβαίωση ισότητας χρειάζεται κάποια εξήγηση:

1. Σπάμε την νέα λίστα σε πολλαπλές λίστες, κάθε μια εκ των οποίων έχει τον ίδιο αριθμό στοιχείων όπως η `list`.
2. Έπειτα επιβεβαιώνουμε ότι κάθε μια από τις παραγόμενες λίστες είναι ίση με την `list`.

Για να το θέσουμε διαφορετικά, βεβαιωνόμαστε ότι η αρχική μας λίστα εμφανίζεται στην τελευταία λίστα στον σωστό αριθμό επαναλήψεων, και ότι κανένα _άλλο_ στοιχείο δεν εμφανίζεται στην τελευταία λίστα μας.

Γιατί χρησιμοποιήσαμε την υπόθεση;
Η  πρώτη βεβαίωση ισότητας και η υπόθεση συνδιάζονται για να δούμε ότι η πρώτη και τελευταία λίστα είναι κενές, οπότε δεν υπάρχει λόγος για περαιτέρω σύγκριση στις λίστες μας.
Επιπλέον, η `Enum.chunk_every/2` απαιτεί το δεύτερο στοιχείο να είναι θετικό.

### Τούπλες

Εν τέλει, ας εφαρμόσουμε μια συνάρτηση η οποία επαναλαμβάνει τα στοιχεία μιας τούπλας.
Η συνάρτηση θα πρέπει να λειτουργεί ως εξής:

```elixir
Repeater.duplicate({:a, :b, :c}, 3)
# {:a, :b, :c, :a, :b, :c, :a, :b, :c}
```

Ένας τρόπος προσέγγισης θα ήταν να μετατρέψουμε την τούπλα σε λίστα, να αντιγράψουμε την λίστα, και να μετατρέψουμε ξανά την δομή δεδομένων σε τούπλα.

```elixir
defmodule Repeater do
  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

Πως θα μπορούσαμε να το δοκιμάσουμε αυτό;
Ας κάνουμε μια διαφορετική προσέγγιση απ'ότι μέχρι τώρα.
Για αλφαριθμητικά και λίστες, βεβαιώναμε ισότητες σχετικά με το μήκος και τα περιεχόμενα των τελικών παραγόμενων δεδομένων.
Η προσέγγιση στις τούπλες με την ίδια λογική είναι εφικτή, αλλά ο κώδικας της δοκιμής μπορεί να μην είναι και τόσο ευκρινής.

Σκεφτείτε δύο ακολουθίες λειτουργιών που θα μπορούσατε να εφαρμόσετε σε μια τούπλα:

1. Καλέστε την `Repeater.duplicate/2` στην τούπλα, και μετατρέψτε το αποτέλεσμα σε λίστα.
2. Μετατρέψτε την τούπλα σε λίστα, και περάστε την λίστα στην `Repeater.duplicate/2`.

Αυτή είναι μια προσέγγιση, όπως την αποκαλεί ο Scott Wlaschin, του τύπου ["Διαφορετικές οδοί, Ίδιος Προορισμός"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/#different-paths-same-destination).
Θα περίμενα και τις δύο αυτές ακολουθίες λειτουργιών να έχουν το ίδιο αποτέλεσμα.
Ας χρησιμοποιήσουμε αυτή την προσέγγιση στην δοκιμή μας.

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

## Περίληψη

Τώρα έχουμε τρεις τύπους συναρτήσεων που εναπαναλαμβάνουν αλφαριθμητικά, λίστες στοιχείων, και τούπλες στοιχείων.
Έχουμε μερικές δοκιμές βάσει ιδιότητας οι οποίες μας δίνουν την σιγουριά, σε έναν μεγάλο βαθμό, πως η εφαρμογή τους είναι σωστή.

Ορίστε και ο κώδικας της τελικής μας εφαρμογής:

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end

  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end

  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

Εδώ είναι οι δοκιμές βάσει ιδιότητας:

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end

    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end

    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

Μπορείτε τώρα να τρέξετε τις δοκιμές σας εισάγοντας στην γραμμή εντολών του τερματικού σας το ακόλουθο:

```shell
mix test
```

Να θυμάστε πως κάθε δοκιμή που γράφετε με την StreamData θα τρέχει προκαθορισμένα 100 φορές.
Επί πρόσθετα, μερικά απο τα τυχαία δεδομένα που παράγει η StreamData χρειάζονται λίγο χρόνο παραπάνω για να παραχθούν.
Η ουσία είναι πως αυτοί οι τύποι δοκιμών θα εκτελούνται πιο αργά από τις δοκιμές βάσει παραδειγμάτων.

Ακόμα και έτσι, οι δοκιμές βάσει ιδιότητας είναι μια καλή προσθήκη στις δοκιμές βάσει παραδειγμάτων.
Μας επιτρέπουν να γράψουμε περιεκτικές δοκιμές που καλύπτουν μια ευρεία γκάμα δεδομένων εισόδου.
Αν δεν χρειάζεται να διατηρήσουμε κάποια κατάσταση μεταξύ των δοκιμαστικών εκτελέσεων, η StreamData προσφέρει καλή σύνταξη για να γράψουμε δοκιμές βάσει ιδιότητας.
