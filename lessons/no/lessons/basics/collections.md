%{
  version: "0.9.0",
  title: "Kolleksjoner",
  excerpt: """
  Lister, tupler, nøkkelord, kart og funksjonell kombinasjon.
  """
}
---

## Lister (lists)

Lister er enkle kolleksjoner av verdier, som kan bestå av forskjellige typer. Listene kan inneholde ikke-unike verdier:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixir implementerer listene som lenkede lister. Dette betyr at for å få lengden av en liste, må man bruke en `O(n)` operasjon for å aksessere den.
På grunn av dette er det ofte raskere å foranstille enn å tilføye til listen.

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```


### Listesammenf&oslash;yning (list concatenation)

For å sammenføye to lister bruker vi `++/2` operatoren:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

### Listesubtrahering (list subtraction)

For å trekke fra i ei liste bruker vi `--/2` operatoren. Det er trygt å trekke fra en verdi som ikke eksisterer:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Vær oppmerksom på duplikate verdier. For hvert element på høyre side, så vil den første forekomsten av dette elementet bli fjernet fra venstre siden:

```elixir
iex> [1,2,2,3,2,3] -- [1,2,3,2]
[2, 3]
```

**Merk:**  Operatoren bruker [nøyaktig sammenligning](../basics/#sammenligningsoperatorer) for å matche verdiene.

### Head / Tail

Når vi jobber med lister er det vanlig å referere til listens head og tail (hode og hale). Head er det første elementet i listen, mens tail er de resterende elementene. Elixir gir oss to hjelpsomme metoder - `hd` og `tl` som vi kan benytte oss av når vi jobber med head og tail i ei liste:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

I tillegg til de tidligere nevnte funksjonene, kan vi også bruke
cons operatoren `|` - Vi kommer tilbake til denne operatoren i en senere leksjon:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tupler (tuples)

Tupler ligner på lister, men er lagret i datamaskinens minne. Dette gjør at vi raskt kan få tilgang til dem, men det gjør også endringer kostbare da tuppelen i sin helhet må kopieres tilbake i minnet.
Vi definerer tupler ved å skrive de mellom klammeparantes:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Tupler brukes ofte til å returnere tilleggsinformasjon fra funksjoner. Bruksnytten av dette vil bli tydeligere når vi starter med mønstergjenkjenning:

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Nøkkelordslister (keyword lists)

Nøkkelord (keywords) og kart (maps) er assosiative kolleksjoner i Elixir.
Ei nøkkelordsliste er ei liste som består av tupler, hvor det første elementet (nøkkelen) er et atom. Nøkkelordslister har samme ytelse som ei vanlig liste:

```elixir
iex> [foo: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:foo, "bar"}, {:hello, "world"}]
[foo: "bar", hello: "world"]
```

I ei nøkkelordsliste er:

+ Nøklene atomer
+ Nøklene ikke unike
+ Nøklene i en rekkefølge

På grunn av dette er det vanlig å bruke nøkkelordslister til å gi forskjellige innstillinger til funksjoner.

## Kart (maps)

I tillegg til nøkkelordslister kan vi også benytte oss av kart. Kart lar oss lagre nøkler med forskjellige typer, og de følger heller ikke en bestemt rekkefølge.
Vi definerer kart ved å bruke syntaksen `%{}`:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

I Elixir 1.2 kan variabler brukes som kartnøkler:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Om et nøkkelduplikat blir lagt til kartet, vil den tidligere verdien bli erstattet:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Som vi kan se fra eksemplene over, er det en spesiell syntaks for kart som kun inneholder atomnøkler:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}

iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

En interessant egenskap ved kart er at de har en egen syntaks for å oppdatere og aksessere atomnøkler:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
iex> map.hello
"world"
```
