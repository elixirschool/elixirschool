---
version: 1.3.1
title: Kolekce
---

Jednotlivé kolekce budeme nazývat jejími anglickými jmeny.
Lists (seznamy), tuples (n-tice), keyword list (seznamy klíčových slov) a maps.

{% include toc.html %}

## Lists (seznamy)

Lists jsou jednoduché kolekce hodnot, které mohou obsahovat více typů; lists můžou taky obsahovat ne-unikátní hodnoty:

```elixir
iex> [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
```

Elixír implementuje kolekci list jako propojené seznamy.
To znamená, že přístup k  velikosti listu je operace, která bude probíhat v lineárním čase (`O(n)`).
Z tohoto důvodu je rychlejší něco do listu předřadit než zařadit:

```elixir
iex> list = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
# Prepending (fast)
iex> ["π" | list]
["π", 3.14, :pie, "Apple"]
# Appending (slow)
iex> list ++ ["Cherry"]
[3.14, :pie, "Apple", "Cherry"]
```

### Lists concatenation

Zřetězení listu používá `++/2` operátor:

```elixir
iex> [1, 2] ++ [3, 4, 1]
[1, 2, 3, 4, 1]
```

A side note about the name (`++/2`) format used above:
In Elixir (and Erlang, upon which Elixir is built), a function or operator name has two components: the name you give it (here `++`) and its _arity_.
Arity is a core part of speaking about Elixir (and Erlang) code.
It is the number of arguments a given function takes (two, in this case).
Arity and the given name are combined with a slash. We'll talk more about this later; this knowledge will help you understand the notation for now.

### List Subtraction

Podpora pro odčítání je s pomocí `--/2` operátoru; je bezpečné odečíst chybějící hodnotu:

```elixir
iex> ["foo", :bar, 42] -- [42, "bar"]
["foo", :bar]
```

Buď pozorný ohledně duplicitních hodnot.
Pro každý element na pravé straně, první případ výskytu bude odstraněn z levé strany:

```elixir
iex> [1,3,3,5,3,5] -- [1,3,5,3]
[3, 5]
```

**Note:** List subtraction uses [strict comparison](../basics/#comparison) to match the values. For example:

```elixir
iex> [2] -- [2.0]
[2]
iex> [2.0] -- [2.0]
[]
```

### Head / Tail

Když používáte listy, je časté pracovat s jejich Head a Tail.
Head je první, počáteční element listu, zatímco Tail je jeho zbytek, to znamná obsahuje všechny elementy listu mimo ten první, ten je Head.
Elixír nabízí dvě pomocné funkce `hd` a `tl` pro práci s těmito částmi:

```elixir
iex> hd [3.14, :pie, "Apple"]
3.14
iex> tl [3.14, :pie, "Apple"]
[:pie, "Apple"]
```

Kromě již zmíněných dvou funkcí `hd` a `tl`, můžete použít [pattern matching](../pattern-matching/) a cons operátor `|` k rozdělení listu na Head a Tail. O tomhle vzoru/patternu se budeme učit i v dalších lekcích:

```elixir
iex> [head | tail] = [3.14, :pie, "Apple"]
[3.14, :pie, "Apple"]
iex> head
3.14
iex> tail
[:pie, "Apple"]
```

## Tuples (n-tice)

Tuples jsou podobné listům, ale jsou uloženy v paměti za sebou.
To dělá přistup k jejich délce rychlý ale modifikaci velmi drahou; nový tuple musí být celý zkopírován do paměti.
Tuple jsou definovány s pomocí složených závorek:

```elixir
iex> {3.14, :pie, "Apple"}
{3.14, :pie, "Apple"}
```

Je časté vidět Tuples té jako mechanismus k dodatečným informacím návratových hodnot funkcí; 
užitečnost toho bude patrnější, až se dostaneme k [pattern matching](../pattern-matching/):

```elixir
iex> File.read("path/to/existing/file")
{:ok, "... contents ..."}
iex> File.read("path/to/unknown/file")
{:error, :enoent}
```

## Keyword lists (seznamy klíčových slov)

Keyword lists a maps jsou v Elixíru asociativní kolekce.
V Elixíru je keyword list speciální list složený ze dvou-elementového tuple, kde první element je atom;
sdílejí výkonnost s listy:

```elixir
iex> [tohle_je_atom: "bar", hello: "world"]
[foo: "bar", hello: "world"]
iex> [{:tohle_je_atom, "bar"}, {:hello, "world"}]
[tohle_je_atom: "bar", hello: "world"]
```

Tři důležité charakteristiky keyword listu:

+ Klíče jsou atomy.
+ Klíče jsou seřazené.
+ Klíče nemusí být unikátní.

Z těhle důvodů se keyword listy nejčastěji používají k předání možností pro funkce.

## Maps

V Elixíru jsou mapy "go-to" možnost pro klíč-hodnota ůložiště.
Narozdíl od keyword listu, umožňují mít klíč jakéhokoliv typu a nejsou seřazeny.

Map můžete definovat pomocí `%{}` syntaxe:

```elixir
iex> map = %{:foo => "bar", "hello" => :world}
%{:foo => "bar", "hello" => :world}
iex> map[:foo]
"bar"
iex> map["hello"]
:world
```

Od Elixíru 1.2 jsou proměnné povoleny jako klíče mapy:

```elixir
iex> key = "hello"
"hello"
iex> %{key => "world"}
%{"hello" => "world"}
```

Jestli je duplikát přidán do mapy, nahradí tak jeho původní hodnotu:

```elixir
iex> %{:foo => "bar", :foo => "hello world"}
%{foo: "hello world"}
```

Jak vidíme z výstupu nahoře, je zde speciální syntaxe pro mapy které mají jako klíče pouze atomy:

```elixir
iex> %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"}
true
```

Dodatečně, je zde i syntaxe k přístupu z "atomového" klíče:

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> map.hello
"world"
```

Další zajímavou vlastností map je to že nabízí svojí vlastní syntaxi pro aktualizaci:
(poznámka: tohle vytvoří novou mapu)

```elixir
iex> map = %{foo: "bar", hello: "world"}
%{foo: "bar", hello: "world"}
iex> %{map | foo: "baz"}
%{foo: "baz", hello: "world"}
```

**Poznámka**: tahe syntaxe funguje pouze por aktualizaci klíče, který už v mapě existuje! Jestliže klíč neexistuje `KeyError` bude vyhozen.

K vytvoření nového klíče použíjte [`Map.put/3`](https://hexdocs.pm/elixir/Map.html#put/3)

```elixir
iex> map = %{hello: "world"}
%{hello: "world"}
iex> %{map | foo: "baz"}
** (KeyError) key :foo not found in: %{hello: "world"}
    (stdlib) :maps.update(:foo, "baz", %{hello: "world"})
    (stdlib) erl_eval.erl:259: anonymous fn/2 in :erl_eval.expr/5
    (stdlib) lists.erl:1263: :lists.foldl/3
iex> Map.put(map, :foo, "baz")
%{foo: "baz", hello: "world"}
```
