%{
  version: "1.2.0",
  title: "Δημιουργώντας Ερωτήματα",
  excerpt: """
  
  """
}
---

Σε αυτό το μάθημα, θα συνεχίσουμε να χτίζουμε την εφαρμογή μας `Friends` και τον τομέα καταλογράφησης ταινιών που ορίσαμε στο [προηγούμενο μάθημα](./associations).

## Φέρνοντας Εγγραφές με την `Ecto.Repo`

Θυμηθείτε ότι ένα "αποθετήριο" στο Ecto συνδέεται σε μια αποθήκη δεδομένων σαν την βάση δεδομένων Postgres μας.
Όλες οι επικοινωνίες με τη βάση δεδομένων θα πραγματοποιηθούν με τη χρήση αυτού του αποθετηρίου.

Μπορούμε να υλοποιήσουμε απλά ερωτήματα απευθείας στο `Friends.Repo` μας με τη βοήθεια λίγων συναρτήσεων.

### Φέρνοντας Εγγραφές με το ID

Μπορούμε να χρησιμοποιήσουμε τη συνάρτηση `Repo.get/3` για να φέρουμε μια εγγραφή από τη βάση δεδομένων μας δοθέντος του ID.
Αυτή η συνάρτηση απαιτεί δύο ορίσματα: μια "ερωτηθείσα" δομή δεδομένων και το ID μιας εγγραφής για να ληφθεί από τη βάση δεδομένων.
Επιστρέφει μια δομή που περιγράφει την εγγραφή που βρέθηκε, αν βρέθηκε.
Επιστρέφει `nil` αν δεν βρέθηκε καμμία εγγραφή.

Ας ρίξουμε μια ματιά σε ένα παράδειγμα.
Παρακάτω, ας πάρουμε μια ταινία με ID 1:

```elixir
iex> alias Friends.{Repo, Movie}
iex> Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Παρατηρήστε ότι το πρώτο όρισμα που δίνουμε στην `Repo.get/3` είναι η ενότητά μας `Movie`.
Η `Movie` είναι "ερωτηθείσα" επειδή η ενότητα χρησιμοποιεί την ενότητα `Ecto.Schema` και ορίζει ένα σχήμα για τη δομή δεδομένων της.
Αυτό δίνει στη `Movie` πρόσβαση στο πρωτόκολλο `Ecto.Queryable`.
Το πρωτόκολλο αυτό μετατρέπει μια δομή δεδομένων σε μια `Ecto.Query`.
Τα ερωτήματα Ecto χρησιμοποιούνται στη λήψη δεδομένων από ένα αποθετήριο.
Περισσότερα στα ερωτήματα μετά.

### Λήψη εγγραφών βάσει χαρακτηριστικών

Μπορούμε επίσης να λάβουμε εγγραφές που ταιριάζουν σε κάποια κριτήρια με τη συνάρτηση `Repo.get_by/3`.
Αυτή η συνάρτηση απαιτεί δύο ορίσματα: την "ερωτηθείσα" δομή δεδομένων και τους όρους με τους οποίους θέλουμε να δημιουργήσουμε ερώτημα.
Η `Repo.get_by/3` επιστρέφει ένα μοναδικό αποτέλεσμα από το αποθετήριο.
Ας δούμε ένα παράδειγμα:

```elixir
iex> Repo.get_by(Movie, title: "Ready Player One")
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Αν θέλουμε να γράψουμε πιο περίπλοκα ερωτήματα, η αν θέλουμε να επιστρέψουμε _όλες_ τις εγγραφές που ικανοποιούν μια ορισμένη συνθήκη, πρέπει να χρησιμοποιήσουμε την ενότητα `Ecto.Query`.

## Γράφοντας ερωτήματα με την `Ecto.Query`

Η ενότητα `Ecto.Query` μας παρέχει μία DSL ερωτημάτων (γλώσσα ειδική σε τομέα) την οποία μπορούμε να χρησιμοποιήσουμε για να λάβουμε δεδομένα από το αποθετήριο της εφαρμογής.

### Ερωτήματα βασισμένα σε λέξεις κλειδιά με την `Ecto.Query.from/2`

Μπορούμε να δημιουργήσουμε ένα ερώτημα με τη μακροεντολή `Ecto.Query.from/2`.
Αυτή η συνάρτηση δέχεται δύο ορίσματα: μια έκφραση και μια προαιρετική λίστα λέξεων κλειδιά.
Ας δημιουργήσουμε το πιο απλό ερώτημα για να επιλέξουμε όλες τις ταινίες από το αποθετήριό μας:

```elixir
iex> import Ecto.Query
iex> query = from(Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

Για να εκτελέσουμε το ερώτημά μας, θα χρησιμοποιήσουμε τη συνάρτηση `Repo.all/2`.
Αυτή η συνάρτηση δέχεται ένα απαραίτητο όρισμα, ένα ερώτημα Ecto και επιστρέφει όλες τις εγγραφές που ισχύουν για τις προυποθέσεις του ερωτήματος.

```elixir
iex> Repo.all(query)

14:58:03.187 [debug] QUERY OK source="movies" db=1.7ms decode=4.2ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

#### Λυμένα ερωτήματα με τη `from`

Από το παραπάνω παράδειγμα λείπουν τα πιο διασκεδαστικά μέρη των ερωτημάτων SQL.
Συχνά θέλουμε να δημιουργούμε ερωτήματα μόνο για συγκεκριμένα πεδία ή να φιλτράρουμε εγγραφές με κάποια συνθήκη.
Ας πάρουμε τα πεδία `title` και `tagline` όλων των ταινιών που έχουν σαν τίτλο το "Ready Player One":

```elixir
iex> query = from(Movie, where: [title: "Ready Player One"], select: [:title, :tagline])
#Ecto.Query<from m0 in Friends.Movie, where: m0.title == "Ready Player One",
 select: [:title, :tagline]>

iex> Repo.all(query)
SELECT m0."title", m0."tagline" FROM "movies" AS m0 WHERE (m0."title" = 'Ready Player One') []
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    id: nil,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Σημειώστε ότι η επιστρεφόμενη δομή έχει μόνο ορισμένα τα πεδία `tagline` και `title` - αυτό είναι το αποτέλεσμα του μέρους της `select` μας.

Ερωτήματα σαν και αυτό ονομάζονται *λυμένα* επειδή είναι αρκετά απλά ώστε να μην απαιτούν δεσίματα.

#### Δεσίματα στα ερωτήματα

Ως τώρα χρησιμοποιούσαμε μια ενότητα που υλοποιεί το πρωτόκολλο `Ecto.Queryable` (πχ: `Movie`) σαν το πρώτο όρισμα για τη μακροεντολή `from`.
Ωστόσο, μπορούμε να χρησιμοποιήσουμε τις εκφράσεις `in` ως εξής:

```elixir
iex> query = from(m in Movie)
#Ecto.Query<from m0 in Friends.Movie>
```

Σε τέτοιες περιπτώσεις, καλούμε τη μεταβλητή `m` *δέσιμο*.
Τα δεσίματα είναι εξαιρετικά χρήσιμα, επειδή μας επιτρέπουν να αναφερόμαστε στις ενότητες σε άλλα μέρη του ερωτήματος.
Ας επιλέξουμε τους τίτλους από όλες τις ταινίες που έχουν `id` μικρότερο του `2`:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: m.title)
#Ecto.Query<from m0 in Friends.Movie, where: m0.id < 2, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 WHERE (m0."id" < 2) []
["Ready Player One"]
```

Το πιο σημαντικό πράγμα εδώ είναι πως η έξοδος από το ερώτημα άλλαξε.
Χρησιμοποιώντας μια *έκφραση* με ένα δέσιμο στο μέρος της `select:` μας επιτρέπει να ορίζουμε ακριβώς τον τρόπο που επιστρέφονται τα επιλεγμένα πεδία.
Μπορούμε να ορίσουμε μια τούπλα για παράδειγμα:

```elixir
iex> query = from(m in Movie, where: m.id < 2, select: {m.title})

iex> Repo.all(query)
[{"Ready Player One"}]
```

Είναι καλή ιδέα να να ξεκινάμε πάντα με ένα απλό ερώτημα χωρίς δεσίματα και να βάλουμε ένα δέσιμο όταν χρειαστεί να αναφερθούμε στη δομή δεδομένων μας.
Περισσότερα για τα δεσίματα στα ερωτήματα μπορείτε να δείτε στην [Τεκμηρίωση του Ecto](https://hexdocs.pm/ecto/Ecto.Query.html#module-query-expressions)


### Ερωτήματα βασισμένα σε μακροεντολές

Στα παραδείγματα πιο πάνω χρησιμοποιήσαμε λέξεις κλειδί όπως οι `select:` και `where:` μέσα στη μακροεντολή `from` για να χτίσουμε ένα ερώτημα - αυτά ονομάζονται *ερωτήματα βασισμένα σε λέξεις κλειδιά*.
Υπάρχει πάντως και ένας άλλος τρόπος να χτίσουμε ερωτήματα - τα ερωτήματα βασισμένα σε μακροεντολές.
Το Ecto παρέχει μακροεντολές για κάθε λέξη κλειδί, όπως η `select/3` ή η `where/3`.
Κάθε μακροεντολή δέχεται μια *ερωτήσιμη* τιμή, *μια σαφή λίστα δεσιμάτων* και την ίδια έκφραση που θα παρείχατε στην αντίστοιχη λέξη κλειδί:

```elixir
iex> query = select(Movie, [m], m.title)
#Ecto.Query<from m0 in Friends.Movie, select: m0.title>

iex> Repo.all(query)
SELECT m0."title" FROM "movies" AS m0 []
["Ready Player One"]
```

Το καλό με τις μακροεντολές έιναι ότι δουλεύουν πολύ καλά με τους σωλήνες:

```elixir
iex> Movie \
...>  |> where([m], m.id < 2) \
...>  |> select([m], {m.title}) \
...>  |> Repo.all
[{"Ready Player One"}]
```

Σημειώστε ότι για να συνεχίσουμε να γράφουμε μετά τη νέα γραμμή στο τερματικό, θα πρέπει να χρησιμοποιήσουμε το χαρακτήρα `\`.

### Χρήση της `where` με Παρεμβαλόμενες Tιμές

Για να μπορέσουμε να χρησιμοποιήσουμε παρεμβαλόμενες τιμές ή εκφράσεις Elixir στα στις προτάσεις where, πρέπει να χρησιμοποιήσουμε τον τελεστή πινέζας `^`.
Αυτό μας επιτρέπει να κρατήσουμε μια τιμή σε μια μεταβλητή και να αναφερόμαστε σε αυτή την καρφιτσωμένη τιμή, αντί να βάλουμε νέα τιμή σε αυτή τη μεταβλητή.

```elixir
iex> title = "Ready Player One"
"Ready Player One"
iex> query = from(m in Movie, where: m.title == ^title, select: m.tagline)
%Ecto.Query<from m in Friends.Movie, where: m.title == ^"Ready Player One",
 select: m.tagline>
iex> Repo.all(query)

15:21:46.809 [debug] QUERY OK source="movies" db=3.8ms
["Something about video games"]
```

### Λήψη της Πρώτης και Τελευταίας Εγγραφής

Μπορούμε να πάρουμε την πρώτη και τελευταία εγγραφή από ένα αποθετήριο χρησιμοποιώντας τις συναρτήσεις `Ecto.Query.first/2` και `Ecto.Query.last/2`.

Αρχικά, θα γράψουμε μία έκφραση ερωτήματος χρησιμοποιώντας τη συνάρτηση `first/2`:

```elixir
iex> first(Movie)
#Ecto.Query<from m0 in Friends.Movie, order_by: [asc: m0.id], limit: 1>
```

Τότε θα περάσουμε το ερώτημά μας στη συνάρτηση `Repo.one/2` για να πάρουμε το αποτέλεσμα:

```elixir
iex> Movie |> first() |> Repo.one()

SELECT m0."id", m0."title", m0."tagline" FROM "movies" AS m0 ORDER BY m0."id" LIMIT 1 []
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: #Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: #Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: #Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Η συνάρτηση `Ecto.Query.last/2` χρησιμοποιείται με τον ίδιο τρόπο:

```elixir
iex> Movie |> last() |> Repo.one()
```

## Ζητώντας Συσχετισμένα δεδομένα

### Προφόρτωση

Για να μπορέσουμε να έχουμε πρόσβαση σε συσχετιζόμενες εγγραφές στις οποίες μας δίνουν πρόσβαση οι μακροεντολές `belongs_to`, `has_many`, και `has_one`, πρέπει να _προφορτώσουμε_ τα συσχετιζόμενα σχήματα.

Ας ρίξουμε μια ματιά στο τι συμβαίνει όταν προσπαθήσουμε να ρωτήσουμε μια ταινία για τους συσχετιζόμενους ηθοποιούς της:

```elixir
iex> movie = Repo.get(Movie, 1)
iex> movie.actors
%Ecto.Association.NotLoaded<association :actors is not loaded>
```

_Δεν_ μπορούμε να έχουμε πρόσβαση στους συσχετιζόμενους χαρακτήρες αν δεν τους προφορτώσουμε.
Υπάρχουν μερικοί διαφορετικοί τρόποι να προφορτώσουμε εγγραφές με το Ecto.

#### Προφόρτωση με Δύο Ερωτήματα

Το παρακάτω ερώτημα θα προφορτώσει τις συσχετιζόμενες εγγραφές σε ένα _ξεχωριστό_ ερώτημα.

```elixir
iex> Repo.all(from m in Movie, preload: [:actors])

13:17:28.354 [debug] QUERY OK source="movies" db=2.3ms queue=0.1ms
13:17:28.357 [debug] QUERY OK source="actors" db=2.4ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Μπορούμε να δούμε ότι η παραπάνω γραμμή κώδικα έτρεξε _δύο_ ερωτήματα στη βάση δεδομένων.
Ένα για όλες τις ταινίες, και ένα ακόμα για όλους τους ηθοποιούς με τα σχετικά IDs ταινιών.

#### Προφόρτωση με Ένα Ερώτημα

Μπορούμε να μειώσουμε τα ερωτήματα στη βάση δεδομένων μας με το παρακάτω:

```elixir
iex> query = from(m in Movie, join: a in assoc(m, :actors), preload: [actors: a])
iex> Repo.all(query)

13:18:52.053 [debug] QUERY OK source="movies" db=3.7ms
[
  %Friends.Movie{
    __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
    actors: [
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 1,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Tyler Sheridan"
      },
      %Friends.Actor{
        __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
        id: 2,
        movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
        name: "Gary"
      }
    ],
    characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
    distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
    id: 1,
    tagline: "Something about video games",
    title: "Ready Player One"
  }
]
```

Αυτό μας επιτρέπει να εκτελέσουμε μόνο μια κλήση στη βάση δεδομένων.
Επίσης έχει το πλεονέκτημα ότι μας επιτρέπει να επιλέξουμε και να φιλτράρουμε τις ταινίες και τους συσχετιζόμενους ηθοποιούς στο ίδιο ερώτημα.
Για παράδειγμα, αυτή η προσέγγιση μας επιτρέπει να δημιουργήσουμε ένα ερώτημα για όλες τις ταινίες όπου οι συσχετιζόμενοι ηθοποιοί πληρούν κάποιες προυποθέσεις με τη χρήση δηλώσεων `join`.
Κάτι σαν αυτό:

```elixir
Repo.all from m in Movie,
  join: a in assoc(m, :actors),
  where: a.name == "John Wayne",
  preload: [actors: a]
```

Περισσότερα στις δηλώσεις join σε λίγο.

#### Προφόρτωση Ληφθέντων Εγγραφών

Μπορούμε επίσης να προφορτώσουμε τα συσχετιζόμενα σχήματα εγγραφών που έχουν ήδη ερωτηθεί από τη βάση δεδομένων.

```elixir
iex> movie = Repo.get(Movie, 1)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>, # actors are NOT LOADED!!
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
iex> movie = Repo.preload(movie, :actors)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    },
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ], # actors are LOADED!!
  characters: [],
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Τώρα μπορούμε να ρωτήσουμε μια ταινία για τους ηθοποιούς της:

```elixir
iex> movie.actors
[
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 1,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Tyler Sheridan"
  },
  %Friends.Actor{
    __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
    id: 2,
    movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
    name: "Gary"
  }
]
```

### Χρησιμοποιώντας Δηλώσεις Join

Μπορούμε να εκτελέσουμε ερωτήματα που περιλαμβάνουν δηλώσεις join με τη βοήθεια της συνάρτησης `Ecto.Query.join/5`.

```elixir
iex> alias Friends.Character
iex> query = from m in Movie,
              join: c in Character,
              on: m.id == c.movie_id,
              where: c.name == "Wade Watts",
              select: {m.title, c.name}
iex> Repo.all(query)
15:28:23.756 [debug] QUERY OK source="movies" db=5.5ms
[{"Ready Player One", "Wade Watts"}]
```

Η έκφραση `on` μπορεί επίσης να χρησιμοποιήσει μια λίστα λέξεων κλειδιά:

```elixir
from m in Movie,
  join: c in Character,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Στο παραπάνω παράδειγμα, συνδεόμαστε σε ένα σχήμα Ecto, `m in Movie`.
Μπορούμε επίσης να συνδεθούμε σε ένα ερώτημα Ecto.
Ας πούμε ότι ο πίνακας ταινιών μας έχει μια στήλη `stars`, όπου αποθηκεύουμε τη βαθμολογία σε αστέρια της ταινίας, ένας αριθμός από το 1 έως το 5.

```elixir
movies = from m in Movie, where: [stars: 5]
from c in Character,
  join: ^movies,
  on: [id: c.movie_id], # keyword list
  where: c.name == "Wade Watts",
  select: {m.title, c.name}
```

Η DSL ερωτημάτων του Ecto είναι ένα πολύ ισχυρό εργαλείο που μας παρέχει ότι χρειαζόμαστε για να χτίσουμε ακόμα περισσότερο περίπλοκα ερωτήματα στη βάση δεδομένων.
Με αυτή την εισαγωγή σας παρέχουμε τα βασικά δομικά στοιχεία για να ξεκινήσετε τα ερωτήματά σας.
