%{
  version: "1.1.1",
  title: "Ημερομηνία και Ώρα",
  excerpt: """
  Πως δουλεύουμε με την ώρα στην Elixir
  """
}
---

## Time

Η Elixir έχει μερικές ενότητες για την εργασία με την ώρα.
Ας ξεκινήσουμε λαμβάνοντας την τρέχουσα ώρα:

```elixir
iex> Time.utc_now
~T[19:39:31.056226]
```

Σημειώστε ότι έχουμε ένα σύμβολο το οποίο μπορεί να χρησιμοπιηθεί για να δημιουργήσουμε μια δομή `Time`:

```elixir
iex> ~T[19:39:31.056226]
~T[19:39:31.056226]
```

Μπορείτε να μάθετε περισσότερα για τα σύμβολα στο [σχετικό μάθημα](../sigils).
Η πρόσβαση σε μέρη της δομής αυτής είναι εύκολη:

```elixir
iex> t = ~T[19:39:31.056226]
~T[19:39:31.056226]
iex> t.hour
19
iex> t.minute
39
iex> t.day
** (KeyError) key :day not found in: ~T[19:39:31.056226]
```

Όμως υπάρχει μια παγίδα: όπως θα παρατηρήσατε, αυτή η δομή περιέχει μόνο την ώρα μέσα σε μια ημέρα, δεν υπάρχουν δεδομένα σχετικά με την ημέρα, το μήνα ή το χρόνο.

## Date

Σε αντίθεση με την `Time`, μια δομή `Date` έχει πληροφορίες για την τρέχουσα ημερομηνία, χωρίς καμμία πληροφορία για την τρέχουσα ώρα.

```elixir
iex> Date.utc_today
~D[2028-10-21]
```

Και επίσης έχει μερικές χρήσιμες συναρτήσεις για να δουλέψει με τις ημερομηνίες:

```elixir
iex> {:ok, date} = Date.new(2020, 12,12)
{:ok, ~D[2020-12-12]}
iex> Date.day_of_week date
6
iex> Date.leap_year? date
true
```

Η `day_of_week/1` υπολογίζει ποιά μέρα της εβδομάδας είναι μια συγκεκριμένη ημέρα.
Σε αυτή την περίπτωση είναι Σάββατο.
Η `leap_year?/1` ελέγχει αν αυτό το έτος είναι δίσεκτο.
Άλλες συναρτήσεις μπορείτε να βρείτε στην [τεκμηρίωση](https://hexdocs.pm/elixir/Date.html).

## NaiveDateTime

Υπάρχουν δύο δομές στην Elixir οι οποίες περιέχουν ημερομηνία και ώρα μαζί.
Η πρώτη είναι η `NaiveDateTime`.
Το μειονέκτημά της είναι η έλειψη υποστήριξης για ζώνες ώρας:

```elixir
iex(15)> NaiveDateTime.utc_now
~N[2029-01-21 19:55:10.008965]
```

Αλλά έχει ταυτόχρονα την τρέχουσα ημερομηνία και ώρα, έτσι μπορείτε να παίξετε με την προσθήκη ώρας, για παράδειγμα:

```elixir
iex> NaiveDateTime.add(~N[2018-10-01 00:00:14], 30)
~N[2018-10-01 00:00:44]
```

## DateTime

Η δεύτερη, όπως μπορείτε να μαντέψετε από τον τίτλο αυτής της ενότητας, είναι η `DateTime`.
Δεν έχει τα μειονεκτήματα που έχει η `NaiveDateTime`: έχει ταυτόχρονα ημερομηνία και ώρα και υποστηρίζει ζώνες ώρας.
Αλλά προσέξτε τις ζώνες ώρας. Η επίσημη τεκμηρίωση γράφει:

> Many functions in this module require a time zone database. By default, it uses the default time zone database returned by `Calendar.get_time_zone_database/0`, which defaults to `Calendar.UTCOnlyTimeZoneDatabase` which only handles "Etc/UTC" datetimes and returns `{:error, :utc_only_time_zone_database}` for any other time zone.

Σημειώστε επίσης ότι μπορείτε να δημιουργήσετε μια δομή DateTime από μια NaiveDateTime, προσθέτοντας την ζώνη ώρας:

```elixir
iex> DateTime.from_naive(~N[2016-05-24 13:26:08.003], "Etc/UTC")
{:ok, #DateTime<2016-05-24 13:26:08.003Z>}
```

## Δουλεύοντας με ζώνες ώρας

Οπως έχουμε σημειώσει στο προηγούμενο κεφάλαιο, η Elixir δεν έχει προκαθορισμένα δεδομένα ζώνης ώρας.
Για να λύσουμε αυτό το πρόβλημα, χρειάζεται να εγκαταστήσουμε το πακέτο [tzdata](https://github.com/lau/tzdata).
Μετά την εγκατάσταση θα πρέπει να ρυθμίσετε την Elixir καθολικά να χρησιμοποιήσει τη Tzdata σαν βάση δεδομένων ζωνών ώρας:

```elixir
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
```

Ας προσπαθήσουμε τώρα να δημιουργήσουμε μια ώρα στη ζώνη ώρας του Παρισίου και να το μετατρέψουμε σε ώρα Νέας Υόρκης:

```elixir
iex> paris_datetime = DateTime.from_naive!(~N[2019-01-01 12:00:00], "Europe/Paris")
#DateTime<2019-01-01 12:00:00+01:00 CET Europe/Paris>
iex> {:ok, ny_datetime} = DateTime.shift_zone(paris_datetime, "America/New_York")
{:ok, #DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>}
iex> ny_datetime
#DateTime<2019-01-01 06:00:00-05:00 EST America/New_York>
```

Οπως μπορείτε να δείτε, η ώρα άλλαξε από 12:00 ώρα Παρισίου, σε 6:00, το οποίο είναι σωστό - η διαφορά μεταξύ των δύο πόλεων είναι 6 ώρες.

Αυτό ήταν! Αν θέλετε να δουλέψετε με άλλες πιο προχωρημένες συναρτήσεις, θα πρέπει να κοιτάξετε στην επίσημη τεκμηρίωση για τις ενότητες [Time](https://hexdocs.pm/elixir/Time.html), [Date](https://hexdocs.pm/elixir/Date.html), [DateTime](https://hexdocs.pm/elixir/DateTime.html) και [NaiveDateTime](https://hexdocs.pm/elixir/NaiveDateTime.html).
Θα πρέπει επίσης να λάβετε υπόψιν σας τις [Timex](https://github.com/bitwalker/timex) και [Calendar](https://github.com/lau/calendar) οι οποίες είναι πολύ δυνατές βιβλιοθήκες της Elixir σχετικά με το χρόνο.
