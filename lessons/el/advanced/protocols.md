%{
  version: "1.0.1",
  title: "Πρωτόκολλα",
  excerpt: """
  Σε αυτό το μάθημα θα δούμε τα Πρωτόκολλα, τί ακριβώς είναι, και πως τα χρησιμοποιούμε στην Elixir.
  """
}
---

## Τι είναι τα Πρωτόκολλα
Τι ακριβώς είναι; Τα πρωτόκολλα είναι ένας τρόπος να έχουμε πολυμορφισμό στην Elixir. Ένα πρόβλημα στην Erlang είναι η επέκταση ενός υπάρχοντος API για πρόσφατα ορισμένους τύπους. Για να το αποφύγουμε αυτό στην Elixir η συνάρτηση αποστέλλεται δυναμικά βασιζόμενη στον τύπο της τιμής. Η Elixir έρχεται με έναν αριθμό πρωτοκόλλων προεγκατεστημένων, για παράδειγμα το πρωτόκολλο `String.Chars` είναι υπεύθυνο για τη συνάρτηση `to_string/1` που χρησιμοποιήσαμε στο παρελθόν. Ας ρίξουμε μια πιο προσεκτική ματιά στην `to_string/1` με ένα γρήγορο παράδειγμα:

```elixir
iex> to_string(5)
"5"
iex> to_string(12.4)
"12.4"
iex> to_string("foo")
"foo"
```

Όπως βλέπετε καλέσαμε τη συνάρτηση σε διάφορους τύπους και επιδείξαμε ότι δουλεύει σε όλους. Τι θα συμβεί αν καλέσουμε την `to_string/1` σε τούπλες (ή σε κάποιον τύπο που δεν έχει υλοποιήσει το `String.Chars` πρωτόκολλο); Για να δούμε:

```elixir
to_string({:foo})
** (Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}
    (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
    (elixir) lib/string/chars.ex:17: String.Chars.to_string/1
```

Όπως βλέπουμε δεχόμαστε ένα σφάλμα πρωτοκόλλου καθώς δεν υπάρχει υλοποίηση για τις τούπλες. Στην επόμενη ενότητα θα υλοποιήσουμε το πρωτόκολλο `String.Chars` για τις τούπλες.

## Υλοποίηση ενός πρωτοκόλλου

Είδαμε ότι η `to_string/1` δεν έχει ακόμα υλοποιηθεί για τις τούπλες, ας την προσθέσουμε. Για να δημιουργήσουμε μια υλοποίηση θα χρησιμοποιήσουμε την `defimpl` με το πρωτόκολλο μας, θα παρέχουμε την επιλογή `:for` και τον τύπο μας. Ας ρίξουμε μια ματιά στο πως θα έδειχνε:

```elixir
defimpl String.Chars, for: Tuple do
  def to_string(tuple) do
    interior =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.join(", ")

    "{#{interior}}"
  end
end
```

Αν αντιγράψουμε αυτό στο IEx θα πρέπει να είμαστε σε θέση να καλέσουμε την `to_string/1` σε μία τούπλα χωρίς να δεχτούμε κάποιο σφάλμα:

```elixir
iex> to_string({3.14, "apple", :pie})
"{3.14, apple, pie}"
```

Ξέρουμε πως να υλοποιήσουμε ένα πρωτόκολλο αλλά πως ορίζουμε ένα νέο; Για το παράδειγμα μας θα υλοποιήσουμε την `to_atom/1`. Ας δούμε πως θα το κάνουμε με την `defprotocol`:

```elixir
defprotocol AsAtom do
  def to_atom(data)
end

defimpl AsAtom, for: Atom do
  def to_atom(atom), do: atom
end

defimpl AsAtom, for: BitString do
  defdelegate to_atom(string), to: String
end

defimpl AsAtom, for: List do
  defdelegate to_atom(list), to: List
end

defimpl AsAtom, for: Map do
  def to_atom(map), do: List.first(Map.keys(map))
end
```

Εδώ ορίσαμε το πρωτόκολλο μας και την αναμενόμενη συνάρτηση, την `to_atom/1`, μαζί με τις υλοποιήσεις για μερικούς τύπους. Τώρα που έχουμε το πρωτόκολλο μας, ας το χρησιμοποιήσουμε στο IEx:

```elixir
iex> import AsAtom
AsAtom
iex> to_atom("string")
:string
iex> to_atom(:an_atom)
:an_atom
iex> to_atom([1, 2])
:"\x01\x02"
iex> to_atom(%{foo: "bar"})
:foo
```

Είναι άξιο αναφοράς ότι παρόλο που οι δομές είναι χάρτες, δεν μοιράζονται τις υλοποιήσεις πρωτοκόλλων μαζί τους. Δεν είναι απαριθμήσιμες, δεν μπορύν να προσπελαστούν.

Όπως θα δούμε, τα πρωτόκολλα είναι ένας ισχυρός τρόπος να έχουμε πολυμορφισμό.
