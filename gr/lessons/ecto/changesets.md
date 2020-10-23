---
version: 1.2.2
title: Σετ Αλλαγών
---

Για να μπορέσουμε νε εισάγουμε, αλλάξουμε, ή διαγράψουμε δεδομένα από τη βάση δεδομένων μας, οι συναρτήσεις `Ecto.Repo.insert/2`, `update/2` και `delete/2` απαιτούν ένα σετ αλλαγών σαν το πρώτο τους όρισμα. Αλλά τι είναι τα σετ αλλαγών;

Μια πολύ γνώριμη εργασία σε όλους τους προγραμματιστές είναι να ελέγχουν τα εισαγόμενα δεδομένα για πιθανά σφάλματα - θέλουμε να βεβαιωθούμε ότι τα δεδομένα είναι στη σωστή κατάσταση πριν προσπαθήσουμε να τα χρησιμοποιήσουμε για τους σκοπούς μας.

Το Ecto μας παρέχει μια πλήρη λύση για την εργασία με αλλαγές δεδομένων στη μορφή της ενότητας και δομής δεδομένων `Changeset`.
Σε αυτό το μάθημα θα εξερευνήσουμε τη λειτουργικότητα και θα μάθουμε πως να επιβεβαιώνουμε την ορθότητα των δεδομένων, πριν τα οριστικοποιήσουμε στη βάση δεδομένων.

{% include toc.html %}

## Δημιουργώντας το πρώτο μας σετ αλλαγών

Ας δούμε μια κενή δομή `%Changeset{}`:

```elixir
iex> %Ecto.Changeset{}
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```

Όπως θα δείτε, έχει μερικά πιθανόν χρήσιμα πεδία, αλλά είναι όλα άδεια.

Για να είναι πραγματικά χρήσιμο ένα σετ αλλαγών, όταν το δημιουργήσουμε θα πρέπει να παρέχουμε ένα σχεδιάγραμμα από τη μορφή των δεδομένων μας.
Υπάρχει καλύτερο σχεδιάγραμμα για τα δεδομένα μας από το σχήμα που δημιουργήσαμε πριν και ορίζει τα πεδία και τους τύπους τους;

Ας χρησιμοποιήσουμε το σχήμα `Friends.Person` από το προηγούμενο μάθημα:

```elixir
defmodule Friends.Person do
  use Ecto.Schema

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Για να δημιουργήσουμε ένα σετ αλλαγών χρησιμοποιώντας το σχήμα `Person`, θα χρειαστούμε την `Ecto.Changeset.cast/3`:

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{}, [:name, :age])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

Η πρώτη παράμετρος είναι τα αρχικά δεδομένα - μια αρχική δομή `%Friends.Person{}` σε αυτή την περίπτωση.
Το Ecto είναι αρκετά έξυπνο να βρει το σχήμα βασιζόμενο μόνο στην ίδια τη δομή.
Στη συνέχεια βρίσκονται οι αλλαγές που θέλουμε να κάνουμε - εδώ απλά ένας άδειος χάρτης.
Η τρίτη παράμετρος είναι αυτή που κάνει την `cast/3` ξεχωριστή: είναι μια λίστα πεδίων που επιτρέπονται να περάσουν, το οποίο μας δίνει τη δυνατότητα να ελέγξουμε τι πεδία μπορούν να αλλαχθούν και να προστατεύσουμε τα υπόλοιπα.

```elixir
iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [:name, :age])
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Jack"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>

iex> Ecto.Changeset.cast(%Friends.Person{name: "Bob"}, %{"name" => "Jack"}, [])
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Person<>,
 valid?: true>
```

Μπορείτε να δείτε πως το νέο όνομα αγνοήθηκε τη δεύτερη φορά, όταν δεν του το επιτρέψαμε.

Μια εναλλακτική της `cast/3` είναι η συνάρτηση `change/2`, η οποία δεν έχει τη δυνατότητα να φιτλράρει αλλαγές σαν την `cast/3`.
Είναι χρήσιμη όταν εμπιστεύεστε την πηγή που κάνει της αλλαγές ή όταν εργάζεστε με δεδομένα χειροκίνητα.

Τώρα μπορούμε να δημιουργήσουμε σετ αλλαγών, αλλά από τη στιγμή που δεν έχουμε επιβεβαίωση, όλες οι αλλαγές στο όνομα του ατόμου θα γίνουν αποδεκτές, έτσι μπορούμε να καταλήξουμε με ένα άδειο όνομα:

```elixir
iex> Ecto.Changeset.change(%Friends.Person{name: "Bob"}, %{name: ""})
#Ecto.Changeset<
  action: nil,
  changes: %{name: ""},
  errors: [],
  data: #Friends.Person<>,
  valid?: true
>
```

Το Ecto λέει ότι το σετ αλλαγών είναι αποδεκτό, αλλά στην πραγματικότητα δεν θέλουμε να επιτρέψουμε άδεια ονόματα. Ας το διορθώσουμε αυτό!

## Επικυρώσεις

Το Ecto για να μας βοηθήσει έρχεται με έναν αριθμό εσωτερικών συναρτήσεων για επικυρώσεις.

Θα χρησιμοποιήσουμε την ενότητα `Ecto.Changeset` αρκετά, έτσι ας εισάγουμε την `Ecto.Changeset` στην ενότητα μας `person.ex`, η οποία επίσης περιέχει το σχήμα μας:

```elixir
defmodule Friends.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :age, :integer, default: 0
  end
end
```

Τώρα μπορούμε να χρησιμοποιήσουμε απευθείας τη συνάρτηση `cast/3`.

Είναι σύνηθες να έχουμε μια ή περισσότερες συναρτήσεις δημιουργίας σετ αλλαγών για ένα σχήμα.
Ας φτιάξουμε μια που δέχεται μια δομή, ένα χάρτη αλλαγών και επιστρέφει ένα σετ αλλαγών:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
end
```

Τώρα μπορούμε να βεβαιωθούμε ότι το `name` είναι πάντα παρόν:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name])
  |> validate_required([:name])
end
```

Όταν καλούμε τη συνάρτηση `Friends.Person.changeset/2` και της περνάμε ένα άδειο όνομα, το σετ αλλαγών δεν θα είναι πλέον έγκυρο, και ακόμα θα περιέχει ένα πολύ χρήσιμο μήνυμα λάθους.
Σημείωση: μην ξεχνάτε να τρέχετε την εντολή `recompile()` όταν εργάζεστε στο `iex`, διαφορετικά δεν θα έχει τις αλλαγές που κάνατε στον κώδικα.

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => ""})
%Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [name: {"can't be blank", [validation: :required]}],
  data: %Friends.Person<>,
  valid?: false
>
```

Αν προσπαθήσετε να τρέξετε την `Repo.insert(changeset)` με το παραπάνω σετ αλλαγών, θα πάρετε πίσω ένα `{:error, changeset}` με το ίδιο σφάλμα, ώστε να μην χρειαστεί να ελέγχετε το `changeset.valid?` κάθε φορά.
Είναι πιο εύκολο να προσπαθήσετε να κάνετε μια εισαγωγή, αλλαγή ή διαγραφή και να επεξεργαστείτε το σφάλμα αργότερα αν υπάρχει κάποιο.

Πέρα από την `validate_required/2`, υπάρχει επίσης η `validate_length/3`, η οποία δέχεται μερικές επιπλέον επιλογές:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
end
```

Μπορείτε να δοκιμάσετε να μαντέψετε το αποτέλεσμα αν περάσουμε ένα όνομα που δέχεται έναν μόνο χαρακτήρα!

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "A"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "A"},
  errors: [
    name: {"should be at least %{count} character(s)",
     [count: 2, validation: :length, kind: :min, type: :string]}
  ],
  data: %Friends.Person<>,
  valid?: false
>
```

Μπορεί να εκπλαγείτε με το ότι το μήνυμα σφάλματος περιέχει το μυστηριώδες `%{count}` - αυτό υπάρχει για να βοηθήσει στη μετάφραση σε άλλες γλώσσες. Αν θέλετε να προβάλετε τα σφάλματα απευθείας στο χρήστη, θα πρέπει να τα κάνετε πιο αναγνώσιμα χρησιμοποιώντας την [`traverse_errors/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#traverse_errors/2) - ρίξτε μια ματιά στο παράδειγμα που δίνεται στα έγγραφα.

Μερικές από τις υπόλοιπες επικυρώσεις που παρέχονται στην `Ecto.Changeset` είναι:

+ validate_acceptance/3
+ validate_change/3 & /4
+ validate_confirmation/3
+ validate_exclusion/4 & validate_inclusion/4
+ validate_format/4
+ validate_number/3
+ validate_subset/4

Μπορείτε να βρείτε την πλήρη λίστα με λεπτομέρεις πως να τις χρησιμοποιήσετε [εδώ](https://hexdocs.pm/ecto/Ecto.Changeset.html#summary).

### Χειροποίητες Επικυρώσεις

Παρόλο που οι παρεχόμενες επικυρώσεις καλύπτουν ένα ευρύ φάσμα περιπτώσεων, μπορεί να χρειαστείτε κάτι διαφορετικό.

Κάθε συνάρτηση τύπου `validate_` που χρησιμοποιήσαμε ως τώρα  δέχεται και επιστρέφει μια δομή `%Ecto.Changeset{}`, έτσι μπορούμε πανεύκολα να φτιάξουμε τη δική μας.

Για παράδειγμα, μπορούμε να βεβαιωθούμε ότι μόνο ονόματα φανταστικών χαρακτήρων επιτρέπονται:

```elixir
@fictional_names ["Black Panther", "Wonder Woman", "Spiderman"]
def validate_fictional_name(changeset) do
  name = get_field(changeset, :name)

  if name in @fictional_names do
    changeset
  else
    add_error(changeset, :name, "is not a superhero")
  end
end
```

Παραπάνω εισηγάγαμε δύο νέες βοηθητικές συναρτήσεις: τις [`get_field/3`](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) και [`add_error/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4).
Η λειτουργία τους είναι αυτονόητη, αλλά σας προτρέπουμε να τους ρίξετε μια ματιά στους συνδέσμους των εγγράφων.

Είναι μια καλή πρακτική να επιστρέφετε πάντα μια δομή `%Ecto.Changeset{}`, ώστε να μπορείτε να χρησιμοποιείτε τον τελεστή `|>` και να κάνετε ευκολότερη την προσθήκη περισσότερων επικυρώσεων αργότερα:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> validate_required([:name])
  |> validate_length(:name, min: 2)
  |> validate_fictional_name()
end
```

```elixir
iex> Friends.Person.changeset(%Friends.Person{}, %{"name" => "Bob"})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Bob"},
  errors: [name: {"is not a superhero", []}],
  data: %Friends.Person<>,
  valid?: false
>
```

Θαυμάσια, δουλεύει! Ωστόσο, δεν υπήρχε λόγος να υλοποιήσουμε αυτή τη συνάρτηση μόνοι μας - μπορούσαμε στη θέση της να χρησιμοποιήσουμε τη συνάρτηση `validate_inclusion/4`. Παρόλα αυτά μπορείτε να δείτε πως να προσθέσετε τα δικά σας σφάλματα το οποίο λογικά θα σας φανεί χρήσιμο.

## Προσθέτοντας αλλαγές προγραμματιστικά

Μερικές φορές θα θέλετε να εισάγετε αλλαγές σε ένα σετ αλλαγών χειροκίνητα. Η βοηθητική συνάρτηση `put_change/3` υπάρχει για αυτό το λόγο.

Αντί να κάνουμε το πεδίο `name` απαραίτητο, ας επιτρέψουμε τους χρήστες μας να εγγραφούν χωρίς όνομα, και ας τους ονομάσουμε "Ανώνυμους".
Η συνάρτηση που χρειαζόμαστε δείχνει οικεία - δέχεται και επιστρέφει ένα σετ αλλαγών, ακριβώς όπως η `validate_fictional_name/1` που δείξαμε νωρίτερα:

```elixir
def set_name_if_anonymous(changeset) do
  name = get_field(changeset, :name)

  if is_nil(name) do
    put_change(changeset, :name, "Anonymous")
  else
    changeset
  end
end
```

Μπορούμε να ορίσουμε το όνομα ενός χρήστη σαν "Ανώνυμος" μόνο όταν κάνουν εγγραφή στην εφαρμογή μας. Για να το κάνουν αυτό, θα δημιουργήσουμε μια νέα συνάρτηση δημιουργίας σετ αλλαγών:

```elixir
def registration_changeset(struct, params) do
  struct
  |> cast(params, [:name, :age])
  |> set_name_if_anonymous()
end
```

Τώρα δεν χρειάζεται να περάσουμε ένα `name` και το `Ανώνυμος` θα οριστεί αυτόματα όπως αναμένεται:

```elixir
iex> Friends.Person.registration_changeset(%Friends.Person{}, %{})
%Ecto.Changeset<
  action: nil,
  changes: %{name: "Anonymous"},
  errors: [],
  data: %Friends.Person<>,
  valid?: true
>
```

Η ύπαρξη συναρτήσεων δημιουργίας σετ αλλαγών που έχουν μία συγκεκριμένη αρμοδιότητα (όπως η `registration_changeset/2`) είναι συνηθισμένη - μερικές φορές χρειαζόμαστε την ελαστικότητα να εκτελούμε συγκεκριμένες επικυρώσεις ή να φιλτράρουμε συγκεκριμένες παραμέτρους.
Η συνάρτηση παραπάνω θα μπορούσε να χρησιμοποιηθεί τότε σε μια βοηθητική συνάρτηση `sign_up/1` κάπου αλλού:

```elixir
def sign_up(params) do
  %Friends.Person{}
  |> Friends.Person.registration_changeset(params)
  |> Repo.insert()
end
```

## Συμπέρασμα

Υπάρχουν αρκετές χρήσεις και λειτουργίες που δεν καλύψαμε σε αυτό το μάθημα, όπως τα [μη σχηματικά σετ αλλαγών](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-schemaless-changesets) που μπορείτε να χρησιμοποιήσετε για να επικυρώσετε _οποιαδήποτε_ δεδομένα, ή να αντιμετωπίσετε παρενέργειες του σετ αλλαγών ([`prepare_changes/2`](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2)) ή να εργαστείτε με ενώσεις και ενσωματώσεις.
Μπορεί να τις καλύψουμε μελλοντικά σε ένα πιο προχωρημένο μάθημα, αλλά προς το παρών σας ενθαρύνουμε να εξερευνήσετε την [τεκμηρίωση του Σετ Αλλαγών του Ecto](https://hexdocs.pm/ecto/Ecto.Changeset.html) για περισσότερες πληροφορίες.
