%{
  version: "1.1.1",
  title: "Kontrol Yapilari",
  excerpt: """
  Burada Elixir'in bize sundugu kontrol yapilarini inceleyecegiz.
  """
}
---

## if and unless

Muhtemelen `if/2` daha once kullandiniz ve eger daha once Ruby de kullandiysaniz muhtemelen `unless/2` ile de tanistiniz. Elixir'de bunlar asagi yukari ayni sekilde calismaktadir fakat bunlar makro olarak tanimlanmistir, dilin bir bileseni olarak degil. Dil icerisince nasil uygulandiklarini [Cekirdek Modul](https://hexdocs.pm/elixir/Kernel.html) icerisinde inceleyebilirsiniz.

Elixir'de, `false` ve `nil` dışında herşey true olarak kabul edilir:

```elixir
iex> if String.valid?("Merhaba") do
...>   "Evet bu bir string"
...> else
...>   "Hayir bu bir string degil"
...> end
"Evet bu bir string"

iex> if "bu bir string midir" do
...>   "evet tabii ki"
...> end
"evet tabii ki"
```

`unless/2` kullanmak ise `if/2` gibidir fakat olumsuz/ters mantikla calisir:

```elixir
iex> unless is_integer("merhaba") do
...>   "Integer degil"
...> end
"Integer degil"
```

## case

Eger birden fazla karsilastirma yapmak gerekirse `case/2` kullanilabilir:

```elixir
iex> case {:ok, "Merhaba Dunya"} do
...>   {:ok, result} -> result
...>   {:error} -> "Hata!"
...>   _ -> "Varsayilan diger tum karsilastirma sonuclari"
...> end
"Merhaba Dunya"
```

`_` degiskeni `case/2` karsilastirmalarinda onemlidir. Kullanilmazsa ve aranilan deger eslesmezse
hata verecektir. Yani aslinda varsayilan deger yok sayilmistir.

```elixir
iex> case :pire do
...>   :deve -> "Deve"
...> end
** (CaseClauseError) no case clause matching: :pire

iex> case :pire do
...>   :deve -> "Deve"
...>   _ -> "Pire"
...> end
"Pire"
```

`_` degiskeni `else` gibi dusunulebilir. Hicbir deger tutmazsa bunu kullan gibi.

`case/2` ornegini bulmaya (pattern-matching) dayandigi icin, onun kurallari gecerlidir. Eger varolan bir deger ile karsilastirma yapacaksiniz, daha once de degindigimiz gibi sapka operatorunu (pin operator) kullanabilirsiniz `^/1`:

```elixir
iex> kek = 3.14
 3.14
iex> case "kirazli kek" do
...>   ^kek -> "Hic lezzetli degil"
...>   kek -> "Iddiaya varim ki #{kek} cok tatlidir"
...> end
"Iddiaya varim ki kirazli kek cok tatlidir"
```

`case/2`nin diger guzel ozelligi de kosullu karsilastirmalari (guard clauses)
desteklemesidir:

_Asagidaki ornek direkt olarak resmi Elixir [Baslarken](http://elixir-lang.org/getting-started/case-cond-and-if.html#case) sayfasindan alinmistir._

```elixir
iex> case {1, 2, 3} do
...>   {1, x, 3} when x > 0 ->
...>     "x sifirdan buyuk"
...>   _ ->
...>     "x sifirdan buyuk degil"
...> end
"x sifirdan buyuk"
```

Elixir resmi dokumanlarindan devamini inceleyebilirsiniz. [Kosullu karsilastimalar (guard clauses) hakkinda daha fazla](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions).

## cond

Degerleri karsilastirmak yerine durumlari karsilastirmak istersek `cond/1` kullanmamiz gerekir; bu diger dillerdeki `else if` veya `elsif`e benzemektedir:

_Asagidaki ornek direkt olarak resmi Elixir [Baslarken](http://elixir-lang.org/getting-started/case-cond-and-if.html#cond) sayfasindan alinmistir._

```elixir
iex> cond do
...>   2 + 2 == 5 ->
...>     "Bu dogru degildir"
...>   2 * 2 == 3 ->
...>     "Bu da degil"
...>   1 + 1 == 2 ->
...>     "Ama bu dogrudur"
...> end
"Ama bu dogrudur"
```

`case/2` ve `cond/1` will raise an error if there is no match.  To handle this, we can define a condition set to `true`:

```elixir
iex> cond do
...>   7 + 1 == 0 -> "Yanlis"
...>   true -> "Varsayilan durum"
...> end
"Varsayilan durum"
```

## with

`with/1` pipe `|` operatorunun kullanilamadigi bazi durumlarda kullanisli olabilir.
`with/1` ifadesi anahtar kelimeler (keywords), uretecler (generators) ve son olarak ifadelerden olusur.

Uretecleri (generators) [liste kapsamlari](../comprehensions/) konusunda inceleyecegiz, fakat simdilik
bilmemiz gereken `<-` ifadesinin sag ve sol taraflarinin karsilastirmasinin [ornegini bulma (pattern matching)](../pattern-matching/) ile yapildigidir.

Basit bir `with/1` ornegiyle basliyoruz:

```elixir
iex> user = %{isim: "Mete", soyisim: "Unal"}
%{isim: "Mete", soyisim: "Unal"}
iex> with {:ok, first} <- Map.fetch(user, :isim),
...>      {:ok, last} <- Map.fetch(user, :soyisim),
...>      do: last <> ", " <> first
"Unal, Mete"
```

Bu ifadenin karsiliginin olmadigi durumda, eslesmeyen deger geri donecektir:

```elixir
iex> user = %{isim: "Mete"}
%{isim: "Mete"}
iex> with {:ok, first} <- Map.fetch(user, :isim),
...>      {:ok, last} <- Map.fetch(user, :soyisim),
...>      do: last <> ", " <> first
:error
```

Simdi de `with/1` olmayan daha buyuk bir kod ornegini inceleyip, nasil daha iyi yazilabilir onu inceleyelim:

```elixir
case Repo.insert(changeset) do
  {:ok, user} ->
    case Guardian.encode_and_sign(user, :token, claims) do
      {:ok, token, full_claims} ->
        important_stuff(token, full_claims)

      error ->
        error
    end

  error ->
    error
end
```

Yukaridaki kodu `with/1` ile yazdigimizda daha kisa, basit ve kolay anlasilir bir kod obegi elde edecegiz.

```elixir
with {:ok, user} <- Repo.insert(changeset),
     {:ok, token, full_claims} <- Guardian.encode_and_sign(user, :token, claims) do
  important_stuff(token, full_claims)
end
```


Elixir 1.3 ile birlikte `with/1` ile birlikte `else` desteklenmeye baslanmistir.

```elixir
import Integer

m = %{a: 1, c: 3}

a =
  with {:ok, number} <- Map.fetch(m, :a),
       true <- is_even(number) do
    IO.puts("#{number}, 2 ile bolumu : #{div(number, 2)}")
    :cift
  else
    :error ->
      IO.puts("Bu deger mapte mevcut degil")
      :error

    _ ->
      IO.puts("tek sayi")
      :tek
  end
```

`case`teki gibi ornegini bulma (pattern-matching) sayesinde hatalar indirgenmektedir.
