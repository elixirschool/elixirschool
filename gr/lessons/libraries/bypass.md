---
version: 1.0.0
title: Bypass
---

Όταν δοκιμάζουμε τις εφαρμογές μας υπάρχουν αρκετές φορές που χρειάζεται να κάνουμε αιτήματα σε εξωτερικές υπηρεσίες.
Είναι πολύ πιθανό επίσης να θέλουμε να εξομοιώσουμε διαφορετικές περιπτώσεις, όπως απροσδόκητα σφάλματα εξυπηρετητή.
Ο αποτελεσματικός χειρισμός αυτών των περιπτώσεων στην Elixir δεν επιτυγχάνεται εύκολα χωρίς λίγη βοήθεια.

Σε αυτό το μάθημα θα εξερευνήσουμε πως η [Bypass](https://github.com/PSPDFKit-labs/bypass) μπορεί να μας βοηθήσει να χειριστούμε γρήγορα και εύκολα αυτά τα αιτήματα στις δοκιμές μας.

{% include toc.html %}

## Τι είναι η Bypass;

Η [Bypass](https://github.com/PSPDFKit-labs/bypass) προσδιορίζεται ως "ένας γρήγορος τρόπος να δημιουργήσουμε ενα προσαρμοσμένο plug που μπορεί να αντικαταστήσει έναν εξυπηρετητή HTTP ώστε να επιστρέψει προεπιλεγμένες απαντήσεις σε εισερχόμενα αιτήματα".

Τι σημαίνει αυτό;
Με μια ματιά στο πως δουλεύει η Bypass, μπορούμε να δούμε ότι είναι μια εφαρμογή OTP που υποδείεται έναν εξωτερικό εξυπηρετητή που περιμένει και απαντάει σε εισερχόμενα αιτήματα.
Δίνοντας προεπιλεγμένες απαντήσεις μπορούμε να δοκιμάσουμε πολλές περιπτώσεις όπως αναπάντεχες διακοπές λειτουργίας και σφάλματα καθώς και αναμενόμενα σενάρια που θα συναντήσουμε, και όλα αυτά χωρίς να κάνουμε ούτε ένα εξερχόμενο αίτημα.

## Χρήση της Bypass 

Για να παρουσιάσουμε καλύτερα τις δυνατότητες της Bypass θα φτιάξουμε μια απλή βοηθητική εφαρμογή που θα στέλνει ping σε μια λίστα από τομείς και θα επιβεβαιώνει ότι είναι online.
Για να το κάνουμε αυτό θα δημιουργήσουμε ένα πρότζεκτ επίβλεψης και έναν GenServer για να ελέγξουμε τους τομείς σε ένα παραμετροποιήσιμο διάστημα.
Χρησιμοποιώντας την Bypass στις δοκιμές μας θα έχουμε την δυνατότητα να επιβεβαιώσουμε πως η εφαρμογή μας θα λειτουργεί με πολλά διαφορετικά αποτελέσματα.

_Σημείωση_: Αν θέλετε να φτάσετε στον τελικό κώδικα, επισκευτείτε το [Clinic](https://github.com/elixirschool/clinic) στο αποθετήριο του Elixir School και ρίξτε μια ματιά.

Σε αυτό το σημείο θα πρέπει να έχουμε άνεση με το να δημιουργούμε νέα Mix πρότζεκτ και να προσθέτουμε τις εξαρτήσεις μας, οπότε αντ' αυτού θα εστιάσουμε στα κομμάτια του κώδικα που θα δοκιμάζουμε.
Αν χρειάζεστε μια ανακεφαλαίωση, επισκευτείτε το τμήμα [Νέα Projects](https://elixirschool.com/en/lessons/basics/mix/#new-projects) του μαθήματος [Mix](https://elixirschool.com/en/lessons/basics/mix) lesson.


Ας αρχίσουμε με τη δημιουργία μιας νέας ενότητας που θα χειρίζεται τα εξερχόμενα αιτήματά μας προς τους τομείς.
Ας δημιουργήσουμε μια συνάρτηση με τη βοήθεια της [HTTPoison](https://github.com/edgurgel/httpoison), την `ping/1`, που θα δέχεται ένα URL και θα επιστρέφει `{:ok, body}` για αιτήματα HTTP 200 και `{:error, reason}` για τα υπόλοιπα:

```elixir
defmodule Clinic.HealthCheck do
  def ping(urls) when is_list(urls), do: Enum.map(urls, &ping/1)

  def ping(url) do
    url
    |> HTTPoison.get()
    |> response()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, body}
  defp response({:ok, %{status_code: status_code}}), do: {:error, "HTTP Status #{status_code}"}
  defp response({:error, %{reason: reason}}), do: {:error, reason}
end
```

Θα παρατηρήσετε οτι _δεν_ φτιάχνουμε έναν GenServer και υπάρχει ένας καλός λόγος γι' αυτό:
Διαχωρίζοντας την λειτουργικότητα (και τις ανησυχίες μας) από τον GenServer, είμαστε σε θέση να δοκιμάσουμε τον κώδικά μας χωρίς τo προστιθέμενo εμπόδιο του συγχρονισμού.

Με τον κώδικά μας έτοιμο, μπορούμε να αρχίσουμε τις δοκιμές μας.
Πριν να είμαστε σε θέση να χρησιμοποιήσουμε την Bypass πρέπει να βεβαιωθούμε οτι τρέχει.
Για να το κάνουμε αυτό, ας ενημερώσουμε το αρχείο `test/test_helper.exs` ως εξής:

```elixir
ExUnit.start()
Application.ensure_all_started(:bypass)
```

Τώρα που ξέρουμε ότι η Bypass θα τρέχει κατά την διάρκεια των δοκιμών μας, ας πάμε το αρχείο `test/clinic/health_check_test.exs` για να τελειώσουμε με τις ρυθμίσεις.
Για να προετοιμάσουμε την Bypass ώστε να δέχεται αιτήματα, πρέπει να ανοίξουμε την σύνδεση με το `Bypass.open/1`, το οποίο μπορεί να γίνει στον ορισμό επανάκλησης της δοκιμής μας:

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end
end
```

Για τώρα θα αρκεστούμε στο ότι η Bypass θα χρησιμοποιήσει την προκαθορισμένη πόρτα επικοινωνίας της αλλά αν θέλουμε να την αλλάξουμε (το οποίο και θα κάνουμε σε επόμενο τμήμα), μπορούμε να παρέχουμε στην `Bypass.open/1` την επιλογή `:port` και μια τιμή - π.χ. `Bypass.open(port: 1337)`.
Τώρα είμαστε έτοιμοι να θέσουμε την Bypass σε λειτουργία.
Θα αρχίσουμε με ένα επιτυχές αίτημα:

```elixir
defmodule Clinic.HealthCheckTests do
  use ExUnit.Case

  alias Clinic.HealthCheck

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "request with HTTP 200 response", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}")
  end
end
```

Η δοκιμή μας είναι αρκετά απλή και αν την τρέξουμε θα δούμε ότι δουλεύει, αλλά ας εμβαθύνουμε για να δούμε τι κάνει το κάθε κομμάτι της.
Το πρώτο πράγμα που βλέπουμε στην δοκιμή μας είναι η συνάρτηση `Bypass.expect/2`:

```elixir
Bypass.expect(bypass, fn conn ->
  Plug.Conn.resp(conn, 200, "pong")
end)
```

Η `Bypass.expect/2` δέχεται την Bypass σύνδεσή μας και μια συνάρτηση ελέγχου η οποία αναμένεται να αλλάξει μια σύνδεση και να την επιστρέψει, αυτή είναι και μια ευκαιρία να γίνουν βεβαιώσεις ισότητας στο αίτημα ώστε να επιβεβαιωθεί οτι είναι αυτό που περιμένουμε.
Ας ενημερώσουμε το δοκιμαστικό URL μας ώστε να συμπεριλαμβάνει το `/ping` και ας βεβαιώσουμε την ισότητα της διαδρομής του αιτήματος και της μεθόδου HTTP:

```elixir
test "request with HTTP 200 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    assert "GET" == conn.method
    assert "/ping" == conn.request_path
    Plug.Conn.resp(conn, 200, "pong")
  end)

  assert {:ok, "pong"} = HealthCheck.ping("http://localhost:#{bypass.port}/ping")
end
```

Στο τελευταίο κομμάτι της δοκιμής μας χρησιμοποιούμε το `HealthCheck.ping/1` και βεβαιώνουμε την ισότητα της απάντησης με το αναμενόμενο αποτέλεσμα, αλλά τι ακριβώς είναι το `bypass.port`;
Η Bypass στην πραγματικότητα ακούει μια τοπική θύρα και υποκλέπτει αυτά τα αιτήματα, χρησιμοποιούμε την `bypass.port` ώστε να ανακτήσουμε την προκαθορισμένη θύρα από την στιγμή που δεν προσδιορίσαμε κάποια στην `Bypass.open/1`.

Σειρά έχει η προσθήκη δοκιμών για σφάλματα.
Μπορούμε να αρχίσουμε με μια δοκιμή σχετικά ίδια με την πρώτη με πολύ μικρές αλλαγές: να επιστρέφει τον κώδικα κατάστασης 500 και στην βεβαίωση ισότητας να επιστρέφει την τούπλα `{:error, reason}`:

```elixir
test "request with HTTP 500 response", %{bypass: bypass} do
  Bypass.expect(bypass, fn conn ->
    Plug.Conn.resp(conn, 500, "Server Error")
  end)

  assert {:error, "HTTP Status 500"} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

Δεν υπάρχει κάτι ιδιαίτερο σε αυτή την περίπτωση δοκιμής οπότε ας περάσουμε στο επόμενο: απροσδόκητες διακοπές λειτουργίας του εξυπηρετητή.
Αυτά είναι τα αιτήματα που μας ενδιαφέρουν περισσότερο.
Για να το επιτύχουμε αυτό δεν θα χρησιμοποιήσουμε την `Bypass.expect/2`, αλλά θα βασιστούμε στην `Bypass.down/1` ώστε να κλείσει η σύνδεση:

```elixir
test "request with unexpected outage", %{bypass: bypass} do
  Bypass.down(bypass)

  assert {:error, :econnrefused} = HealthCheck.ping("http://localhost:#{bypass.port}")
end
```

Αν τρέξουμε τις νέες δοκιμές μας θα δούμε ότι όλα λειτουργούν όπως θα περιμέναμε!
Έχοντας δοκιμάσει την ενότητά μας `HealthCheck` μπορούμε να προχωρίσουμε στη δοκιμή της παράλληλα με τον βασισμένο σε GenServer προγραμματιστή μας.

## Πολλαπλοί εξωτερικοί hosts

Για το πρότζεκτ μας θα κρατήσουμε την ραχοκοκαλιά του προγραμματιστή μας και θα βασιστούμε στην `Process.send_after/3` ώστε να τροφοδοτήσει τις επαναλαμβανόμενες δοκιμές μας, για περισσότερα σχετικά με την ενότητα `Process` ρίξτε μια ματιά στην [τεκμηρίωση](https://hexdocs.pm/elixir/Process.html).
Ο προγραμματιστής μας χρειάζεται τρεις επιλογές: την συλλογή των σελίδων, την συχνότητα των δοκιμών μας, και την ενότητα που εφαρμόζει την `ping/1`.
Περνώντας την ενότητά μας αποσυνδέουμε περαιτέρω την λειτουργικότητα μας και τον GenServer, δίνοντάς μας την δυνατότητα να δοκιμάσουμε ξεχωριστά το κάθε τμήμα:

```elixir
def init(opts) do
  sites = Keyword.fetch!(opts, :sites)
  interval = Keyword.fetch!(opts, :interval)
  health_check = Keyword.get(opts, :health_check, HealthCheck)

  Process.send_after(self(), :check, interval)

  {:ok, {health_check, sites}}
end
```

Τώρα πρέπει να προσδιορίσουμε την συνάρτηση `handle_info/2` για το μήνυμα `:check` που αποστέλλεται με την `send_after/2`.
Για να κρατήσουμε απλά τα πράγματα θα περάσουμε τις σελίδες μας στο `HealthCheck.ping/1` και θα κρατήσουμε τα αποτελέσματα μας στο `Logger.info` ή σε περίπτωση σφάλματος στο `Logger.error`.
Θα φτιάξουμε τον κώδικά μας με τέτοιο τρόπο ώστε να μας επιτρέπεται η βελτίωση των δυνατοτήτων αναφοράς στο μέλλον:

```elixir
def handle_info(:check, {health_check, sites}) do
  sites
  |> health_check.ping()
  |> Enum.each(&report/1)

  {:noreply, {health_check, sites}}
end

defp report({:ok, body}), do: Logger.info(body)
defp report({:error, reason}) do
  reason
  |> to_string()
  |> Logger.error()
end
```

Όπως συζητήσαμε περνάμε τις σελίδες μας στην `HealthCheck.ping/1` και μετά θα επαναλάβουμε τα αποτελέσματά μας με την `Enum.each/2` εφαρμόζοντας σε κάθε ένα την συνάρτησή μας `report/1`.
Με αυτές τις συναρτήσεις έτοιμες ο προγραμματιστής μας είναι έτοιμος και μπορούμε πλέον να εστιάσουμε στη δοκιμή του.

Δεν θα εστιάσουμε τόσο στις δοκιμές μονάδας του προγραμματιστή, καθώς αυτό δεν απαιτεί την χρήση της Bypass, οπότε μπορούμε να περάσουμε στον τελικό κώδικα:

```elixir
defmodule Clinic.SchedulerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  defmodule TestCheck do
    def ping(_sites), do: [{:ok, "pong"}, {:error, "HTTP Status 404"}]
  end

  test "health checks are run and results logged" do
    opts = [health_check: TestCheck, interval: 1, sites: ["http://example.com", "http://example.org"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "pong"
    assert output =~ "HTTP Status 404"
  end
end
```

Βασιζόμαστε σε μια εφαρμογή δοκιμών με την χρήση του `TestCheck` παράλληλα με το `CaptureLog.capture_log/1` ώστε να βεβαιώσει ότι τα σωστά μηνύματα καταγράφονται.

Τώρα που έχουμε δύο λειτουργικές ενότητες, την `Scheduler` και την `HealthCheck`, ας γράψουμε μια δοκιμή ενσωμάτωσης ώστε να βεβαιώσουμε πως όλα μαζί λειτουργούν σωστά.
Θα χρειαστούμε την Bypass για αυτή τη δοκιμή και θα πρέπει να χειριστούμε πολλαπλά αιτήματα Bypass ανα δοκιμή, ας δούμε πως θα το κάνουμε αυτό.

Θυμάστε την `bypass.port` από πριν; Όταν πρέπει να μιμηθούμε πολλαπλές σελίδες, η επιλογή `:port` φαίνεται χρήσιμη.
όπως πιθανότατα μαντέψατε ήδη, μπορούμε να δημιουργήσουμε πολλαπλές συνδέσεις Bypass με διαφορετικές θύρες στην κάθε μια, αυτές θα εξομοιώνανε διαφορετικές σελίδες.
Θα αρχίσουμε αναθεωρώντας το ενημερωμένο μας αρχείο `test/clinic_test.exs`:

```elixir
defmodule ClinicTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Clinic.Scheduler

  test "sites are checked and results logged" do
    bypass_one = Bypass.open(port: 1234)
    bypass_two = Bypass.open(port: 1337)

    Bypass.expect(bypass_one, fn conn ->
      Plug.Conn.resp(conn, 500, "Server Error")
    end)

    Bypass.expect(bypass_two, fn conn ->
      Plug.Conn.resp(conn, 200, "pong")
    end)

    opts = [interval: 1, sites: ["http://localhost:1234", "http://localhost:1337"]]

    output =
      capture_log(fn ->
        {:ok, _pid} = GenServer.start_link(Scheduler, opts)
        :timer.sleep(10)
      end)

    assert output =~ "[info]  pong"
    assert output =~ "[error] HTTP Status 500"
  end
end
```

Δεν θα έπρεπε να υπάρχει κάτι το πολύ εκπληκτικό στην παραπάνω δοκιμή.
Αντί να δημιουργήσουμε μια μοναδική σύνδεση Bypass στο `setup`, δημιουργούμε δύο μέσα στην δοκιμή μας και προσδιορίζουμε τις θύρες τους ως την 1234 και την 1337.
Στη συνέχεια βλέπουμε τα αιτήματα της `Bypass.expect/2` και εν τέλη τον κώδικα που έχουμε στο `SchedulerTest` να εκκινεί τον προγραμματιστή και να βεβαιώνει ότι αποθηκεύουμε τα σωστά μηνύματα.

Αυτό ήταν! Έχουμε φτιάξει μια βοηθητική εφαρμογή η οποία μας κρατά ενήμερους για το αν υπάρχει οποιοδήποτε πρόβλημα με τους τομείς μας και έχουμε μάθει πως να επιστρατεύουμε την Bypass ώστε να γράφουμε καλύτερες δοκιμές με εξωτερικές υπηρεσίες.