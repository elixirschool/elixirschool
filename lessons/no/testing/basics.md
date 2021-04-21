%{
  version: "0.9.1",
  title: "Testing",
  excerpt: """
  Testing er en viktig del i det å utvikle programvare. I denne seksjonen så vil vi se på hvordan vi kan teste vår Elixir kode med ExUnit og best praksiser for hvordan det skal gjøres.
  """
}
---

## ExUnit

Elixirs innebygde test rammeverk er ExUnit og inkluderer alt vi trenger for å kunne teste koden vår. Før vi beveger oss videre er det viktig å merke seg at tester i Elixir er implementert som skripts slik at vi må bruke `.exs` filendelsen. Før vi kan kjøre testene våre så må vi starte ExUnit med `ExUnit.start()`, dette er som oftest gjort i `test/test_helper.exs`

Når vi lager våre eksempel prosjekter, så vil mix alltid lage en veldig enkel test for oss, vi finner den under `test/example_test.exs`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 2
  end
end
```

Vi kan eksekvere testene i prosjektet vårt med `mix test`. Hvis vi gjør det nå, så vil vi se noe slikt:

```shell
Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 0 failures
```

### assert

Hvis du har skrevet tester før så er du kjent med `assert`; i noen rammeverk har du kanskje sett det som `should` eller `expect` som fyller rollen til `assert`.

Når vi bruker `assert` makroen så tester vi at uttrykket er sant. I tilfeller hvor det ikke er sant, så vil en feil bli hevet og vår test vil ikke lykkes. For å teste dette så må vi endre eksempelet og kjøre `mix test`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "the truth" do
    assert 1 + 1 == 3
  end
end
```

Som vil gi oss en annen type beskjed:

```shell
  1) test the truth (ExampleTest)
     test/example_test.exs:5
     Assertion with == failed
     code: 1 + 1 == 3
     lhs:  2
     rhs:  3
     stacktrace:
       test/example_test.exs:6

......

Finished in 0.03 seconds (0.02s on load, 0.01s on tests)
1 tests, 1 failures
```

ExUnit vil fortelle oss eksakt hvor vår antakelse feilet, hva den forventet verdien var, og hva den faktiske verdien var.

### refute

`refute` er for `assert` hva `unless` er for `if`. Bruk `refute` når du trenger å forsikre deg om at et uttrykk alltid er usant.

### assert_raise

Noen ganger så kan det være nødvendig å anta at en feil skal bli hevet. Vi kan gjøre dette med `assert_raise`. Vi vil se et eksempel på `assert_raise` i neste seksjon om Plug.

### assert_received

Elixir applikasjoner består av aktorer/prosesser som sender meldinger til hverandre, derfor så vil vi gjerne sjekke meldingen som blir sendt. Siden ExUnit kjører i sin egen prosess så kan den motta meldinger akkurat som alle andre prosesser og du kan bruke assert på disse meldingen med `assert_received` makroen:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end

defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :ping
  end
end
```

`assert_received` venter ikke på meldinger, men med `assert_receive` så kan du spesifisere en timeout.

### capture_io og capture_log

Det er mulig å få tak i en applikasjons output med `ExUnit.CaptureIO` uten å må endre på original applikasjonen. Du trenger bare å gi en funksjon med det du ønsker å skrive ut:

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog` er ekvivalent med det å sende output til `Logger`.

## Test Setup

I noen instanser så kan det være nødvendig å utføre operasjoner på forhånd før man kjører testene. For å oppnå dete så kan vi bruke `setup` og `setup_all` makroene. `setup` vil kjøre før hver eneste test og `setup_all` kun en gang før alle testene blir kjørt. Det er forventet at både `setup` og `setup_all` vil returnere et tuple i formen av: `{:ok, state}`, hvor state vil være tilgjengelig i testene våre.

Kun som et eksempel, så vil vi endre koden vår til å bruke `setup_all`:

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

## Mocking

Det enkle svaret når det gjelder bruk av mocking i Elixir er: Ikke gjør det. Du kan fort ty til mocker, men det er ikke anbefalt og det for gode grunner.

For en lengre diskusjon på dette:
[Flott artikkel](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/). Tanken er at, istedenfor at man mocker vekk avhengigheter for testing (mock som et *verb*), så er det mange fordeler å eksplisit definere grensesnitt (oppførseler) for kode utenfor din applikasjon, og heller bruke Mock (som et *substantiv*) implementasjoner i din klient kode for testingen.

For å endre implementasjon av din applikasjon kode, så er den foretrukne måten og heller gi modulen som et argument og bruke en standard verdi. Hvis det ikke fungerer, så kan du bruke den innebygde konfigurasjons mekansimen. For å lage disse mock implementasjonene, så trenger du ikke et spesielt mocking bibliotek, kun oppførseler og tilbakekallende funksjoner.


