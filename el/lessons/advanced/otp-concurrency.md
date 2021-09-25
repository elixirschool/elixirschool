---
version: 1.0.3
title: Συγχρονισμός OTP
---

Είδαμε τις αφαιρέσεις της Elixir για το συγχρονισμό αλλά μερικές φορές χρειαζόμαστε μεγαλύτερο έλεγχο και για αυτό στρεφόμαστε στις συμπεριφορές OTP πάνω στις οποίες έχει χτιστεί η Elixir.

Σε αυτό το μάθημα θα εστιάσουμε στο σημαντικότερο κομμάτι: τους GenServers.

{% include toc.html %}

## GenServer

Ένας εξυπηρετητής OTP είναι μια ενότητα με τη συμπεριφορά GenServer η οποία υλοποιεί ένα σετ επανακλήσεων.  Στο πιο βασικό επίπεδό του ένας GenServer είναι μια διαδικασία η οποία τρέχει ένα βρόγχο, ο οποίος χειρίζεται μια αίτηση ανά επανάληψη και περνάει μια ενημερωμένη κατάσταση.

Για να επιδείξουμε το API των GenServer θα υλοποιήσουμε μια βασική ουρά για να αποθηκεύουμε και ανακτούμε τιμές.

Για να ξεκινήσουμε τον GenServer μας θα χρειαστεί να τον ξεκινήσουμε και να χειριστούμε την αρχικοποίηση.  Στις περισσότερες περιπτώσεις θα θέλουμε να συνδέσουμε διεργασίες, έτσι θα χρησιμοποιήσουμε την `GenServer.start_link/3`.  Θα περάσουμε κάποια ορίσματα και ένα σετ επιλογών GenServer στην ενότητα GenServer που ξεκινάμε.  Τα ορίσματα θα περάσουν στην `GenServer.init/1` η οποία ορίζει την αρχική κατάσταση μέσω της τιμής επιστροφής της.  Στο παράδειγμά μας τα ορίσματα θα είναι η αρχική μας κατάσταση:

```elixir
defmodule SimpleQueue do
  use GenServer

  @doc """
  Ξεκινάει την ουρά μας και την συνδέει.  Αυτή είναι μια βοηθητική συνάρτηση
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 επανάκληση
  """
  def init(state), do: {:ok, state}
end
```

### Σύγχρονες Συναρτήσεις

Συχνά είναι απαραίτητο να αλληλεπιδράσουμε με τους GenServers με ένα σύγχρονο τρόπο, καλώντας μια συνάρτηση και περιμένοντας για την απάντησή της.  Για να χειριστούμε σύγχρονες αιτήσεις θα χρειαστεί να υλοποιήσουμε την επανάκληση `GenServer.handle_call/3` η οποία δέχεται: την αίτηση, το PID της διεργασίας που καλεί, και την υπάρχουσα κατάσταση.  Είναι αναμενόμενο να απαντήσει επιστρέφοντας μια τούπλα: `{:reply, response, state}`.  

Με την αντιπαραβολή προτύπων μπορούμε να ορίσουμε επανακλήσεις για πολλές διαφορετικές αιτήσεις και καταστάσεις.  Μια πλήρης λίστα των αποδεκτών επιστρεφόμενων τιμών μπορεί να βρεθεί στα έγγραφα της [`GenServer.handle_call/3`](https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3).

Για να επιδείξουμε τις σύγχρονες αιτήσεις, ας προσθέσουμε την ικανότητα να προβάλουμε την τρέχουσα ουρά και να αφαιρέσουμε μια τιμή:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 επανάκληση
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 επανάκληση
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  ### Client API / Βοηθητικές συναρτήσεις

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Ας ξεκινήσουμε την SimpleQueue μας και ας δοκιμάσουμε την νέα μας λειτουργικότητα dequeue:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.90.0>}
iex> SimpleQueue.dequeue
1
iex> SimpleQueue.dequeue
2
iex> SimpleQueue.queue
[3]
```

### Ασύγχρονες Συναρτήσεις

Οι ασύγχρονες αιτήσεις χειρίζονται από την επανάκληση `handle_cast/2`.  Αυτή δουλεύει σχεδόν σαν την `handle_call/3`, αλλά δεν δέχεται την διεργασία που καλεί και δεν αναμένεται να απαντήσει.

Θα υλοποιήσουμε την λειτουργικότητά μας enqueue ώστε να είναι ασύγχρονη, ενημερώνοντας την queue αλλά χωρίς να εμποδίζουμε την τρέχουσα εκτέλεση:

```elixir
defmodule SimpleQueue do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 επανάκληση
  """
  def init(state), do: {:ok, state}

  @doc """
  GenServer.handle_call/3 επανάκληση
  """
  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  @doc """
  GenServer.handle_cast/2 επανάκληση
  """
  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Client API / Βοηθητικές Συναρτήσεις

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def enqueue(value), do: GenServer.cast(__MODULE__, {:enqueue, value})
  def dequeue, do: GenServer.call(__MODULE__, :dequeue)
end
```

Ας χρησιμοποιήσουμε την νέα μας λειτουργικότητα:

```elixir
iex> SimpleQueue.start_link([1, 2, 3])
{:ok, #PID<0.100.0>}
iex> SimpleQueue.queue
[1, 2, 3]
iex> SimpleQueue.enqueue(20)
:ok
iex> SimpleQueue.queue
[1, 2, 3, 20]
```

Για περισσότερες πληροφορίες ελέγξτε την επίσημη τεκμηρίωση του [GenServer](https://hexdocs.pm/elixir/GenServer.html#content).
