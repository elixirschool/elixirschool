%{
  version: "1.0.2",
  title: "Βοηθοί IEx",
  excerpt: """
  
  """
}
---

## Σύνοψη

Καθώς ξεκινάτε να δουλεύετε με την Elixir, το IEx είναι ο καλύτερος σας φίλος.
Είναι ένα REPL, αλλά έχει πολλά προηγμένα χαρακτηριστικά τα οποία μπορούν να κάνουν τη ζωή σας πιό εύκολη καθώς εξερευνάτε νέο κώδικα ή αναπτύσσετε τη δική σας δουλειά.
Υπάρχει μια πλειάδα προεγκατεστημένων βοηθών που θα αναλύσουμε σε αυτό το μάθημα.

### Αυτόματη Συμπλήρωση

Καθώς εργάζεστε στο κέλυφος, μπορεί να βρεθείτε να χρησιμοποιείτε μία νέα ενότητα με την οποία δεν είστε εξοικειωμένοι.
Για να κατανοήσετε μέρος του τι σας είναι διαθέσιμο, η λειτουργικότητα της αυτόματης συμπλήρωσης είναι εξαιρετική.
Απλά γράψτε το όνομα της ενότητας, ακολουθούμενο από μια `.` και ένα `Tab`.

```elixir
iex> Map. # πατήστε το Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```

Και τώρα ξέρουμε τις συναρτήσεις που έχουμε και την τάξη τους.

### `.iex.exs`

Κάθε φορά που ξεκινάει το IEx θα ψάξει για ένα αρχείο ρυθμίσεων `.iex.exs`. Αν δεν είναι παρών στον τρέχοντα κατάλογο, τότε θα χρησιμοποιηθεί ο γονικός κατάλογος του χρήστη (`~/.iex.exs`) σαν εφεδρικός.

Οι επιλογές ρυθμίσεων και ο κώδικας που ορίζονται σε αυτό το αρχείο θα μας είναι διαθέσιμα όταν το κέλυφος του IEx ξεκινάει. 
Για παράδειγμα, αν θέλουμε να μας είναι διαθέσιμες μερικές βοηθητικές συναρτήσεις στο IEx, μπορούμε να ανοίξουμε το `.iex.exs` και να κάνουμε μερικές αλλαγές.

Ας ξεκινήσουμε προσθέτοντας μια ενότητα με μερικές βοηθητικές συναρτήσεις:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Τώρα όταν τρέχουμε το IEx θα έχουμε την ενότητα IExHelpers διαθέσιμη σε εμάς από την αρχή. Ανοίξτε το IEx και δοκιμάστε τους νέους μας βοηθούς:

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Όπως βλέπουμε δεν χρειάζεται να κάνουμε τίποτα το ιδιαίτερο για να απαιτήσουμε ή εισάγουμε τους βοηθούς μας, το IEx το κάνει για εμάς.

### `h`

Το `h` είναι ένα από τα πιο χρήσιμα εργαλεία που μας παρέχει το κέλυφος Elixir.
Εξαιτίας της εξαιρετικής υποστήριξης που έχει η γλώσσα για την τεκμηρίωση, μπορούμε να έχουμε πρόσβαση στα έγγραφα οποιουδήποτε κώδικα χρησιμοποιώντας αυτόν το βοηθό.
Είναι εύκολο να το δείτε στην πράξη:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4] 

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as a result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

Και τώρα μπορούμε ακόμα να το συνδυάσουμε με τα χαρακτηριστικά αυτόματης συμπλήρωσης του κελύφους μας.
Φανταστείτε ότι εξερευνούμε την Map για πρώτη φορά:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Όπως βλέπουμε δεν ήμασταν μόνο σε θέση να βρούμε ποιές συναρτήσεις ήταν διαθέσιμες σαν μέρος της ενότητας, αλλά και να έχουμε πρόσβαση στα επί μέρους έγγραφα συναρτήσεων, πολλά από τα οποία περιλαμβάνουν παραδείγματα χρήσης.

### `i`

Ας χρησιμοποιήσουμε τις νέες μας γνώσεις χρησιμοποιώντας τον `h` για να μάθουμε μερικά πράγματα για τον βοηθό `i`.

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Τώρα έχουμε ένα σύνολο πληροφοριών για την `Map` συμπεριλαμβανομένου και το που αποθηκεύεται ο πηγαίος κώδικάς της και τις ενότητες που αναφέρει. Αυτό είναι αρκετά χρήσιμο όταν εξερευνούμε ειδικούς, ξένους τύπους δεδομένων και νέες συναρτήσεις.

Οι επι μέρους κεφαλίδες μπορεί να είναι πολύ συμπυκνωμένες, αλλά μπορούμε να συγκεντρώσουμε κάποιες χρήσιμες πληροφορίες σε υψηλότερο επίπεδο:

- Είναι ένας τύπος δεδομένων ατόμου
- Που βρίσκεται ο πηγαίος κώδικας
- Η έκδοση, και οι επιλογές σύνταξης
- Μια γενική περιγραφή
- Πως να έχετε πρόσβαση σε αυτήν
- Ποιές άλλες ενότητες αναφέρει

Αυτό μας δίνει αρκετές πληροφορίες για να δουλέψουμε και είναι καλύτερο από το να πηγαίνουμε στα τυφλά.

### `r`

Αν θέλουμε να ξανασυντάξουμε μια συγκεκριμένη ενότητα μπορούμε να χρησιμοποιήσουμε τον βοηθό `r`. Ας πούμε ότι αλλάξαμε κάποιο κώδικα και θέλουμε να τρέξουμε μια νέα συνάρτηση που προσθέσαμε. Για να το κάνουμε αυτό πρέπει να αποθηκεύσουμε τις αλλαγές μας και να τις επανασυντάξουμε τον `r`:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `t`

Ο βοηθός `t` μας λέει για τους διαθέσιμους τύπους σε μια δοθείσα ενότητα.

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

Και τώρα ξέρουμε ότι η `Map` ορίζει τύπους κλειδιών και τιμής στην υλοποίηση της.
Αν πάμε και κοιτάξουμε στον πηγαίο κώδικα της `Map`:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Αυτό είναι ένα απλό παράδειγμα, που αναφέρει ότι τα κλειδιά και οι τιμές κατά την υλοποίηση μπορούν να είναι οποιουδήποτε τύπου, αλλά είναι χρήσιμο να το ξέρουμε.

Αξιοποιώντας όλες αυτές τις προεγκατεστημένες λεπτομέρειες μπορούμε εύκολα να εξερευνήσουμε τον κώδικα και να μάθουμε περισσότερα για το πως δουλεύουν κάποια πράγματα. Το IEx είναι ένα πολύ δυνατό και στιβαρό εργαλείο που βοηθάει τους προγραμματιστές. Με αυτά τα εργαλεία στην εργαλειοθήκη μας, η εξερεύνηση και η δημιουργία μπορούν να γίνουν ακόμα πιο διασκεδαστικές!
