---
version: 1.1.1
title: Ενότητες
---

Ξέρουμε από πείρας ότι είναι ακατάστατο να έχουμε όλες τις συναρτήσεις μας στο ίδιο αρχείο και με το ίδιο πεδίο δράσης.  Σε αυτό το μάθημα θα καλύψουμε το πως να συλλέγουμε συναρτήσεις και να ορίζουμε ένα ειδικό χάρτη γνωστό ως δομή ώστε να οργανώνουμε πιο αποτελεσματικά τον κώδικά μας.

{% include toc.html %}

## Ενότητες

Οι ενότητες είναι ο καλύτερος τρόπος οργάνωσης συναρτήσεων σε ένα namespace. Επιπρόσθετα της συλλογής συναρτήσεων, μας επιτρέπουν να ορίζουμε ονομασμένες και ιδιωτικές συναρτήσεις τις οποίες καλύψαμε σε προηγούμενο μάθημα.

Ας δούμε ένα βασικό παράδειγμα:

``` elixir
defmodule Example do
  def greeting(name) do
    "Γεια σου #{name}."
  end
end

iex> Example.greeting "Sean"
"Γειά σου Sean."
```

Είναι δυνατόν να ενσωματώσουμε ενότητες στην Elixir, επιτρέποντας μας να ομαδοποιήσουμε περαιτέρω την λειτουργικότητά μας:

```elixir
defmodule Example.Greetings do
  def morning(name) do
    "Καλημέρα #{name}."
  end

  def evening(name) do
    "Καληνύχτα #{name}."
  end
end

iex> Example.Greetings.morning "Sean"
"Καλημέρα Sean."
```

### Ορίσματα Ενοτήτων

Τα ορίσματα ενοτήτων είναι πιο συχνά ως σταθερές στην Elixir.  Ας δούμε ένα απλό παράδειγμα:

```elixir
defmodule Example do
  @greeting "Γεια σου"

  def greeting(name) do
    ~s(#{@greeting} #{name}.)
  end
end
```

Είναι σημαντικό να σημειώσουμε ότι υπάρχουν κατειλημμένα ορίσματα στην Elixir.  Τα τρία πιο συχνά είναι:

+ `moduledoc` — Τεκμηριώνει την τρέχουσα ενότητα.
+ `doc` — Τεκμηρίωση συναρτήσεων και μακροεντολών.
+ `behaviour` — Χρήσης μιας OTP ή μιας καθορισμένης από το χρήστη συμπεριφοράς.

## Δομές

Οι δομές είναι ειδικοί χάρτες με ένα ορισμένο σύνολο κλειδιών και προκαθορισμένες τιμές.  Μια δομή πρέπει να είναι ορισμένη μέσα σε μια ενότητα, από την οποία παίρνει και το όνομά της.  Είναι συχνό για μια δομή να είναι το μόνο πράγμα που ορίζεται σε μια ενότητα.

Για να ορίσουμε μια δομή χρησιμοποιούμε την `defstruct` μαζί με μια λίστα λέξεων κλειδί από πεδία και προκαθορισμένες τιμές:

```elixir
defmodule Example.User do
  defstruct name: "Sean", roles: []
end
```

Ας δημιουργήσουμε μερικές δομές:

```elixir
iex> %Example.User{}
%Example.User{name: "Sean", roles: []}

iex> %Example.User{name: "Steve"}
%Example.User{name: "Steve", roles: []}

iex> %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
```

Μπορούμε να αναβαθμίσουμε μια δομή όπως θα το κάναμε σε ένα χάρτη:

```elixir
iex> steve = %Example.User{name: "Steve", roles: [:admin, :owner]}
%Example.User{name: "Steve", roles: [:admin, :owner]}
iex> sean = %{steve | name: "Sean"}
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

Σημαντικότερα, μπορούμε να αντιπαραβάλουμε δομές με χάρτες:

```elixir
iex> %{name: "Sean"} = sean
%Example.User{name: "Sean", roles: [:admin, :owner]}
```

## Σύνθεση

Τώρα που ξέρουμε πως να δημιουργήσουμε ενότητες και δομές ας μάθουμε πως να προσθέσουμε λειτουργικότητα σε αυτές μέσω της σύνθεσης.  Η Elixir μας παρέχει μια ποικιλία διαφορετικών τρόπων για να αλληλεπιδρούμε με άλλες ενότητες.

### `alias`

Μας επιτρέπει να δίνουμε ψευδώνυμο σε ονόματα ενοτήτων.  Χρησιμοποιείται πολύ συχνά σε κώδικα Elixir:

```elixir
defmodule Sayings.Greetings do
  def basic(name), do: "Γεια σου, #{name}"
end

defmodule Example do
  alias Sayings.Greetings

  def greeting(name), do: Greetings.basic(name)
end

# Χωρίς ψευδώνυμο

defmodule Example do
  def greeting(name), do: Sayings.Greetings.basic(name)
end
```

Αν υπάρχει σύγκρουση μεταξύ δύο ψευδωνύμων ή απλά επιθυμούμε να δώσουμε ψευδώνυμο ένα τελείως διαφορετικό όνομα, μπορούμε να χρησιμοποιήσουμε την επιλογή της `:as`:

```elixir
defmodule Example do
  alias Sayings.Greetings, as: Hi

  def print_message(name), do: Hi.basic(name)
end
```

Είναι επίσης εφικτό να δώσουμε ψευδώνυμο σε πολλές ενότητες μαζί:

```elixir
defmodule Example do
  alias Sayings.{Greetings, Farewells}
end
```

### `import`

Αν θέλουμε να εισάγουμε συναρτήσεις και μακροεντολές αντί να δώσουμε ψευδώνυμο στην ενότητα τότε χρησιμοποιούμε την `import`:

```elixir
iex> last([1, 2, 3])
** (CompileError) iex:9: undefined function last/1
iex> import List
nil
iex> last([1, 2, 3])
3
```

#### Φιλτράρισμα

Είναι προκαθορισμένο όλες οι συναρτήσεις και οι μακροεντολές να εισάγονται αλλά μπορούμε να τις φιλτράρουμε χρησιμοποιώντας τις επιλογές `:only` και `:except` .

Για να εισάγουμε συγκεκριμένες συναρτήσεις και μακροεντολές, πρέπει να παρέχουμε το ζευγάρι όνομα/τάξη στις `:only` και `:except`.  Ας ξεκινήσουμε εισάγοντας μόνο την συνάρτηση `last/1`:

```elixir
iex> import List, only: [last: 1]
iex> first([1, 2, 3])
** (CompileError) iex:13: undefined function first/1
iex> last([1, 2, 3])
3
```

Αν εισάγουμε τα πάντα εκτός της `last/1` και δοκιμάσουμε τις ίδιες συναρτήσεις με πριν:

```elixir
iex> import List, except: [last: 1]
nil
iex> first([1, 2, 3])
1
iex> last([1, 2, 3])
** (CompileError) iex:3: undefined function last/1
```

Επιπρόσθετα στα ζεύγη όνομα/τάξη υπάρχουν δύο ειδικά άτομα, τα `:functions` και `:macros`, τα οποία εισάγουν μόνο συναρτήσεις και μακροεντολές αντίστοιχα:

```elixir
import List, only: :functions
import List, only: :macros
```

### `require`

Παρόλο που χρησιμοποιείται λιγότερο συχνά η `require/2` είναι εξίσου σημαντική.  Η χρήση μιας ενότητας εξασφαλίζει ότι συντάσσεται και φορτώνεται.  Αυτό είναι πιο χρήσιμο όταν θέλουμε να έχουμε πρόσβαση στις μακροεντολές μιας ενότητας:

```elixir
defmodule Example do
  require SuperMacros

  SuperMacros.do_stuff
end
```

Αν προσπαθήσουμε να καλέσουμε μια μακροεντολη η οποία δεν έχει φορτωθεί ακόμα η Elixir θα σηκώσει ένα σφάλμα.

### `use`

Η μακροεντολη `use` καλεί μια ειδική μακροεντολή, την `__using__/1` από την ορισμένη ενότητα: Ένα παράδειγμα:

```elixir
# lib/use_import_require/use_me.ex
defmodule UseImportRequire.UseMe do
  defmacro __using__(_) do
    quote do
      def use_test do
        IO.puts("use_test")
      end
    end
  end
end
```

και προσθέτουμε αυτή τη γραμμή στην UseImportRequire:

```elixir
use UseImportRequire.UseMe
```

Η χρήση της UseImportRequire.UseMe ορίζει μια use_test/0 συνάρτηση μέσω της κλήσης της μακροεντολής `__using__/1`.

Αυτό μόνο κάνει η use.  Πάντως, είναι συχνό για την μακροεντολή `__using__` να καλέσει τις alias, require, ή import.  Αυτό με τη σειρά του θα δημιουργήσει ψευδώνυμα ή εισαγωγές στη χρησιμοποιούμενη ενότητα.  Αυτό επιτρέπει στην ενότητα που χρησιμοποιείται να ορίζει μια πολιτική για το πως οι συναρτήσεις και οι μακροεντολές της θα αναφέρονται.  Αυτό είναι πολύ ευέλικτο καθώς η `__using__/1` μπορεί να καθορίζει αναφορές σε άλλες ενότητες, ειδικά σε υποενότητες.

Ο σκελετός εφαρμογών Phoenix χρησιμοποιεί την use και `__using__/1` για να μειώσει την ανάγκη για επαναλαμβανόμενα ψευδώνυμα και εισαγωγές στις καθορισμένες από το χρήστη ενότητες.

Ορίστε ένα μικρό και ωραίο παράδειγμα από την ενότητα Ecto.Migration:

```elixir
defmacro __using__(_) do
  quote location: :keep do
    import Ecto.Migration
    @disable_ddl_transaction false
    @before_compile Ecto.Migration
  end
end
```

Η μακροεντολή `Ecto.Migration.__using__/1` περιλαμβάνει μια εισαγωγή ώστε όταν εσείς καλείτε την `use Ecto.Migrate`, επίσης καλείτε την `import Ecto.Migration`.  Επίσης ορίζει μια ιδιότητα ενότητας η οποία υποθέτουμε ελέγχει τη συμπεριφορά του Ecto.

Για να συνοψίσουμε: η μακροεντολή use απλά καλεί την μακροεντολή `__using__/1` της ορισμένης ενότητας.  Για να καταλάβετε τι κάνει αυτή πρέπει να διαβάσετε την μακροεντολή `__using__/1`.


**Σημείωση**: οι `quote`, `alias`, `use` και `require` είναι μακροεντολές που χρησιμοποιούνται όταν δουλεύουμε με τον [μεταπρογραμματισμό](../../advanced/metaprogramming).
