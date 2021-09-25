---
version: 1.2.1
title: Συσχετισμοί
---

Σε αυτό τον τομέα θα μάθουμε πως να χρησιμοποιήσουμε το Ecto για να ορίσουμε και να εργαστούμε με συσχετισμούς ανάμεσα στα σχήματά μας.

{% include toc.html %}

## Στήσιμο

Θα ξεκινήσουμε με την ίδια εφαρμογή `Friends` από τα προηγούμενα μαθήματα.
Μπορείτε να δείτε το στήσιμο [εδώ](../basics) για μια γρήγορη ανασκόπηση.

## Τύποι Συσχετισμών

Υπάρχουν τρεις τύποι συσχετισμών που μπορούμε να ορίσουμε μεταξύ των σχημάτων μας.
Θα δούμε τι είναι και πως να υλοποιήσουμε κάθε τύπο σχέσης.

### Ανήκει σε / Έχει πολλά


Θα προσθέσουμε μερικές νέες οντότητες στην εφαρμογή μας Friends ώστε να μπορέσουμε να καταχωρήσουμε τις αγαπημένες μας ταινίες.
Θα ξεκινήσουμε με δύο σχήματα: Τα `Movie` και `Character`.
Θα υλοποιήσουμε μια σχέση "έχει πολλά/ανήκει σε" ανάμεσα σε αυτά τα δύο σχήματα: Μια ταινία έχει πολλούς χαρακτήρες και ένας χαρακτήρας ανήκει σε μια ταινία.

#### Η Μετατροπή για το Έχει πολλά

Ας δημιουργήσουμε μια μετατροπή για την `Movie`:

```console
mix ecto.gen.migration create_movies
```

Ανοίξτε το πρόσφατα δημιουργημένο αρχείο μετατροπής και ορίστε τη συνάρτηση `change` ώστε να δημιουργήσετε τον πίνακα `movies` με μερικά χαρακτηριστικά:

```elixir
# priv/repo/migrations/*_create_movies.exs
defmodule Friends.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :title, :string
      add :tagline, :string
    end
  end
end
```

#### Το σχήμα για το Έχει πολλά

Θα προσθέσουμε ένα σχήμα που ορίζει τη σχέση "έχει πολλά" ανάμεσα στις ταινίες και τους χαρακτήρες της.

```elixir
# lib/friends/movie.ex
defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
  end
end
```

Η μακροεντολή `has_many/3` δεν προσθέτει τίποτα στην ίδια τη βάση δεδομένων.
Αυτό που κάνει είναι να χρησιμοποιεί το ξένο κλειδί στο συσχετισμένο σχήμα, `characters` ώστε να κάνει διαθέσιμους τους σχετικούς χαρακτήρες της ταινίας.
Αυτό είναι που θα μας δώσει τη δυνατότητα να καλέσουμε την `movie.characters`.

#### Η Μετατροπή για την Ανήκει σε

Τώρα είμαστε έτοιμοι να χτίσουμε τη μετατροπή και το σχήμα για το `Character`.
Ένας χαρακτήρας ανήκει σε μια ταινία, έτσι θα ορίσουμε μια μετατροπή και ένα σχήμα που ορίζει αυτή τη σχέση.

Αρχικά, δημιουργήστε τη μετατροπή:

```console
mix ecto.gen.migration create_characters
```

Για να ορίσουμε ότι ένας χαρακτήρας ανήκει σε μια ταινία, θα χρειαστούμε ο πίνακας `characters` να έχει μια στήλη `movie_id`.
Θέλουμε αυτή η στήλη να λειτουργεί σαν ξένο κλειδί.
Μπορούμε να το καταφέρουμε αυτό με την παρακάτω γραμμή στη συνάρτησή μας `create_table/1`:

```elixir
add :movie_id, references(:movies)
```

Έτσι η μετατροπή μας πρέπει να δείχνει ως εξής:

```elixir
# priv/migrations/*_create_characters.exs
defmodule Friends.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :movie_id, references(:movies)
    end
  end
end
```

#### Το Σχήμα της Ανήκει σε

Παρόμοια το σχήμα μας θα πρέπει να ορίζει τη σχέση "ανήκει σε" ανάμεσα σε ένα χαρακτήρα και την ταινία του.

```elixir
# lib/friends/character.ex

defmodule Friends.Character do
  use Ecto.Schema

  schema "characters" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Ας ρίξουμε μια κοντινότερη ματιά στο τι κάνει η μακροεντολή `belongs_to/3` για εμάς.
Τοποθετεί το ξένο κλειδί `movie_id` στο σχήμα μας και μας δίνει τη δυνατότητα να έχουμε πρόσβαση στο συσχετιζόμενο σχήμα `movies` _μέσα από_ το `characters`.
Χρησιμοποιεί το ξένο κλειδί για να κάνει διαθέσιμη τη συσχετιζόμενη ταινία ενός χαρακτήρα όταν πραγματοποιήσουμε ένα ερώτημα για αυτούς.
Αυτό θα μας επιτρέψει να καλέσουμε την `character.movie`.

Τώρα είμαστε έτοιμοι να τρέξουμε τις μετατροπές μας:

```console
mix ecto.migrate
```

### Belongs To/Has One

Ας πούμε ότι μια ταινία έχει έναν διανομέα, για παράδειγμα το `Netflix` είναι ο διανομέας του πρωτότυπου φίλμ τους "Bright".

Θα ορίσουμε τη μετατροπή και το σχήμα `Distributor` με τη σχέση "ανήκει σε".
Αρχικά, ας δημιουργήσουμε τη μετατροπή:

```console
mix ecto.gen.migration create_distributors
```

Θα πρέπει να προσθέσουμε ένα ξένο κλειδί `movie_id` στη μετατροπή πίνακα `distributors` που μόλις δημιουργήσαμε, όπως επίσης και ένα μοναδικό δείκτη για να βεβαιωθούμε ότι η ταινία έχει μόνο ένα διανομέα:

```elixir
# priv/repo/migrations/*_create_distributors.exs

defmodule Friends.Repo.Migrations.CreateDistributors do
  use Ecto.Migration

  def change do
    create table(:distributors) do
      add :name, :string
      add :movie_id, references(:movies)
    end
    
    create unique_index(:distributors, [:movie_id])
  end
end
```

Και το `Distributor` σχήμα θα πρέπει να χρησιμοποιήσει τη μακροεντολή `belongs_to/3` για να μας επιτρέψει να καλέσουμε την `distributor.movie` και να ψάξουμε τη συσχετιζόμενη ταινία ενός διανομέα χρησιμοποιώντας αυτό το ξένο κλειδί.

```elixir
# lib/friends/distributor.ex

defmodule Friends.Distributor do
  use Ecto.Schema

  schema "distributors" do
    field :name, :string
    belongs_to :movie, Friends.Movie
  end
end
```

Στη συνέχεια, ας προσθέσουμε τη σχέση "has_one" στο σχήμα της `Movie`:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor # I'm new!
  end
end
```

Η μακροεντολή `has_one/3` λειτουργεί ακριβώς όπως η `has_many/3`.
Χρησιμοποιεί το ξένο κλειδί του συσχετιζόμενου σχήματος για να ψάξει και να αποκαλύψει τον διανομέα της ταινίας.
Αυτό θα μας επιτρέψει να καλέσουμε την `movie.distributor`.

Είμαστε έτοιμοι να τρέξουμε τη μετατροπή μας:

```console
mix ecto.migrate
```

### Πολλά προς Πολλά

Ας πούμε ότι μια ταινία έχει πολλούς ηθοποιούς και ένας ηθοποιός ανήκει σε περισσότερες από μια ταινίες.
Θα χτίσουμε ένα πίνακα σύνδεσης που αναφέρεται στις ταινίες και τους ηθοποιούς για να υλοποιήσει αυτή τη σχέση.

Αρχικά, θα δημιουργήσουμε τη μετατροπή για τους `Actors`:

```console
mix ecto.gen.migration create_actors
```

Ορίστε τη μετατροπή:

```elixir
# priv/migrations/*_create_actors.ex

defmodule Friends.Repo.Migrations.Actors do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string
    end
  end
end
```

Ας δημιουργήσουμε τη μετατροπή μας για το πίνακα σύνδεσης:

```console
mix ecto.gen.migration create_movies_actors
```

Θα ορίσουμε τη μετατροπή μας ώστε να έχει δύο ξένα κλειδιά.
Θα προσθέσουμε επίσης ένα μοναδικό δείκτη για να βεβαιωθούμε ότι το ταίριασμα ταινίας και ηθοποιού είναι μοναδικό:

```elixir
# priv/migrations/*_create_movies_actors.ex

defmodule Friends.Repo.Migrations.CreateMoviesActors do
  use Ecto.Migration

  def change do
    create table(:movies_actors) do
      add :movie_id, references(:movies)
      add :actor_id, references(:actors)
    end

    create unique_index(:movies_actors, [:movie_id, :actor_id])
  end
end
```

Στη συνέχεια, ας προσθέσουμε τη μακροεντολή `many_to_many` στο `Movie` σχήμα μας:

```elixir
# lib/friends/movie.ex

defmodule Friends.Movie do
  use Ecto.Schema

  schema "movies" do
    field :title, :string
    field :tagline, :string
    has_many :characters, Friends.Character
    has_one :distributor, Friends.Distributor
    many_to_many :actors, Friends.Actor, join_through: "movies_actors" # I'm new!
  end
end
```

Τελικά, θα ορίσουμε το `Actor` σχήμα μας με την ίδια μακροεντολή `many_to_many`.

```elixir
# lib/friends/actor.ex

defmodule Friends.Actor do
  use Ecto.Schema

  schema "actors" do
    field :name, :string
    many_to_many :movies, Friends.Movie, join_through: "movies_actors"
  end
end
```

Είμαστε έτοιμοι να τρέξουμε τις μετατροπές μας:

```console
mix ecto.migrate
```

## Αποθήκευση Συσχετιζόμενων Δεδομένων

Ο τρόπος με τον οποίο αποθηκεύουμε εγγραφές μαζί με τα σχετικά δεδομένα τους εξαρτάται από τη φύση της σχέσης μεταξύ των εγγραφών.
Ας ξεκινήσουμε με τη σχέση "Ανήκει σε/Έχει πολλά".

### Ανήκει σε

#### Αποθήκευση με την `Ecto.build_assoc/3`

Με τη σχέση "ανήκει σε", μπορούμε να χρησιμοποιήσουμε τη συνάρτηση του Ecto `build_assoc/3`.

Η [`build_assoc/3`](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3) δέχεται τρία ορίσματα:

* Τη δομή της εγγραφής που θέλουμε να αποθηκεύσουμε.
* Το όνομα του συσχετισμού.
* Κάθε όρισμα που θέλουμε να ορίσουμε στη συσχετιζόμενη εγγραφή που αποθηκεύουμε.

Ας αποθηκεύσουμε μια ταινία και το συσχετιζόμενο χαρακτήρα.
Αρχικά, ας δημιουργήσουμε μια εγγραφή ταινίας:

```elixir
iex> alias Friends.{Movie, Character, Repo}
iex> movie = %Movie{title: "Ready Player One", tagline: "Something about video games"}

%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:built, "movies">,
  actors: %Ecto.Association.NotLoaded<association :actors is not loaded>,
  characters: %Ecto.Association.NotLoaded<association :characters is not loaded>,
  distributor: %Ecto.Association.NotLoaded<association :distributor is not loaded>,
  id: nil,
  tagline: "Something about video games",
  title: "Ready Player One"
}

iex> movie = Repo.insert!(movie)
```

Τώρα θα χτίσουμε ένα συσχετιζόμενο χαρακτήρα και θα τον εισάγουμε στη βάση δεδομένων:

```elixir
character = Ecto.build_assoc(movie, :characters, %{name: "Wade Watts"})
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:built, "characters">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
Repo.insert!(character)
%Friends.Character{
  __meta__: %Ecto.Schema.Metadata<:loaded, "characters">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Wade Watts"
}
```

Παρατηρήστε ότι από τη στιγμή που η μακροεντολή `has_many/3` του σχήματος `Movie` ορίζει ότι η ταινία έχει πολλούς `:characters`, το όνομα του συσχετισμού που περνάμε σαν δεύτερο όρισμα στην `build_assoc/3` είναι ακριβώς αυτό: `:characters`.
Μπορούμε να δούμε ότι δημιουργήσαμε ένα χαρακτήρα του οποίου η ιδιότητά `movie_id` ορίστηκε σωστά στο ID της συσχετιζόμενης ταινίας.

Για να μπορέσουμε να αποθηκεύσουμε το διανομέα μιας ταινίας με τη χρήση της `build_assoc/3`, θα έχουμε την ίδια προσέγγιση περνώντας το _όνομα_ της σχέσης της ταινίας με το διανομέα σαν δεύτερο όρισμα της `build_assoc/3`:

```elixir
iex> distributor = Ecto.build_assoc(movie, :distributor, %{name: "Netflix"})
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:built, "distributors">,
  id: nil,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
iex> Repo.insert!(distributor)
%Friends.Distributor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "distributors">,
  id: 1,
  movie: %Ecto.Association.NotLoaded<association :movie is not loaded>,
  movie_id: 1,
  name: "Netflix"
}
```

### Πολλά προς πολλά

#### Αποθήκευση με την `Ecto.Changeset.put_assoc/4`

Η προσέγγιση με την `build_assoc/3` δεν θα δουλέψει για τη σχέση μας πολλά-προς-πολλά.
Αυτό συμβαίνει γιατί κανένας εκ των πινάκων ταινίας και ηθοποιού δεν περιέχει ένα ξένο κλειδί.
Αντίθετα, θα χρειαστεί να χρησιμοποιήσουμε τα Σετ Αλλαγών του Ecto και τη συνάρτηση `put_assoc/4`.

Υποθέτοντας ότι δημιουργήσαμε ήδη μια εγγραφή ταινίας πιο πάνω, ας δημιουργήσουμε μια εγγραφή ηθοποιού:

```elixir
iex> alias Friends.Actor
iex> actor = %Actor{name: "Tyler Sheridan"}
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:built, "actors">,
  id: nil,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
iex> actor = Repo.insert!(actor)
%Friends.Actor{
  __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
  id: 1,
  movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
  name: "Tyler Sheridan"
}
```

Τώρα είμαστε έτοιμοι να συσχετίσουμε την ταινία και τον ηθοποιό μας μέσα από τον πίνακα σύνδεσης.

Αρχικά, σημειώστε ότι για να εργαστούμε με τα σετ αλλαγών, πρέπει να βεβαιωθούμε ότι η δομή `movie` μας έχει προφορτωθεί με τα συσχετιζόμενα δεδομένα.
Θα μιλήσουμε περισσότερο για την προφόρτωση δεδομένων σε λίγο.
Για τώρα, είναι αρκετό να καταλάβετε ότι μπορούμε να προφορτώσουμε τους συσχετισμούς μας ως εξής:

```elixir
iex> movie = Repo.preload(movie, [:distributor, :characters, :actors])
%Friends.Movie{
 __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Στη συνέχεια, θα δημιουργήσουμε ένα σετ αλλαγών για την εγγραφή της ταινίας μας:

```elixir
iex> movie_changeset = Ecto.Changeset.change(movie)
%Ecto.Changeset<action: nil, changes: %{}, errors: [], data: %Friends.Movie<>,
 valid?: true>
```

Τώρα θα περάσουμε το σετ αλλαγών μας σαν πρώτο όρισμα στην [`Ecto.Changeset.put_assoc/4`](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_assoc/4):

```elixir
iex> movie_actors_changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [actor])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<action: :update, changes: %{}, errors: [],
       data: %Friends.Actor<>, valid?: true>
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
```

Αυτό μας δίνει ένα _νέο_ σετ αλλαγών που αναπαριστά την ακόλουθη αλλαγή: προσθήκη των ηθοποιών στη λίστα ηθοποιών της δοθείσας εγγραφής ταινίας.

Τελικά, θα αναβαθμίσουμε τη δοθείσα ταινία και τις εγγραφές ηθοποιών της με το τελευταίο μας σετ αλλαγών:

```elixir
iex> Repo.update!(movie_actors_changeset)
%Friends.Movie{
  __meta__: #Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: #Ecto.Schema.Metadata<:loaded, "actors">,
      id: 1,
      movies: #Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Tyler Sheridan"
    }
  ],
  characters: [
    %Friends.Character{
      __meta__: #Ecto.Schema.Metadata<:loaded, "characters">,
      id: 1,
      movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
      movie_id: 1,
      name: "Wade Watts"
    }
  ],
  distributor: %Friends.Distributor{
    __meta__: #Ecto.Schema.Metadata<:loaded, "distributors">,
    id: 1,
    movie: #Ecto.Association.NotLoaded<association :movie is not loaded>,
    movie_id: 1,
    name: "Netflix"
  },
  id: 1,
  tagline: "Something about video game",
  title: "Ready Player One"
}
```

Μπορούμε να δούμε ότι αυτό μας δίνει μια εγγραφή ταινίας με το νέο ηθοποιό σωστά συσχετισμένο και ήδη προφορτωμένο για εμάς στην `movie.actors`.

Μπορούμε να χρησιμοποιήσουμε αυτή την προσέγγιση για να δημιουργήσουμε ένα νέο ηθοποιό που συσχετίζεται με τη δοθείσα ταινία.
Αντί να περάσουμε μια _αποθηκευμένη_ δομή ηθοποιού στην `put_assoc/4`, απλά περνάμε ένα χάρτη με τα στοιχεία νέου ηθοποιού που θέλουμε να δημιουργήσουμε:

```elixir
iex> changeset = movie_changeset |> Ecto.Changeset.put_assoc(:actors, [%{name: "Gary"}])
%Ecto.Changeset<
  action: nil,
  changes: %{
    actors: [
      %Ecto.Changeset<
        action: :insert,
        changes: %{name: "Gary"},
        errors: [],
        data: %Friends.Actor<>,
        valid?: true
      >
    ]
  },
  errors: [],
  data: %Friends.Movie<>,
  valid?: true
>
iex>  Repo.update!(changeset)
%Friends.Movie{
  __meta__: %Ecto.Schema.Metadata<:loaded, "movies">,
  actors: [
    %Friends.Actor{
      __meta__: %Ecto.Schema.Metadata<:loaded, "actors">,
      id: 2,
      movies: %Ecto.Association.NotLoaded<association :movies is not loaded>,
      name: "Gary"
    }
  ],
  characters: [],
  distributor: nil,
  id: 1,
  tagline: "Something about video games",
  title: "Ready Player One"
}
```

Μπορούμε να δούμε ότι ο νέος ηθοποιόος δημιουργήθηκε με το ID "2" και τα χαρακτηριστικά που του ορίσαμε.

Στην επόμενη ενότητα, θα μάθουμε πως να δημιουργούμε ερωτήματα για τις συσχετιζόμενες εγγραφές μας.
