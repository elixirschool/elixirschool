---
version: 1.0.1
title: IEx Yardımcıları
---

{% include toc.html %}

## Genel Bakış

Elixir kullanmaya başladığınızda, IEx en yakın arkadaşınız olacaktır.
Bu bir REPL(Read–Eval–Print Loop)'olarak geçer, ancak yeni kodu keşfederken veya kendi işinizi geliştirirken hayatınızı kolaylaştıracak birçok gelişmiş özelliğe sahip olmanızı sağlar
Bu derste üzerinden geçeceğimiz bir takım yerleşik(built-in) yardımcılar var.

### Otomatik tamamlama

Komut satırında çalışırken, çoğu zaman kendinizi bilmediğiniz yeni bir modül kullanırken bulacaksınız.
Kullanabileceğiniz şeylerin bazılarını anlamak için otomatik tamamlama özelliğini kullanabilirsiniz.
Sadece bir modül adını yazıp ardından `.` yazdıktan sonra `Tab` tuşuna basmanız yeterlidir:

```elixir
iex> Map. # press Tab
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
replace!/3           replace/3            split/2
take/2               to_list/1            update!/3
update/4             values/1
```
Ve şimdi sahip olduğumuz function'ları ve onların gerekliliklerini biliyoruz!

### `.iex.exs`

IEx her başlatıldığında bir `.iex.exs` yapılandırma dosyası arar. Geçerli dizinde yoksa kullanıcının ana dizininde bulunan (~/.iex.exs) yedek olarak kullanılacaktır.

Bu dosyada tanımlanan yapılandırma seçenekleri ve kod IEx kabuğu başlatıldığında kullanılabilir. Örneğin, IEx'de bazı yardımcı fonksiyonları kullanmak istersek, `.iex.exs` dosyasını açıp bazı değişiklikler yapabiliriz.

Birkaç yardımcı işlev içeren bir modül ekleyerek başlayalım:

```elixir
defmodule IExHelpers do
  def whats_this?(term) when is_nil(term), do: "Type: Nil"
  def whats_this?(term) when is_binary(term), do: "Type: Binary"
  def whats_this?(term) when is_boolean(term), do: "Type: Boolean"
  def whats_this?(term) when is_atom(term), do: "Type: Atom"
  def whats_this?(_term), do: "Type: Unknown"
end
```

Artık IEx'i çalıştırdığımızda baştan beri IExHelpers modülümüzü kullanacağız. IEx'i açın ve yeni oluşturduğumuz programlarımızı deneyelim:

```elixir
$ iex
{{ site.erlang.OTP }} [{{ site.erlang.erts }}] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
iex> IExHelpers.whats_this?("a string")
"Type: Binary"
iex> IExHelpers.whats_this?(%{})
"Type: Unknown"
iex> IExHelpers.whats_this?(:test)
"Type: Atom"
```

Görebildiğimiz gibi, helpers modüllerimizi çağırmak veya import etmek için özel bir şeyler yapmak zorunda değiliz, IEx bunu bizim için zaten halledecektir.


### `h`

`h`, Elixir komut satırının bize verdiği en faydalı araçlardan biridir.
Dilin dokümantasyonu için muhteşem birinci sınıf desteği sayesinde, herhangi bir kodun dokümanlarına bu yardımcı araç kullanılarak ulaşılabilir.
Nasıl çalıştığına bakalım:

```elixir
iex> h Enum
                                      Enum

Provides a set of algorithms that enumerate over enumerables according to the
Enumerable protocol.

┃ iex> Enum.map([1, 2, 3], fn(x) -> x * 2 end)
┃ [2, 4, 6]

Some particular types, like maps, yield a specific format on enumeration. For
example, the argument is always a {key, value} tuple for maps:

┃ iex> map = %{a: 1, b: 2}
┃ iex> Enum.map(map, fn {k, v} -> {k, v * 2} end)
┃ [a: 2, b: 4]

Note that the functions in the Enum module are eager: they always start the
enumeration of the given enumerable. The Stream module allows lazy enumeration
of enumerables and provides infinite streams.

Since the majority of the functions in Enum enumerate the whole enumerable and
return a list as result, infinite streams need to be carefully used with such
functions, as they can potentially run forever. For example:

┃ Enum.each Stream.cycle([1, 2, 3]), &IO.puts(&1)
```

Ve şimdi bunu komut satırımızda otomatik tamamlama özellikleri ile birleştirebiliriz.
Map'i ilk kez kullandığınızı düşünün:

```elixir
iex> h Map
                                      Map

A set of functions for working with maps.

Maps are key-value stores where keys can be any value and are compared using
the match operator (===). Maps can be created with the %{} special form defined
in the Kernel.SpecialForms module.

iex> Map.
delete/2             drop/2               equal?/2
fetch!/2             fetch/2              from_struct/1
get/2                get/3                get_and_update!/3
get_and_update/3     get_lazy/3           has_key?/2
keys/1               merge/2              merge/3
new/0                new/1                new/2
pop/2                pop/3                pop_lazy/3
put/3                put_new/3            put_new_lazy/3
split/2              take/2               to_list/1
update!/3            update/4             values/1

iex> h Map.merge/2
                             def merge(map1, map2)

Merges two maps into one.

All keys in map2 will be added to map1, overriding any existing one.

If you have a struct and you would like to merge a set of keys into the struct,
do not use this function, as it would merge all keys on the right side into the
struct, even if the key is not part of the struct. Instead, use
Kernel.struct/2.

Examples

┃ iex> Map.merge(%{a: 1, b: 2}, %{a: 3, d: 4})
┃ %{a: 3, b: 2, d: 4}
```

Gördüğünüz gibi modülün bir parçası olarak hangi fonksiyonların mevcut olduğunu bulamadık, ancak birçoğunda gördük ki örnek kullanımı içeren fonksiyon belgeleri var.

### `i`

Yeni kullanacağımız `i` yardımcı aracı hakkında biraz daha fazla bilgi sahibi olabilmek için `h` aracını kullanalım:

```elixir
iex> h i

                                  def i(term)

Prints information about the given data type.

iex> i Map
Term
  Map
Data type
  Atom
Module bytecode
  /usr/local/Cellar/elixir/1.3.3/bin/../lib/elixir/ebin/Elixir.Map.beam
Source
  /private/tmp/elixir-20160918-33925-1ki46ng/elixir-1.3.3/lib/elixir/lib/map.ex
Version
  [9651177287794427227743899018880159024]
Compile time
  no value found
Compile options
  [:debug_info]
Description
  Use h(Map) to access its documentation.
  Call Map.module_info() to access metadata.
Raw representation
  :"Elixir.Map"
Reference modules
  Module, Atom
```

Şimdi, kaynağın nerede tutulduğunu ve nereye referans sağladığını, modüller de dahil olmak üzere `maps` hakkında bir sürü bilgiye erişebiliriz. Özel ve farklı veri türlerini ve yeni fonksiyonları keyfetmek işimize oldukça yarayacaktır

Belli başlı konular şu şekildedir:

- Bir atom veri tipi
- Kaynak kod nerede
- Sürüm ve derleme seçenekleri
- Genel bir açıklama
- Nasıl erişilir?
- Hangi diğer modülleri referans gösteriyor?

Bu size çok çalışmanızı sağlasa da kör olmaktan kurtarır.

### `r`

Belli bir modülü yeniden derlemek istersek `r` yardımcı aracını kullanabiliriz. Diyelim ki, bazı kodları değiştirdik ve eklediğimiz yeni bir fonksiyonu çalıştırmak istedik. Bunu yapmak için değişikliklerimizi kaydettirip r ile yeniden derlemeliyiz:

```elixir
iex> r MyProject
warning: redefining module MyProject (current version loaded from _build/dev/lib/my_project/ebin/Elixir.MyProject.beam)
  lib/my_project.ex:1

{:reloaded, MyProject, [MyProject]}
```

### `s`

`s` ile, bir modül veya fonksiyon için tip özellikleri bilgisini alabiliriz. Bunu, ne beklediğini bilmek için kullanabiliriz:

```elixir
iex> s Map.merge/2
@spec merge(map(), map()) :: map()

# it also works on entire modules
iex> s Map
@spec get(map(), key(), value()) :: value()
@spec put(map(), key(), value()) :: map()
# ...
@spec get(map(), key()) :: value()
@spec get_and_update!(map(), key(), (value() -> {get, value()})) :: {get, map()} | no_return() when get: term()
```

### `t`

`t` yardımcı aracı, belirli bir modülde kullanılabilen tipleri hakkında bilgi verir:

```elixir
iex> t Map
@type key() :: any()
@type value() :: any()
```

Ve şimdi biz biliyoruz ki `Map`, uygulanmasında anahtar ve değer tipleri tanımlıyor.
Gidip `Maps` kaynağına bakarsak:

```elixir
defmodule Map do
# ...
  @type key :: any
  @type value :: any
# ...
```

Bu en basit örnektir, uygulama başına anahtar ve değerlerin herhangi bir tip olabileceğini belirtir, gerektiği zaman tiplerin ne olduğunu bilmek işimize yarayacaktır.

Tüm bu yerleşik özelliklerden yararlanarak kodu kolayca keşfedebilir ve işlerin nasıl yürüdüğü konusunda daha fazla bilgi edinebiliriz. IEx, geliştiricileri güçlendiren çok güçlü ve sağlam bir yardımcı araçtır. Araç kutusu(toolbox) içerisindeki bu araçlar sayesinde yeni şeyler keşfetmek ve üretmek daha da eğlenceli olabilir!