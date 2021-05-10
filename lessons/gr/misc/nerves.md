%{
  version: "1.1.2",
  title: "Nerves",
  excerpt: """
  """
}
---

## Εισαγωγή και απαιτήσεις

Σε αυτό το μάθημα θα μιλήσουμε για το Nerves.
Το πρότζεκτ Nerves είναι μια δομή που μας επιτρέπει να χρησιμοποιούμε Elixir σε ενσωματομένη ανάπτυξη λογισμικού.
Όπως αναφέρεται στην ιστοσελίδα του Nerves, μας επιτρέπει να "δημιουργήσουμε και να  αναπτύξουμε αλεξίσφαιρο ενσωματωμένο λογισμικό στην Elixir".
Αυτό το μάθημα θα είναι λίγο διαφορετικό από τα υπόλοιπα μαθήματα του Elixir School.
Η εισαγωγή στο Nerves είναι λίγο πιο δύσκολη, καθώς χρειάζεται προηγμένη ρύθμιση συστήματος αλλά και επιπρόσθετο υλικό, οπότε είναι πιθανό να μην είναι κατάλληλο για αρχάριους.

Για να γράψουμε ενσωματωμένο κώδικα χρησιμοποιώντας το Nerves, θα χρειαστούμε ένα από τα [supported targets](https://hexdocs.pm/nerves/targets.html), έναν αναγνώστη καρτών με μία κάρτα που υποστηρίζεται από το υλικό που επιλέξατε, καθώς επίσης και μια ενσύρματη σύνδεση δικτύου ώστε να έχουμε πρόσβαση στην συσκευή μέσω δικτύου.

Ωστόσο, θα προτείναμε να χρησιμοποιήσετε ένα Raspberry Pi, διότι έχει ελεγχόμενες ενδείξεις LED στην πλακέτα.
Επίσης καλό θα ήταν να έχετε μια οθόνη συνδεδεμένη στην συσκευή σας καθώς αυτό θα βοηθήσει με την αποσφαλμάτωση μέσω της χρήσης του IEx.

## Εγκατάσταση

Το Nerves πρότζεκτ έχει έναν άριστο [Οδηγό εκκίνησης](https://hexdocs.pm/nerves/getting-started.html), αλλά οι λεπτομέρειες που υπάρχουν εκεί μπορεί να είναι υπερβολικές για κάποιους χρήστες.
Αντ' αυτού, αυτό το μάθημα θα προσπαθήσει να παρουσιάσει "περισσότερο κώδικα και λιγότερες λέξεις".

Αρχικά, θα χρειαστεί να ρυθμίσετε ένα περιβάλλον.
Μπορείτε να βρείτε τον οδηγό  στο τμήμα [Εγκατάσταση](https://hexdocs.pm/nerves/installation.html) του wiki για το Nerves.
Παρακαλούμε βεβαιωθείτε ότι έχετε την ίδια έκδοση OTP και Elixir που χρησιμοποιείται στον οδηγό.
Η χρήση λάθος έκδοσης μπορεί να προκαλέσει προβλήματα στη συνέχεια.
Τη στιγμή που συντάσσεται αυτό το μάθημα, οποιαδήποτε έκδοση της Elixir (με Elrang/OTP 21) θα πρέπει να δουλεύει σωστα.

Μετά την εγκατάσταση, θα είστε έτοιμοι να φτιάξετε το πρώτο σας πρότζεκτ με το Nerves!

Στόχος μας είναι να να φτάσουμε στο "Hello world" της ανάπτυξης ενσωματωμένου κώδικα: μια λυχνία LED που ελέγχεται από την κλήση ενός απλού HTTP API.

## Δημιουργώντας ένα πρότζεκτ

Για να δημιουργήσουμε ένα νέο πρότζεκτ, γράφουμε την εντολή `mix nerves.new network_led` και εισάγουμε την απάντηση `Y` όταν μας ζητηθεί να κατεβάσουμε και να εγκαταστήσουμε τις εξαρτήσεις.

Θα πρέπει να βλέπετε το ακόλουθο αποτέλεσμα:

```
Your Nerves project was created successfully.

You should now pick a target. See https://hexdocs.pm/nerves/targets.html#content
for supported targets. If your target is on the list, set `MIX_TARGET`
to its tag name:

For example, for the Raspberry Pi 3 you can either
  $ export MIX_TARGET=rpi3
Or prefix `mix` commands like the following:
  $ MIX_TARGET=rpi3 mix firmware

If you will be using a custom system, update the `mix.exs`
dependencies to point to desired system's package.

Now download the dependencies and build a firmware archive:
  $ cd network_led
  $ mix deps.get
  $ mix firmware

If your target boots up using an SDCard (like the Raspberry Pi 3),
then insert an SDCard into a reader on your computer and run:
  $ mix firmware.burn

Plug the SDCard into the target and power it up. See target documentation
above for more information and other targets.
```

Το πρότζεκτ μας δημιουργήθηκε και είναι έτοιμο να περαστεί στην δοκιμαστική συσκευή μας!
Ας το δοκιμάσουμε τώρα!

Στην περίπτωση ενός Raspberry Pi 3, ορίζετε `MIX_TARGET=rpi3`, αλλά μπορείτε να το αλλάξετε ώστε να ταιριάζει με το υλικό που έχετε σε σχέση με το υλικό που προορίζεται (δείτε την λίστα στην [Τεκμηρίωση Nerves](https://hexdocs.pm/nerves/targets.html#content)).

Αρχικά ας ορίσουμε τις εξαρτήσεις μας:

```shell
$ export MIX_TARGET=rpi3
$ cd network_led
$ mix deps.get

....

Nerves environment
  MIX_TARGET:   rpi3
  MIX_ENV:      dev
Resolving Nerves artifacts...
  Resolving nerves_system_rpi3
  => Trying https://github.com/nerves-project/nerves_system_rpi3/releases/download/v1.12.2/nerves_system_rpi3-portable-1.12.2-E904717.tar.gz
|==================================================| 100% (142 / 142) MB
  => Success
  Resolving nerves_toolchain_arm_unknown_linux_gnueabihf
  => Trying https://github.com/nerves-project/toolchains/releases/download/v1.3.2/nerves_toolchain_arm_unknown_linux_gnueabihf-darwin_x86_64-1.3.2-E31F29C.tar.xz
|==================================================| 100% (55 / 55) MB
  => Success
```

Σημείωση: να είστε σίγουροι πως έχετε ορίσει την μεταβλητή περιβάλλοντος να προσδιορίζει την πλατφόρμα που στοχεύετε πριν γράψετε την εντολή `mix deps.get`, καθώς θα κατεβάσει την απαραίτητη εικόνα συστήματος και την εργαλειοθήκη για την προσδιοριζόμενη πλατφόρμα.

## "Εγκατάσταση" υλικολογισμικού

Τώρα μπορούμε να προχωρήσουμε στην τροποποίηση του δίσκου.
Τοποθετήστε την κάρτα στον αναγνώστη, και αν έχετε εγκαταστήσει τα πάντα σωστά στα προηγούμενα βήματα, αφου γράψετε την εντολή `mix firmware.burn` και επιβεβαιώσετε την συσκευή που θα χρησιμοποιηθεί, θα πρέπει να βλέπετε αυτή την προτροπή:

```
Building ......../network_led/_build/rpi_dev/nerves/images/network_led.fw...
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
```

Αν είστε σίγουροι πως αυτή είναι η κάρτα που θα χρησιμοποιήσετε - επιλέξτε `Y` και σε σύντομο χρονικό διάστημα η κάρτα θα είναι έτοιμη:

```
Use 7.42 GiB memory card found at /dev/rdisk2? [Yn]
|====================================| 100% (32.51 / 32.51) MB
Success!
Elapsed time: 8.022 s
```

Έχει έρθει η ώρα να δοκιμάσουμε αν η κάρτα μας δουλεύει ή όχι.

Αν έχετε μια οθόνη συνδεδεμένη - θα πρέπει να βλέπετε την ακολουθία εκκίνησης του Linux αφού εκκινήσετε την συσκευή με την κάρτα μνήμης μέσα.

## Ρυθμίζοντας την δικτύωση

Το επόμενο βήμα είναι να ρυθμίσουμε την δικτύωση.
Το οικοσύστημα του Nerves παρέχει μια ποικιλία από πακέτα, και το [vintage_net](https://github.com/nerves-networking/vintage_net) είναι αυτό που θα χρειαστούμε για να συνδέσουμε την συσκευή μας στο δίκτυο με την χρήση της θύρας Ethernet.

Υπάρχει ήδη στο πρότζεκτ σας, ως εξάρτηση του [`nerves_pack`](https://github.com/nerves-project/nerves_pack).
Παρ' όλα αυτά, προκαθορισμένα, χρησιμοποιεί DHCP (δείτε την ρύθμιση για αυτό στο `config/target.exs`μετα το `config :vintage_net`).
Είναι πιο εύκολο να έχουμε στατική διεύθυνση IP.

Για να ορίσουμε στατική δικτύωση σε θύρα Ethernet, θα πρέπει να ενημερώσετε την ρύθμιση του `:vintage_net` στο αρχείο `config/target.exs`, ως εξής:

```elixir
# Statically assign an address
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{
         method: :static,
         address: "192.168.88.2",
         prefix_length: 24,
         gateway: "192.168.88.1",
         name_servers: ["8.8.8.8", "8.8.4.4"]
       }
     }},
    {"wlan0", %{type: VintageNetWiFi}}
  ]
```

Παρακαλούμε προσέξτε ότι αυτή η ρύθμιση ενημερώνει μόνο την πόρτα Ethernet.
Αν θέλετε να χρησιμοποιήσετε την ασύρματη σύνδεση - ρίξτε μια ματιά στο [VintageNet Cookbook](https://hexdocs.pm/vintage_net/cookbook.html#wifi).

Θα πρέπει να χρησιμοποιείτε τις ρυθμήσεις τοπικού δικτύου εδώ - στο δικό μας δίκτυο υπάρχει μια διεύθυνση IP που δεν έχει αποδοθεί κάπου και είναι η `192.168.88.2`, την οποία και θα χρησιμοποιήσουμε.
Στην περίπτωσή σας ωστόσο, μπορεί να διαφέρει.

Αφού κάνουμε αυτή την αλλαγή, θα πρέπει να περάσουμε την αλλαγμένη έκδοση του υλικολογισμικού μέσω της εντολής `mix firmware.burn` και στην συνέχεια να επανεκκινήσουμε την συσκευή με την νέα κάρτα μνήμης.

Όταν ενεργοποιήσετε την συσκευή, μποορείτε να χρησιμοποιήσετε την εντολή `ping` για να δείτε πότε θα "μπει στο δίκτυο".

```
Request timeout for icmp_seq 206
Request timeout for icmp_seq 207
64 bytes from 192.168.88.2: icmp_seq=208 ttl=64 time=2.247 ms
64 bytes from 192.168.88.2: icmp_seq=209 ttl=64 time=2.658 ms
```

Αυτά τα αποτελέσματα σημαίνουν ότι η συσκευή μας είναι πλέον προσβάσιμη μέσω δικτύου.

## Network firmware burning

Μέχρι στιγμής, περνούσαμε τις αλλαγές μας σε κάρτες μνήμης SD και τις τοποθετούσαμε στην συσκευή μας.
Παρ' όλο που αυτή είναι μια χαρά σαν διαδικασία για να ξεκινήσουμε, είναι πιο λειτουργικό να προωθούμε τις ενημερώσεις μας μέσω του δικτύου.
Το πακέτο [`ssh_subsystem_fwup`](https://github.com/nerves-project/ssh_subsystem_fwup) κάνει ακριβώς αυτό.
Είναι ήδη προκαθορισμένο στο πρότζεκτ σας και είναι διαμορφωμένο να αναγνωρίζει αυτόματα και να βρίσκει κλειδιά SSH στον φάκελο `~/.ssh` σας.

Για να χρησιμοποιήσετε την λειτουργία δικτυακής ενημέρωσης υλικολογισμικού, θα χρειαστεί να παράγετε ένα script μεταφόρτωσης με την εντολή `mix firmware.gen.script`.
Αυτή η εντολή θα παράξει ένα νέο script `upload.sh` το οποίο μπορείτε να τρέξετε για να ενημερώσετε το υλικολογισμικό.

Αν το δίκτυο είναι λειτουργικό μετά το προηγούμενο βήμα, είστε έτοιμοι.

Για να ενημερώσετε την εγκατάσταση σας, ο πιο απλός τρόπος είναι να χρησιμοποιήσετε την εντολή `mix firmware && ./upload.sh 192.168.88.2`: η πρώτη εντολή δημιουργεί το ενημερωμένο υλικολογισμικό, και η δεύτερη το προωθεί μέσω του δικτύου και επανεκκινεί την συσκευή.
Μπορείτε πλέον να σταματήσετε να βάζετε και να βγάζετε κάρτες μνήμης SD στην συσκευή σας!

_Αναφορά: Η εντολή `ssh 192.168.88.2` σας παρέχει ένα κέλυφος IEx στην συσκευή στο περιεχόμενο της εφαρμογής._

_Αντιμετώπιση προβλημάτων: Αν δεν έχετε ένα κλειδί ssh στον αρχικό σας φάκελο, θα παρουσιαστεί ένα σφάλμα `No SSH public keys found in ~/.ssh.`.
Σε αυτή την περίπτωση, θα χρειαστεί να εισάγετε την εντολή `ssh-keygen` και να γράψετε εκ νέου το υλικολογισμικό ώστε να χρησιμοποιεί την λειτουργία ενημέρωσης μέσω δικτύου._

## Ρυθμίζοντας τον έλεγχο των  λυχνιών LED

Για να αλληλεπιδράσουμε με τις λυχνίες LED, θα χρειαστεί να εγκαταστήσουμε το πακέτο [nerves_leds](https://github.com/nerves-project/nerves_leds), με την προσθήκη του `{:nerves_leds, "~> 0.8", targets: @all_targets},` στο αρχείο `mix.exs`.

Αφου εγκαταστήσουμε τις εξαρτήσεις, θα πρέπει να ρυθμίσουμε την λίστα λυχνιών LED για την συσκευή μας.
Για παράδειγμα, για όλα τα μοντέλα Raspberry Pi, υπάρχει μόνο μια λυχνία LED ενσωματομένη: `led0`.
Ας την χρησιμοποιήσουμε προσθέτοντας μια γραμμή `config :nerves_leds, names: [green: "led0"]` στο αρχείο `config/config.exs`.

Για άλλες συσκευές, μπορείτε να ρίξετε μια ματιά στο [αντίστοιχο μέρος του πρότζεκτ nerves_examples](https://github.com/nerves-project/nerves_examples/tree/main/hello_leds/config).

Αφού ρυθμίσουμε την λυχνία LED, σίγουρα θα πρέπει κάπως να την ελέγξουμε.
Για να το κάνουμε αυτό, θα προσθέσουμε έναν GenServer (δείτε λεπτομέριες στο μάθημα [OTP Concurrency](../../advanced/otp-concurrency)) στο αρχείο `lib/network_led/blinker.ex` με αυτά τα περιεχόμενα:

```elixir
defmodule NetworkLed.Blinker do
  use GenServer

  @moduledoc """
    Simple GenServer to control GPIO #18.
  """

  require Logger
  alias Nerves.Leds

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    enable()

    {:ok, state}
  end

  def handle_cast(:enable, state) do
    Logger.info("Enabling LED")
    Leds.set(green: true)

    {:noreply, state}
  end

  def handle_cast(:disable, state) do
    Logger.info("Disabling LED")
    Leds.set(green: false)

    {:noreply, state}
  end

  def enable() do
    GenServer.cast(__MODULE__, :enable)
  end

  def disable() do
    GenServer.cast(__MODULE__, :disable)
  end
end

```

Για να το ενεργοποιήσετε αυτό, θα πρέπει επίσης να το προσθέσετε στο δέντρο εποπτείας σας στο `lib/network_led/application.ex`: προσθέστε `{NetworkLed.Blinker, name: NetworkLed.Blinker}` κάτω από την ομάδα `def children(_target) do`.

Παρατηρείτε ότι το Nerves έχει δύο διαφορετικά δέντρα εποπτείας στην εφαρμογή - ένα για την συσκευή οικοδεσπότη και ένα για τις πραγματικές συσκευές.

Μετά από αυτό - αυτό ήταν! Μπορείτε πλέον να ανεβάσετε το υλικολογισμικό σας και τρέχοντας το IEx με ssh στην συσκευή που στοχεύουμε να ελένξουμε ότι η εντολή `NetworkLed.Blinker.disable()` σβήνει την λυχνία LED (η οποία ήταν προκαθορισμένο στον κώδικά μας να είναι αναμένη), και η εντολή `NetworkLed.Blinker.enable()` την ανάβει.

Έχουμε τον έλεγχο της λυχνίας από την γραμμή εντολών!

Τώρα το μόνο κομμάτι που λείπει από το παζλ είναι να ελέγχουμε την λυχνία από την διεπαφή ιστού.

## Προσθέτοντας τον εξυπηρετητή ιστού

Σε αυτό το βήμα, θα χρησιμοποιήσουμε το `Plug.Router`.
Αν χρειάζεστε μια υπενθύμιση - μπορείτε να ανατρέξετε στο μάθημα [Plug](../../../lessons/specifics/plug/).

Αρχικά, θα προσθέσουμε την γραμμή `{:plug_cowboy, "~> 2.0"},` στο αρχείο `mix.exs` και θα εγκαταστήσουμε τις εξαρτήσεις.

Έπειτα, θα προσθέσουμε την λειτουργία που θα επεξεργάζεται αυτά τα αιτήματα στο αρχείο `lib/network_led/http.ex` :

```elixir
defmodule NetworkLed.Http do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Feel free to use API endpoints!"))

  get "/enable" do
    NetworkLed.Blinker.enable()
    send_resp(conn, 200, "LED enabled")
  end

  get "/disable" do
    NetworkLed.Blinker.disable()
    send_resp(conn, 200, "LED disabled")
  end

  match(_, do: send_resp(conn, 404, "Oops!"))
end
```

Και ως τελευταίο βήμα - προσθέστε την γραμμή `{Plug.Cowboy, scheme: :http, plug: NetworkLed.Http, options: [port: 80]}` στο δέντρο εποπτείας της εφαρμογής.

Μετά την ενημέρωση του υλικολογισμικού, μπορείτε να το δοκιμάσετε! Η σελίδα `http://192.168.88.2/` επιστρέφει μια απάντηση κειμένου και οι σελίδες `http://192.168.88.2/enable` και `http://192.168.88.2/disable` την ενεργοποίηση και απενεργοποίηση αντίστοιχα της λυχνίας LED!

Μπορείτε ακόμη να πακετάρετε διεπαφές χρήστη με την τις δυνατότητες του Phoenix στην Nerves εφαρμογή σας, ωστόσο, αυτό [απαιτεί κάποιες τροποποιήσεις](https://github.com/nerves-project/nerves/blob/master/docs/User%20Interfaces.md#phoenix-web-interfaces).
