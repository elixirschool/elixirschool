%{
  version: "1.2.1",
  title: "Base",
  excerpt: """
  Configurazione, tipi di base ed operazioni di base.
  """
}
---

## Configurazione

### Installare Elixir

Le istruzioni per l'installazione per ciascun sistema operativo sono disponibili su Elixir-lang.org nella guida [Installing Elixir](http://elixir-lang.org/install.html).

Dopo aver installato Elixir, possiamo facilmente controllare la versione installata.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Modalità Interattiva

Elixir viene fornito con IEx, una shell interattiva che permette di eseguire istruzioni di Elixir in tempo reale.

Per cominciare, lanciamo il comando `iex`:

	Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

	Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
	iex>

Ora proviamola con alcuni semplici comandi:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Non preoccuparti se non capisci ogni singola espressione, ma speriamo che tu abbia un'idea generale.

## Tipi di Base

### Interi

```elixir
iex> 255
255
```

Il supporto per numeri in notazione binaria, ottale ed esadecimale è già incluso:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Numeri in Virgola Mobile (Float)

In Elixir, i numeri in virgola mobile richiedono un decimale dopo almeno una cifra; hanno una doppia precisione a 64 bit e supportano la `e` per i numeri con notazione esponenziale:

```elixir
iex> 3.14 
 3.14
iex> .14 
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Booleani

Elixir supporta `true` e `false` come booleani; ogni valore è considerato vero ad eccezione di `false` e `nil`:

```elixir
iex> true
true
iex> false
false
```

### Atoms

Un atom è una costante la quale nome è anche il suo valore. Se hai familiarità con Ruby, puoi considerare gli atoms come i Symbols:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

NOTA: I booleani `true` e `false` sono, rispettivamente, anche `:true` e `:false`.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

I Nomi dei moduli in Elixir sono anch'essi atomi. `MyApp.MyModule` è un atom valido, anche se nessun modulo con questo nome è stato dichiarato.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Inoltre, gli Atomi sono usati per fare riferimento ai moduli delle librerie Erlang, incluse quelle già integrate.

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Stringhe

Le stringhe in Elixir sono codificate in UTF-8 e vengono racchiuse tra apici doppi:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Le stringhe supportano le interruzioni di linea e le sequenze di escape:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Oltre a questi tipi di base, Elixir supporta tipi di dati piú compliessi.
Impareremo di piú su questi durante le lezioni sulle [collezioni](../collections/) e [funzioni](../functions/).

## Operazioni di Base

### Aritmetica

Elixir supporta gli operatori di base `+`, `-`, `*`, e `/` esattamente come ti aspetteresti. È importante notare che l'operatore `/` restituirà sempre un numero in virgola mobile:

```elixir
iex> 2 + 2
4
iex> 2 - 1
1
iex> 2 * 5
10
iex> 10 / 5
2.0
```

Se hai bisogno di fare una divisione tra interi o ottenere il resto di una divisione, Elixir offre due funzioni utili per questo scopo:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Logica Booleana

Elixir mette a disposizione gli operatori booleani `||`, `&&`, e `!`. Questi supportano qualsiasi tipo di dato:

```elixir
iex> -20 || true
-20
iex> false || 42
42

iex> 42 && true
true
iex> 42 && nil
nil

iex> !42
false
iex> !false
true
```

Esistono altri tre operatori che _devono_ ricevere un booleano (`true` e `false`) come primo argomento:

```elixir
iex> true and 42
42
iex> false or true
true
iex> not false
true
iex> 42 and true
** (ArgumentError) argument error: 42
iex> not 42
** (ArgumentError) argument error
```

Nota: Le operazioni booleane `and` e `or` in Elixir derivano a `andalso` e `orelse` in Erlang.

### Confronto

Elixir è provvisto di tutti gli operatori di comparazione ai quali siamo abituati: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` e `>`.

```elixir
iex> 1 > 2
false
iex> 1 != 2
true
iex> 2 == 2
true
iex> 2 <= 3
true
```

Per una comparazione rigorosa (_strict_) tra interi e numeri in virgola mobile, usa `===`:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Una funzionalità importante di Elixir è che due valori di qualsiasi tipo possono essere confrontati, questo è particolarmente utile per l'ordinamento. Non abbiamo bisogno di memorizzare la sequenza di ordinamento, ma è importante esserne al corrente:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Questo può portare ad alcuni interessanti, e validi, confronti che potresti non trovare in altri linguaggi:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Interpolazione in una Stringa

Se hai usato Ruby, l'interpolazione di una stringa in Elixir ti sembrerà familiare:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Concatenazione di Stringhe

Per concatenare le stringhe si usa l'operatore `<>`:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
