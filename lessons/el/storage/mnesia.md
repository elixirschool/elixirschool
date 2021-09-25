%{
  version: "1.2.0",
  title: "Mnesia",
  excerpt: """
  To Mnesia είναι ένα κατανεμημένο σύστημα διαχείρισης βάσεων δεδομένων που λειτουργεί σε πραγματικό χρόνο.
  """
}
---

## Επισκόπηση

Το Mnesia είναι ένα Σύστημα Διαχείρισης Βάσεων Δεδομένων (Database Management System - DBMS) που έρχεται μαζί με το Erlang Runtime System το οποίο μπορούμε να χρησιμοποιήσουμε φυσικά με την Elixir.
Το *σχεσιακό και υβριδικό αντικείμενο μοντέλο δεδομένων* του Mnesia είναι το πιο ταιριαστό για την ανάπτυξη κατανεμημένων εφαρμογών κάθε κλίμακας.

## Πότε να το χρησιμοποιήσετε

Δεν είναι πάντα ξεκάθαρο το πότε θα χρησιμοποιήσουμε ένα κομμάτι τεχνολογίας.
Αν μπορείτε να απαντήσετε 'ναι' σε κάποια από τις παρακάτω ερωτήσεις, τότε αυτή είναι μια καλή ένδειξη για τη χρήση του Mnesia αντί των ETS ή DETS.

  - Χρειάζεται να γυρίσω πίσω μεταφορές;
  - Χρειάζομαι ένα εύκολο στη χρήση συντακτικό για την ανάγνωση και εγγραφή δεδομένων;
  - Πρέπει να αποθηκεύσω δεδομένα σε πάνω από ένα κόμβο;
  - Χρειάζομαι μια επιλογή στο που να αποθηκεύσω πληροφορίες (στη RAM ή στο δίσκο);

## Σχήμα

Καθώς το Mnesia είναι μέρος του πυρήνα της Erlang, όχι της Elixir, πρέπει να χρησιμοποιήσουμε το συντακτικό με την άνω κάτω τελεία για να έχουμε πρόσβαση σε αυτό (δείτε το μάθημα: [Αλληλεπίδραση με την Erlang](../../advanced/erlang/)) ως εξής:

```shell

iex> :mnesia.create_schema([node()])

# ή αν προτιμάτε το στυλ της Elixir...

iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
```

Για αυτό το μάθημα, θα χρησιμοποιήσουμε την τελευταία προσέγγιση όταν δουλεύουμε με το API του Mnesia.
Η `Mnesia.create_schema/1` αρχικοποιεί ένα άδειο σχήμα και του περνάει μια λίστα κόμβων.
Σε αυτή την περίπτωση, περνάμε τον κόμβο που είναι συσχετισμένος με τη συνεδρία μας στο IEX.

## Κόμβοι

Αφού τρέξετε την εντολή `Mnesia.create_schema([node()])` στο IEx, θα πρέπει να βλέπετε ένα φάκελο που ονομάζεται **Mnesia.nonode@nohost** ή παρόμοιο στον τρέχοντα φάκελο εργασίας.
Ίσως αναρωτιέστε τι σημαίνει το **nonode@nohost** καθώς δεν το έχουμε ξανα συναντήσει.
Για να το δούμε.

```shell
$ iex --help
Usage: iex [options] [.exs file] [data]

  -v                Prints version
  -e "command"      Evaluates the given command (*)
  -r "file"         Requires the given files/patterns (*)
  -S "script"       Finds and executes the given script
  -pr "file"        Requires the given files/patterns in parallel (*)
  -pa "path"        Prepends the given path to Erlang code path (*)
  -pz "path"        Appends the given path to Erlang code path (*)
  --app "app"       Start the given app and its dependencies (*)
  --erl "switches"  Switches to be passed down to Erlang (*)
  --name "name"     Makes and assigns a name to the distributed node
  --sname "name"    Makes and assigns a short name to the distributed node
  --cookie "cookie" Sets a cookie for this distributed node
  --hidden          Makes a hidden node
  --werl            Uses Erlang's Windows shell GUI (Windows only)
  --detached        Starts the Erlang VM detached from console
  --remsh "name"    Connects to a node using a remote shell
  --dot-iex "path"  Overrides default .iex.exs file and uses path instead;
                    path can be empty, then no file will be loaded

** Options marked with (*) can be given more than once
** Options given after the .exs file or -- are passed down to the executed code
** Options can be passed to the VM using ELIXIR_ERL_OPTIONS or --erl
```

Όταν περνάμε την επιλογή `--help` στο IEx από τη γραμμή εντολών, μας δίνεται μια λίστα με όλες τις διαθέσιμες επιλογές.
Μπορούμε να δούμε ότι υπάρχουν οι επιλογές `--name` και `--sname` για τον ορισμό πληροφοριών στους κόμβους.
Ένας κόμβος είναι απλά μια ενεργή εικονική μηχανή Erlang η οποία χειρίζεται τις επικοινωνίες της, τη συλλογή σκουπιδιών της, το χρονοπρογραμματισμό επεξεργασίας της, τη μνήμη της και άλλα.
Ο κόμβος ονομάζεται **nonode@nohost** εξ' ορισμού.

```shell
$ iex --name learner@elixirschool.com

Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex(learner@elixirschool.com)> Node.self
:"learner@elixirschool.com"
```

Όπως μπορούμε να δούμε, ο κόμβος που τρέχουμε είναι ένα άτομο που ονομάζεται `:"learner@elixirschool.com"`.
Αν τρέχουμε ξανά την `Mnesia.create_schema([node()])`, θα δούμε ότι δημιούργησε έναν άλλο φάκελο που ονομάζεται **Mnesia.learner@elixirschool.com**.
Ο σκοπός του είναι αρκετά απλός.
Οι κόμβοι στην Erlang χρησιμοποιούνται για να συνδεθούν σε άλλους κόμβους και να μοιραστούν (και να διανέμουν) πληροφορίες και πόρους.
Αυτό δεν περιορίζεται στο ίδιο μηχάνημα και μπορεί να επικοινωνήσει μέσω LAN, μέσω του internet κ.α.

## Ξεκινώντας το Mnesia

Τώρα που έχουμε κατανοήσει τα βασικά και έχουμε ρυθμίσει τη βάση δεδομένων, είμαστε σε θέση να ξεκινήσουμε το σύστημα διαχείρησης βάσης δεδομένων με την εντολή ```Mnesia.start/0```.

```shell
iex> alias :mnesia, as: Mnesia
iex> Mnesia.create_schema([node()])
:ok
iex> Mnesia.start()
:ok
```

Η συνάρτηση `Mnesia.start/0` είναι ασύγχρονη.
Ξεκινάει την αρχικοποίηση των πινάκων που υπάρχουν ήδη και επιστρέφει το άτομο `:ok`.
Σε περίπτωση που πρέπει να κάνουμε κάτι στους υπάρχοντες πίνακες αμέσως αφού ξεκινήσουμε την Mnesia, πρέπει να καλέσουμε την συνάρτηση `Mnesia.wait_for_tables/2`.
Αυτό θα παγώσει την κλήση έως ότου οι πίνακες αρχικοποιηθούν.
Δείτε το παράδειγμα στον τομέα [Αρχικοποίηση και Μεταφορά δεδομένων](#data-initialization-and-migration).

Είναι σημαντικό να έχουμε στο μυαλό μας ότι η εκτέλεση ενός κατανεμημένου συστήματος με δύο ή περισσότερους κόμβους, η συνάρτηση `Mnesia.start/1` πρέπει να εκτελεστεί σε όλους τους κόμβους που λαμβάνουν μέρους.

## Δημιουργία Πινάκων

Η συνάρτηση `Mnesia.create_table/2` χρησιμοποιείται για τη δημιουργία πινάκων μέσα στη βάση δεδομένων μας.
Παρακάτω δημιουργούμε ένα πίνακα που ονομάζεται `Person` και μετά περνάμε μια λίστα λέξεων κλειδιά για να ορίσουμε το σχήμα του πίνακα.

```shell
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:atomic, :ok}
```

Ορίζουμε τις στήλες χρησιμοποιώντας τα άτομα `:id`, `:name`, και `:job`.
Το πρώτο άτομο (σε αυτή την περίπτωση το `:id`) είναι το πρωτεύον κλειδί.
Απαιτείται τουλάχιστον ένα ακόμα όρισμα.

Όταν εκτελέσουμε την `Mnesia.create_table/2`, θα επιστρέψει μια από τις ακόλουθες απαντήσεις:

 - `{:atomic, :ok}` αν η συνάρτηση εκτελεστεί με επιτυχία
 - `{:aborted, Reason}` αν η συνάρτηση αποτύχει

Συγκεκριμένα, αν ο πίνακας υπάρχει ήδη, ο λόγος θα είναι στη μορφή `{:already_exists, table}` έτσι αν προσπαθήσουμε να τον δημιουργήσουμε μια δεύτερη φορά, θα λάβουμε:

```elixir
iex> Mnesia.create_table(Person, [attributes: [:id, :name, :job]])
{:aborted, {:already_exists, Person}}
```

## Ο Λάθος Τρόπος

Πρώτα από όλα θα δούμε το λάθος τρόπο ανάγνωσης και εγγραφής σε ένα πίνακα Mnesia.
Αυτός γενικά θα πρέπει να αποφεύγεται καθώς η επιτυχία δεν είναι εγγυημένη, αλλά θα μας μάθει να είμαστε πιο άνετοι στην εργασία μας με το Mnesia.
Ας δούμε μερικές εγγραφές στον πίνακα μας **Person**.

```shell
iex> Mnesia.dirty_write({Person, 1, "Seymour Skinner", "Principal"})
:ok

iex> Mnesia.dirty_write({Person, 2, "Homer Simpson", "Safety Inspector"})
:ok

iex> Mnesia.dirty_write({Person, 3, "Moe Szyslak", "Bartender"})
:ok
```

... και για να ανακτήσουμε τις εγγραφές μπορούμε να χρησιμοποιήσουμε την `Mnesia.dirty_read/1`:

```shell
iex> Mnesia.dirty_read({Person, 1})
[{Person, 1, "Seymour Skinner", "Principal"}]

iex> Mnesia.dirty_read({Person, 2})
[{Person, 2, "Homer Simpson", "Safety Inspector"}]

iex> Mnesia.dirty_read({Person, 3})
[{Person, 3, "Moe Szyslak", "Bartender"}]

iex> Mnesia.dirty_read({Person, 4})
[]
```

Αν δοκιμάσουμε να εξετάσουμε μια εγγραφή που δεν υπάρχει η Mnesia θα ανταποκριθεί με μια άδεια λίστα.

## Συναλλαγές

Παραδοσιακά χρησιμοποιούμε τις **συναλλαγές** για να ενσωματώσουμε τις αναγνώσεις και εγγραφές στη βάση δεδομένων μας.
Οι συναλλαγές είναι ένα σημαντικό μέρος σχεδίασης ανεκτικών σε λάθη, υψηλά κατανεμημένων συστημάτων.
Στη Mnesia, *η συναλλαγή είναι ένας μηχανισμός με τον οποίο μια σειρά εργασιών της βάσης δεδομένων μπορεί να εκτελεστεί σαν ένα συναρτησιακό μπλοκ*.
Πρώτα δημιουργούμε μια ανώνυμη συνάρτηση, σε αυτή την περίπτωση την `data_to_write` και τότε την περνάμε στην `Mnesia.transaction`.

```shell
iex> data_to_write = fn ->
...>   Mnesia.write({Person, 4, "Marge Simpson", "home maker"})
...>   Mnesia.write({Person, 5, "Hans Moleman", "unknown"})
...>   Mnesia.write({Person, 6, "Monty Burns", "Businessman"})
...>   Mnesia.write({Person, 7, "Waylon Smithers", "Executive assistant"})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_write)
{:atomic, :ok}
```
Βασιζόμενοι σε αυτό το μήνυμα συναλλαγής, είμαστε σε θέση να υποθέσουμε ότι έχουμε γράψει τα δεδομένα μας στον πίνακα `Person`.
Ας χρησιμοποιήσουμε μια συναλλαγή για να διαβάσουμε από τη βάση δεδομένων για να βεβαιωθούμε.
Θα χρησιμοποιήσουμε τη `Mnesia.read/1` για να διαβάσουμε από τη βάση δεδομένων, αλλά ξανά μέσα από μια ανώνυμη συνάρτηση.

```shell
iex> data_to_read = fn ->
...>   Mnesia.read({Person, 6})
...> end
#Function<20.54118792/0 in :erl_eval.expr/5>

iex> Mnesia.transaction(data_to_read)
{:atomic, [{Person, 6, "Monty Burns", "Businessman"}]}
```

Σημειώστε ότι αν θέλετε να αναβαθμίσετε δεδομένα, πρέπει απλά να καλέσετε την `Mnesia.write/1` με το ίδιο κλειδί μιας υπάρχουσας εγγραφής.
Έτσι, για να αναβαθμίσετε την εγγραφή για τον Hans, μπορείτε να κάνετε το εξής:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.write({Person, 5, "Hans Moleman", "Ex-Mayor"})
...>   end
...> )
```

## Χρήση Δεικτών

Η Mnesia υποστηρίζει δείκτες σε στήλες όχι-κλειδιά και μπορούν να ερωτηθούν δεδομένα σε αυτούς τους δείκτες.
Έτσι, μπορούμε να προσθέσουμε ένα δείκτη στη στήλη `:job` του πίνακα `Person`:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:atomic, :ok}
```

Το αποτέλεσμα είναι παρόμοιο με αυτό που επιστρέφεται από την `Mnesia.create_table/2`:

 - `{:atomic, :ok}` αν η συνάρτηση εκτελέστηκε επιτυχώς
 - `{:aborted, Reason}` αν η συνάρτηση απέτυχε
 
Συγκεκριμένα, αν ο δείκτης υπάρχει ήδη, ο λόγος θα είναι της μορφής `{:already_exists, table, attribute_index}` έτσι αν προσπαθήσουμε να προσθέσουμε αυτό το δείκτη για δεύτερη φορά, θα πάρουμε:

```elixir
iex> Mnesia.add_table_index(Person, :job)
{:aborted, {:already_exists, Person, 4}}
```

Όταν ο δείκτης δημιουργηθεί επιτυχώς, μπορούμε να διαβάσουμε από αυτό και να λάβουμε μια λίστα από διευθυντές:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.index_read(Person, "Principal", :job)
...>   end
...> )
{:atomic, [{Person, 1, "Seymour Skinner", "Principal"}]}
```

## Ταίριασμα και επιλογή

Η Mnesia υποστηρίζει πολλύπλοκα ερωτήματα για την λήψη δεδομένων από ένα πίνακα στη μορφή του ταιριάσματος και των ad-hoc συναρτήσεων ερωτημάτων.

Η συνάρτηση `Mnesia.match_object/1` επιστρέφει όλες τις εγγραφές που ταιριάζουν στο δωσμένο πρότυπο.
Αν κάποια από τις στήλες του πίνακα έχει δείκτες, μπορεί να τους χρησιμοποιήσει για να κάνει το ερώτημα πιο αποδοτικό.
Χρησιμοποιήστε το ειδικό άτομο `:_` για να αναγνωρίσετε στήλες που δεν παίρνουν μέρος στο ταίριασμα.

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     Mnesia.match_object({Person, :_, "Marge Simpson", :_})
...>   end
...> )
{:atomic, [{Person, 4, "Marge Simpson", "home maker"}]}
```

Η συνάρτηση `Mnesia/select/2` σας επιτρέπει να ορίσετε ένα αυτοσχέδιο ερώτημα χρησιμοποιώντας οποιονδήποτε χειριστή ή συνάρτηση στη γλώσσα Elixir (ή στην Erlang).
Ας δούμε ένα παράδειγμα το οποίο επιλέγει όλες τις εγγραφές που έχουν κλειδί μεγαλύτερο του 3:

```elixir
iex> Mnesia.transaction(
...>   fn ->
...>     {% raw %}Mnesia.select(Person, [{{Person, :"$1", :"$2", :"$3"}, [{:>, :"$1", 3}], [:"$$"]}]){% endraw %}
...>   end
...> )
{:atomic, [[7, "Waylon Smithers", "Executive assistant"], [4, "Marge Simpson", "home maker"], [6, "Monty Burns", "Businessman"], [5, "Hans Moleman", "unknown"]]}
```

Ας το αποσυμπιέσουμε.
Το πρώτο όρισμα είναι ο πίνακας, `Person`, το δεύτερο όρισμα είναι της μορφής `{match, [guard], [result]}`:

- Το `match` είναι το ίδιο με αυτό που θα περνούσατε στη συνάρτηση `Mnesia.match_object/1`. Πάντως, σημειώστε τα ειδικά άτομα `:"#$n"` τα οποία ορίζουν παραμέτρους θέσης που χρησιμοποιούνται από το υπόλοιπο του ερωτήματος
- Η λίστα `guard` είναι μια λίστα από τούπλες που ορίζει τι συναρτήσεις προστασίας να εφαρμόσουν, σε αυτή την περίπτωση τη προεγκατεστημένη συνάρτηση `:>` με την πρώτη παράμετρο θέσης `:"$1"` και τη σταθερά `3` σαν ορίσματα
- Η λίστα `result` είναι η λίστα πεδίων που επιστρέφεται από το ερώτημα, στη μορφή των περαμέτρων θέσης του ειδικού ατόμου `:"$$"` για να αναφερθείτε σε όλα τα πεδία, έτσι θα μπορούσατε να χρησιμοποιήσετε το `[:"$1", :"$2"]` για να επιστρέψετε τα πρώτα δύο πεδία ή `[:"$$"]` για να επιστρέψετε όλα τα πεδία

Για περισσότερες λεπτορμέρειες, δείτε την [τεκμηρίωση Erlang Mnesia για τη συνάρτηση select/2](http://erlang.org/doc/man/mnesia.html#select-2).

## Αρχικοποίηση και μεταφορά δεδομένων

Σε κάθε λύση λογισμικού, έρχεται μια στιγμή που χρειάζεστε να αναβαθμίσετε το λογισμικό σας και να μεταφέρετε τα δεδομένα που είναι αποθηκευμένα στη βάση δεδομένων σας.
Για παράδειγμα, μπορεί να θέλουμε να προσθέσουμε μια στήλη `:age` στον πίνκακα μας `Person`  στην v2 της εφαρμογής μας.
Δεν μπορούμε να δημιουργήσουμε τον πίνακα `Person` εφόσον έχει δημιουργηθεί αλλά μπορούμε να τον μετατρέψουμε.
Για αυτό θα χρειαστεί να ξέρουμε πότε να τον μετατρέψουμε, το οποίο μπορούμε να κάνουμε όταν δημιουργούμε τον πίνακα.
Για να το κάνουμε αυτό, θα χρησιμοποιήσουμε την συνάρτηση `Mnesia.table_info/2` για να λάβουμε την τρέχουσα δομή του πίνακα και την `Mnesia.transforma_table/3` για να τον μεταμορφώσουμε στη νέα δομή.

Ο κώδικας παρακάτω το κάνει αυτό υλοποιώντας την παρακάτω λογική:

* Δημιουργεί τον πίνακα με τα ορίσματα της v2: `[:id, :name, :job, :age]`
* Χειρίζεται το αποτέλεσμα δημιουργίας:
    * `{:atomic, :ok}`: αρχικοποιεί τον πίνακα με τη δημιουργία δεικτών στις `:job` και `:age`
    * `{:aborted, {:already_exists, Person}}`: έλεγχει ποια ορίσματα υπάρχουν στον τρέχον πίνακα και δρα ανάλογα:
        * αν είναι στην λίστα v1 (`[:id, :name, :job]`), μετέτρεψε τον πίνακα δίνοντας σε όλους την ηλικία των 21 ετών και πρόσθεσε τον νέο δείκτη στο πεδίο `:age`
        * αν είναι στην λίστα v2, μην κάνεις τίποτα, είμαστε εντάξει
        * αν είναι κάτι άλλο, τερμάτισε

Αν κάνουμε οποιεσδήποτε ενέργειες σε υπάρχοντες πίνακες αμέσως μετά την αρχικοποίηση της Mnesia με την `Mnesia.start/0`, αυτοί οι πίνακες μπορεί να μην είναι ακόμα αρχικοποιημένοι και προσβάσιμοι.
Σε αυτή την περίπτωση, πρέπει να χρησιμοποιήσουμε την συνάρτηση [`Mnesia.wait_for_tables/2`](http://erlang.org/doc/man/mnesia.html#wait_for_tables-2).
Αυτή θα παγώσει την τρέχουσα διεργασία έως ότου οι πίνακες αρχικοποιηθούν ή έως έρθει το timeout.

Η συνάρτηση `Mnesia.transform_table/3` δέχεται σαν ορίσματα το όνομα του πίνακα, μια συνάρτηση που μετατρέπει μια εγγραφή από την παλιά στη νέα μορφή και μια λίστα των ορισμάτων.

```elixir
case Mnesia.create_table(Person, [attributes: [:id, :name, :job, :age]]) do
  {:atomic, :ok} ->
    Mnesia.add_table_index(Person, :job)
    Mnesia.add_table_index(Person, :age)
  {:aborted, {:already_exists, Person}} ->
    case Mnesia.table_info(Person, :attributes) do
      [:id, :name, :job] ->
        Mnesia.wait_for_tables([Person], 5000)
        Mnesia.transform_table(
          Person,
          fn ({Person, id, name, job}) ->
            {Person, id, name, job, 21}
          end,
          [:id, :name, :job, :age]
          )
        Mnesia.add_table_index(Person, :age)
      [:id, :name, :job, :age] ->
        :ok
      other ->
        {:error, other}
    end
end
```
