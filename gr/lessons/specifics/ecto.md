---
version: 1.0.1
title: Ecto
---

Το Ecto είναι ένα επίσημο Elixir project το οποίο παρέχει ένα κάλυμμα βάσης δεδομένων και μια ενσωματωμένη γλώσσα ερωτημάτων.  Με το Ecto είμαστε σε θέση να δημιουργούμε μετατροπές, να ορίζουμε μοντέλα, να εισάγουμε και επεξεργαζόμαστε εγγραφές και να τις εξετάζουμε.

{% include toc.html %}

## Εγκατάσταση

Για να ξεκινήσουμε πρέπει να συμπεριλάβουμε το Ecto και έναν αντάπτορα βάσης δεδομένων στο `mix.exs` του project μας.  Μπορείτε να βρείτε μια λίστα υποστηριζόμενων ανταπτόρων στον τομέα [Usage](https://github.com/elixir-lang/ecto/blob/master/README.md#usage) του Ecto README.  Για το παράδειγμά μας θα χρησιμοποιήσυμε την PostgreSQL:

```elixir
defp deps do
  [{:ecto, "~> 2.1.4"}, {:postgrex, ">= 0.13.2"}]
end
```

Τώρα μπορούμε να προσθέσουμε το Ecto και τον αντάπτορά μας στη λίστα εφαρμογών:

```elixir
def application do
  [applications: [:ecto, :postgrex]]
end
```

### Αποθετήριο

Τέλος χρειάζεται να δημιουργήσουμε το αποθετήριο του project μας, το κάλυμμα της βάσης δεδομένων.  Αυτό μπορεί να γίνει μέσω της εργασίς `mix ecto.gen.repo`.  Θα καλύψουμε τις εργασίες mix του Ecto στη συνέχεια.  Το αποθετήριο μπορεί να βρεθεί στο `lib/<όνομα του project>/repo.ex`:

```elixir
defmodule ExampleApp.Repo do
  use Ecto.Repo, otp_app: :example_app
end
```

### Επιτηρητής

Εφόσον έχουμε δημιουργήσει το αποθετήριό μας χρειαζόμαστε να ρυθμίσουμε το δέντρο επιτήρησής μας, το οποίο συνήθως βρίσκεται στο `lib/<όνομα του project>.ex`.

Είναι σημαντικό να σημειώσουμε ότι ορίζουμε το αποθετήριο σαν επιτηρητή με την `supervisor/3` και _όχι_ με την `worker/3`.  Αν δημιουργήσετε την εφαρμογή σας με την σημαία `--sup`, αρκετά από αυτά υπάρχουν ήδη:

```elixir
defmodule ExampleApp.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(ExampleApp.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: ExampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Για περισσότερες πληροφορίες στους επιτηρητές ελέγξτε το μάθημα [Επιτηρητές OTP](../../advanced/otp-supervisors).

### Ρύθμιση

Για να ρυθμίσουμε το Ecto χρειάζεται να προσθέσουμε ένα τομέα στο `config/config.exs` μας.  Εδώ θα ορίσουμε το αποθετήριο, τον αντάπτορα, τη βάση δεδομένων και τις πληροφορίες λόγαριασμού:

```elixir
config :example_app, ExampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "example_app",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

## Εργασίες Mix

Το Ecto περιλαμβάνει έναν αριθμό χρήσιμων εργασιών mix για την εργασία με τη βάση δεδομένων μας:

```shell
mix ecto.create         # Δημιουργήστε την αποθήκη για το αποθετήριό μας
mix ecto.drop           # Διαγράψτε την αποθήκη για το αποθετήριο
mix ecto.gen.migration  # Δημιουργήστε μια νέα μετατροπή για το αποθετήριο
mix ecto.gen.repo       # Δημιουργήστε ένα νέο αποθετήριο
mix ecto.migrate        # Ανεβάστε τις μετατροπές σε ένα αποθετήριο
mix ecto.rollback       # Επαναφέρετε τις μετατροπές από ένα αποθετήριο
```

## Μετατροπές

Ο καλύτερος τρόπος να δημιουργήσετε μετατροπές είναι η εργασία `mix ecto.gen.migration <όνομα>`.  Αν είστε εξοικειομένοι με το ActiveRecord, οι μετατροπές θα σας είναι γνώριμες.

Ας ξεκινήσουμε ρίχνοντας μια ματιά σε μια μετατροπή για ένα πίνακα χρηστών:

```elixir
defmodule ExampleApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :string, unique: true)
      add(:encrypted_password, :string, null: false)
      add(:email, :string)
      add(:confirmed, :boolean, default: false)

      timestamps
    end

    create(unique_index(:users, [:username], name: :unique_usernames))
  end
end
```

Εξ' ορισμού το Ecto δημιουργεί ένα αυτό-αυξανόμενο πρωτεύον κλειδί ονομαζόμενο `id`.  Εδώ χρησιμοποιούμε την προκαθορισμένη επανάκληση `change/0` αλλά το Ecto επίσης υποστηρίζει τις `up/0` και `down/0` σε περίπτωση που χρειάζεστε περισσότερο έλεγχο.

Όπως ίσως θα μαντέψατε, η προσθήκη των `timestamps` στη μετατροπή σας θα δημιουργήσει και διαχειριστεί τα πεδία `inserted_at` και `updated_at` για εσάς.

Για να εφαρμόσουμε τη νέα μας μετατροπή θα τρέξουμε την εργασία `mix ecto.migrate`.

Για περισσότερα στις μετατροπές ρίξτε μια ματιά στον τομέα [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html#content) των εγγράφων.

## Μοντέλα

Τώρα που έχουμε τη μετατροπή μας μπορούμε να μεταφερθούμε στο μοντέλο.  Τα μοντέλα καθορίζουν το σχήμα, τις βοηθητικές μεθόδους και το σετ αλλαγών μας (changeset).  Θα καλύψουμε περισσότερο τα σετ αλλαγών στις επόμενες ενότητες.

Για τώρα ας δούμε πως φαίνεται το μοντέλο για τη μετατροπή μας:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username encrypted_password email)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:username)
  end
end
```

Το σχήμα που ορίζουμε στο μοντέλο μας αναπαριστά το τι ορίσαμε στη μετατροπή μας.  Επιπρόσθετα στα πεδία της βάσης δεδομένων μας, συμπεριλαμβάνουμε δύο εικονικά πεδία.  Τα εικονικά πεδία δεν αποθηκεύονται στη βάση δεδομένων αλλά μπορούν να γίνουν χρήσιμα για περιπτώσεις όπως η επικύρωση.  Θα δούμε τα εικονικά πεδία σε δράση στον τομέα [Σετ αλλαγών](#changesets).

## Ερωτήματα

Πριν μπορέσουμε να ρωτήσουμε το αποθετήριό μας πρέπει να εισάγουμε το API Ερωτημάτων.  Για τώρα πρέπει να εισάγουμε μόνο την `from/2`:

```elixir
import Ecto.Query, only: [from: 2]
```

Η επίσημη τεκμηρίωση μπορεί να βρεθεί στο [Ecto.Query](http://hexdocs.pm/ecto/Ecto.Query.html).

### Βασικά

Το Ecto παρέχει μία εξαιρετική DSL Ερωτημάτων που μας επιτρέπει να εκφράζουμε ξεκάθαρα τα ερωτήματα.  Για να βρούμε τα ονόματα χρήστη από όλους τους επιβεβαιωμένους λογαριασμούς θα μπορούσαμε να χρησιμοποιήσουμα κάτι σαν αυτό:

```elixir
alias ExampleApp.{Repo, User}

query =
  from(
    u in User,
    where: u.confirmed == true,
    select: u.username
  )

Repo.all(query)
```

Επιπρόσθετα στην `all/2`, το αποθετήριο παρέχει έναν αριθμό επανακλήσεων συμπεριλαμβάνοντας τις `one/2`, `get/3`, `insert/2` και `delete/2`.  Μια πλήρης λίστα επανακλήσεων μπορεί να βρεθεί στο [Ecto.Repo#callbacks](http://hexdocs.pm/ecto/Ecto.Repo.html#callbacks).

### Μέτρηση

Αν θέλουμε να μετρήσουμε τον αριθμό χρηστών που έχουν επιβεβαιωμένο λογαριασμό θα μπορούσαμε να χρησιμοποιήσουμε την `count/1`:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id)
  )
```

Υπάρχει η συνάρτηση `count/2` που μετράει τις ξεχωριστές τιμές σε μια δωσμένη εγγραφή:

```elixir
query =
  from(
    u in User,
    where: u.confirmed == true,
    select: count(u.id, :distinct)
  )
```



### Ομαδοποίηση

Για να ομαδοποιήσουμε χρήστες με βάση την κατάσταση επιβεβαίωσης μπορούμε να συμπεριλάβουμε την επιλογή `group_by`:

```elixir
query =
  from(
    u in User,
    group_by: u.confirmed,
    select: [u.confirmed, count(u.id)]
  )

Repo.all(query)
```

### Ταξινόμηση

Η ταξινόμηση των χρηστών με βάση την ημερομηνία δημιουργίας:

```elixir
query =
  from(
    u in User,
    order_by: u.inserted_at,
    select: [u.username, u.inserted_at]
  )

Repo.all(query)
```

Για να ταξινομήσουμε κατά φθίνουσα σειρά:

```elixir
query =
  from(
    u in User,
    order_by: [desc: u.inserted_at],
    select: [u.username, u.inserted_at]
  )
```

### Ενώσεις

Υποθέτωντας ότι έχουμε ένα προφίλ συσχετισμένο με τον χρήστη μας, ας βρούμε όλα τα προφίλ επιβεβαιωμένων λογαριασμών:

```elixir
query =
  from(
    p in Profile,
    join: u in assoc(p, :user),
    where: u.confirmed == true
  )
```

### Κομμάτια

Μερικές φορές, όπως όταν χρειαζόμαστε συγκεκριμμένες συναρτήσεις βάσης δεδομένων, το API ερωτημάτων δεν είναι αρκετό.  Η συνάρτηση `fragment/1` υπάρχει για αυτό το σκοπό:

```elixir
query =
  from(
    u in User,
    where: fragment("downcase(?)", u.username) == ^username,
    select: u
  )
```

Επιπρόσθετα παραδείγματα ερωτημάτων μπορούν να βρεθούν στην περιγραφή ενότητας [Ecto.Query.API](http://hexdocs.pm/ecto/Ecto.Query.API.html).

## Σετ αλλαγών

Στον προηγούμενο τομέα μάθαμε πως να ανακτήσουμε δεδομένα, αλλά πως τα εισάγουμε και πως τα αλλάζουμε;  Για αυτό χρειαζόμαστε τα σετ αλλαγών.

Τα σετ αλλαγών αναλαμβάνουν το φιλτράρισμα, την επικύρωση και τους περιορισμούς όταν γίνονται αλλαγές σε ένα μοντέλο.

Για αυτό το παράδειγμα θα εστιάσουμε στο σετ αλλαγών για τη δημιουργία ενός λογαριασμού χρήστη.  Για να ξεκινήσουμε πρέπει να αλλάξουμε το μοντέλο μας:

```elixir
defmodule ExampleApp.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field(:username, :string)
    field(:encrypted_password, :string)
    field(:email, :string)
    field(:confirmed, :boolean, default: false)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    timestamps
  end

  @required_fields ~w(username email password password_confirmation)
  @optional_fields ~w()

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:password, min: 8)
    |> validate_password_confirmation()
    |> unique_constraint(:username, name: :email)
    |> put_change(:encrypted_password, hashpwsalt(params[:password]))
  end

  defp validate_password_confirmation(changeset) do
    case get_change(changeset, :password_confirmation) do
      nil ->
        password_incorrect_error(changeset)

      confirmation ->
        password = get_field(changeset, :password)
        if confirmation == password, do: changeset, else: password_mismatch_error(changeset)
    end
  end

  defp password_mismatch_error(changeset) do
    add_error(changeset, :password_confirmation, "Passwords does not match")
  end

  defp password_incorrect_error(changeset) do
    add_error(changeset, :password, "is not valid")
  end
end
```

Βελτιώσαμε τη συνάρτηση `changeset/2` και προσθέσαμε τρεις νέες βοηθητικές συναρτήσεις: `validate_password_confirmation/1`, `password_mismatch_error/1` και `password_incorrect_error/1`.

Όπως υποστηρίζει το όνομα, η `changeset/2` δημιουργεί ένα νέο σετ αλλαγών για εμάς.  Σε αυτό χρησιμοποιούμε την `cast/4` για να μετατρέψουμε τις παραμέτρους σε ένα σετ αλλαγών από ένα σετ απαραίτητων και προεραιτικών πεδίων.  Στη συνέχεια επικυρώνουμε το μέγεθος του κωδικού στο σετ αλλαγών, χρησιμοποιούμε τις δικές μας συναρτήσεις να επικυρώσουμε ότι ταιριάζει η επιβεβαίωση κωδικού, και επικυρώνουμε τη μοναδικότητα του ονόματος χρήστη.  Τέλος αναβαθμίζουμε το πραγματικό μας πεδίο κωδικού στη βάση δεδομένων.  Για αυτό χρησιμοποιούμε την `put_change/3` για να αναβαθμίσουμε μια τιμή στο σετ αλλαγών.

Η χρήση της `User.changeset/2` είναι αρκετά απλή:

```elixir
alias ExampleApp.{User, Repo}

pw = "οι κωδικοί πρέπει να είναι δύσκολοι"

changeset =
  User.changeset(%User{}, %{
    username: "doomspork",
    email: "sean@seancallan.com",
    password: pw,
    password_confirmation: pw
  })

case Repo.insert(changeset) do
  {:ok, model}        -> # Επιτυχής εισαγωγή
  {:error, changeset} -> # Κάτι πήγε στραβά
end
```

Αυτό ήταν!  Τώρα είστε έτοιμοι να αποθηκεύσετε μερικά δεδομένα.
