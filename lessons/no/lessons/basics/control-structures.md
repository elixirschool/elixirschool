%{
  version: "0.9.1",
  title: "Kontrollstrukturer",
  excerpt: """
  I denne leksjonen skal vi ta en nærmere titt på de forskjellige kontrollstrukturene Elixir har tilgjengelig.
  """
}
---

## `if` og `unless`

Sannsynligheten er stor for at du har vært borti `if/2` tidligere, og har du tidligere programmert i Ruby kjenner du til `unless/2`. De virker på samme måte i Elixir, men er her definert som makroer, og ikke språk konstruksjoner. Du kan finne implementeringen i [Kernel modulen](https://hexdocs.pm/elixir/Kernel.html).

Det er verdt å merke seg at kun verdien `nil` og den boolske verdien `false` er "usant" i Elixir.

```elixir
iex> if String.valid?("Hello") do
...>   "Valid string!"
...> else
...>   "Invalid string."
...> end
"Valid string!"

iex> if "a string value" do
...>   "Truthy"
...> end
"Truthy"
```

`unless/2` er motsatt av `if/2` - Ellers fungerer den på samme måte:

```elixir
iex> unless is_integer("hello") do
...>   "Not an Int"
...> end
"Not an Int"
```

## `case`

Om vi trenger å sammenligne mot forskjellige mønster, kan vi bruke `case`:

```elixir
iex> case {:ok, "Hello World"} do
...>   {:ok, result} -> result
...>   {:error} -> "Uh oh!"
...>   _ -> "Catch all"
...> end
"Hello World"
```

Variabelen `_` er en viktig del av `case`. Uten den vil funksjonen gi oss ei feilmelding, hvis det ikke finnes en match.

```elixir
iex> case :even do
...>   :odd -> "Odd"
...> end
** (CaseClauseError) no case clause matching: :even

iex> case :even do
...>   :odd -> "Odd"
...>   _ -> "Not Odd"
...> end
"Not Odd"
```

Variabelen `_` blir som `else` og vil matche "alt annet".

Siden `case` avhenger av mønstersammenligning, gjelder de samme reglene og restriksjonene. Hvis du ønsker å sammenligne med en eksisterende variabel, må festeoperatoren `^` benyttes:

```elixir
iex> pie = 3.14 
3.14
iex> case "cherry pie" do
...>   ^pie -> "Not so tasty"
...>   pie -> "I bet #{pie} is tasty"
...> end
"I bet cherry pie is tasty"
```

En annen fiffig funksjon i `case`, er dens støtte for beskyttelsesklausuler (guard clauses):

_Dette eksemplet er hentet direkte fra den offisielle Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) guiden._


```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "Will match"
...>   _ ->
...>     "Won't match"
...> end
"Will match"
```

Se den offisielle dokumentasjonen for [Tillatte uttrykk i beskyttelsesklausuler](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).


## `cond`

Hvis vi trenger å sammenligne forhold, og ikke verdier, kan vi bruke `cond`.
Denne funksjonen kan sammenlignes med `else if` eller `elsif` i andre programmeringsspråk:

_Dette eksemplet er hentet direkte fra den offisielle Elixir [Getting Started](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) guiden._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "This will not be true"
...>   2 * 2 == 3 ->
...>     "Nor this"
...>   1 + 1 == 2 ->
...>     "But this will"
...> end
"But this will"
```

På samme måte som `case`, vil `cond` gi oss ei feilmelding hvis det ikke er noen match. Vi kan håndtere dette ved å definere en betingelse til `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Incorrect"
...>   true -> "Catch all"
...> end
"Catch all"
```

## `with`

`with` er nyttig hvis vi for eksempel benytter oss av et nestet `case` statement eller forhold som ikke enkelt kan transporteres sammen. `with` består av nøkkelord, generatorer og et utrykk.

Vi vil diskutere generatorer nærmere i en senere leksjon, men alt vi trenger å vite nå er at de benytter mønstersammenligning til å sammenligne den høyre siden `<-` med den venstre.

Vi starter med et enkelt eksempel av `with`:

```elixir
iex> user = %{first: "Sean", last: "Callan"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
"Callan, Sean"
```

Hvis utsagnet ikke kan sammenlignes, vil den ikke-sammenlignbare verdien returneres:

```elixir
iex> user = %{first: "doomspork"}
%{first: "doomspork"}
iex> with {:ok, first} <- Map.fetch(user, :first),
...>      {:ok, last} <- Map.fetch(user, :last),
...>      do: last <> ", " <> first
:error
```

La oss nå se på et større eksempel uten `with`, og deretter se hvordan vi kan refaktorere det:


```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, jwt, full_claims} ->
        important_stuff(jwt, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Når vi introduserer `with` til eksemplet, ender vi opp med kode som er enklere å lese, og som består av færre linjer:

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, jwt, full_claims} <- Guardian.encode_and_sign(user, :token, claims),
     do: important_stuff(jwt, full_claims)
```

