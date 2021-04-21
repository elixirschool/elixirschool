---
version: 1.1.2
title: Temeller
---

Temel veri tipleri ve temel operasyonlar ile başlayalım.

{% include toc.html %}

## Başlarken

### Elixir Kurulumu

Her işletim sistemi için uygun kurulum talimatlarını elixir-lang.org sitesinde [Elixir Kurulumu](http://elixir-lang.org/install.html) bulabilirsiniz.

Elixir yüklendikten sonra aşağıdaki komut ile kolayca kurulu sürümü doğrulayabilirsiniz.

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### Etkileşimli (İnteraktif) Modu Deneyelim

Elixir `iex` isimli, Elixir ifadelerini kolayca çalıştırmanız için etkileşimli (interaktif) bir kabuk ile birlikte gelir.

`iex` komutunu çalıştıralım:

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

Birkaç basit ifade yazmayı deneyelim:

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

Henüz birşey anlamadıysanız endişe etmeyin, ama umarım bir fikir edinmişsinizdir.

## Temel Veri Tipleri

### Tam Sayılar (Integers)

```elixir
iex> 255
255
```

Binary, octal, and hexadecimal sayı desteği dahili olarak gelmektedir:

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### Ondalıklı Sayılar (Floats)

Elixir de ondaklı sayılarda en az bir rakamdan sonra ondalıklı sayı gelmelidir. Toplamda 64 bit tutulan çifte duyarlı (double precision) sayılarını destekler:

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```


### Mantıksal Tipler (Booleans)

Elixir de mantıksal `true` ve `false` değerleri bulunur; `false` ve `nil` dışında herşey true olarak kabul edilir:

```elixir
iex> true
true
iex> false
false
```

### Atomlar

Bir atom, değeri adı olan bir sabittir. Eğer Ruby'e aşina iseniz sembollere benzer:

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

Mantıksal `true` ve `false` değerleri aynı zamanda atom olarak sırasıyla `:true` ve `:false` olarak ifade edilir.

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Modül isimleri aynı zamanda Elixir içerisinde birer atomdur. `MyApp.MyModule` geçerli bir atomdur. Hatta böyle bir modül henüz beyan edilmemişse bile.

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atomlar aynı zamanda Erlang kütüphanelerine erişmek için de kullanılır.
```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### Stringler

Elixir içinde stringler UTF-8 olarak kodlanmış ve çift tırnak ile çevrelenmiştir:

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

Stringler line-break ve escape karakteri destekler:

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir aynı zamanda karmaşık veri tipleri içerir. Koleksiyonlar ve Fonksiyonları öğrendiğimiz zaman bu konuda daha çok şey öğreneceğiz:

## Temel Operasyonlar

### Aritmatik

Elixir `+` `-`,`*` ve `/` olarak beklediğimiz temel operatörleri destekler. Önemli bir not, `/` operatörü her zaman ondalıklı tipinde döner:

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

Eğer tamsayılarda bölme veya kalan bulma işlemleri yapmak gerekiyorsa, Elixir bunun için iki yardımcı fonksiyon ile birlikte gelmektedir:

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### Mantıksal Operatörler (Boolean)

Elixir `||`, `&&`, ve `!` mantıksal operatörleri sağlar. Bunlar her tipi destekler:

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

İlk argümanı mutlaka mantıksal değer (`true` yada `false`) olması gereken 3 ek operatör bulunmaktadır:

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

### Karşılaştırmalar

Elixir birçok karşılaştırma operatörü ile birlikte gelir: `==`, `!=`, `===`, `!==`, `<=`, `>=`, `<` ve `>`.

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

Tamsayı ve ondalıklı sayılarıda kesin tip karşılaştırmalar için `===` operatörü kullanılabilir:

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Elixir'in önemli bir özelliği de, iki değişken tipini karşılaştırabiliyor olmasıdır. Sıralama işlemleri için kolaylık sağlar. Aşağıdaki sıralamayı ezberlemek gerekmez ama bunun farkında olmakta yarar vardır:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Tüm bunlar başka dillerde bulamayacağınız, ilginç fakat tamamen geçerli bir sonuca yol açar:

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### Stringlere Şablonları (Interpolation)

Eğer siz Ruby kullandıysanız, string şablonları (interpolation) Elixirin yöntemi tanıdık gelecektir:

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### Stringleri Birbirine Ekleme (Concatenation)

Stringler birbirine `<>` operatoru kullanılarak bağlanabilir:

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```
