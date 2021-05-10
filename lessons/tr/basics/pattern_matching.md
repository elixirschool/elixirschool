---
version: 1.0.1
title: Ornegini Bulma
---

Ornegini Bulma (Pattern matching) Elixir'in guclu yanlarindan birisidir. Basit degerleri, veri yapilarini (data structures) ve hatta fonksiyonlari (functions) eslestirmeye yarar. Simdi ornegini bulma (pattern matching) nasil kullanilir onu ogrenecegiz.

{% include toc.html %}

## Eslestirme Operatoru (Match Operator)

Ters kose olmaya hazir misiniz? Elixir'de, `=` operatoru bir eslestirme operatorudur. Esittir isareti tum denklemi bir esitlige donusturur ve Elixir soldaki degerleri sagdaki ile eslestirir. Eger eslestirme dogru ise esitligin degeri sonuc olarak doner. Aksi takdirde hata doner. Isterseniz inceleyelim:

```elixir
iex> x = 1
1
```

Now let's try some simple matching:

```elixir
iex> 1 = x
1
iex> 2 = x
** (MatchError) no match of right hand side value: 1
```

Simdi de koleksiyonlar (collections) ile deneyelim:

```elixir
# Lists
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [1, 2, 3] = list
[1, 2, 3]
iex> [] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

iex> [1 | tail] = list
[1, 2, 3]
iex> tail
[2, 3]
iex> [2 | _] = list
** (MatchError) no match of right hand side value: [1, 2, 3]

# Demetler (Tuples)
iex> {:ok, value} = {:ok, "Basarili!"}
{:ok, "Basarili!"}
iex> value
"Basarili!"
iex> {:ok, value} = {:error}
** (MatchError) no match of right hand side value: {:error}
```

## Sapka Operatoru (Pin Operator)

Eslestirme operatoru, esitligin sol tarafinda bir degisken varsa eslestirme yapar. Fakat bazi durumlarda bu yeniden esleme islemi istenmemektedir. Bu gibi kosullarda, sapka operatoru (pin operator) kullanilir: `^`
Degiskenin yanina sapka koyuldugunda "varolan degeri eslestir, yeni deger atama" demektir. Nasil calistigina goz atalim isterseniz:


```elixir
iex> x = 1
1
iex> ^x = 2
** (MatchError) no match of right hand side value: 2
iex> {x, ^x} = {2, 1}
{2, 1}
iex> x
2
```

Sapka operatoru (pin operator) Elixir 1.2'de haritalar (map keys) ve fonksiyonlar icin kullanilmaya baslanmistir.

```elixir
iex> anahtar = "merhaba"
"merhaba"
iex> %{^anahtar => deger} = %{"merhaba" => "dunya"}
%{"merhaba" => "dunya"}
iex> deger
"dunya"
iex> %{^anahtar => deger} = %{:merhaba => "dunya"}
** (MatchError) no match of right hand side value: %{merhaba: "dunya"}
```

Sapka operatorunun fonksiyonlarla beraber kullanilma sekli:

```elixir
iex> greeting = "Merhaba"
"Merhaba"
iex> greet = fn
...>   (^greeting, isim) -> "Selam #{isim}"
...>   (greeting, isim) -> "#{greeting}, #{isim}"
...> end
#Function<12.54118792/2 in :erl_eval.expr/5>
iex> greet.("Merhaba","Mete")
"Selam Mete"
iex> greet.("Gunaydin","Mete")
"Gunaydin, Mete"
```
