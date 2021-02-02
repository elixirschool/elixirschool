%{
  version: "1.2.1",
  title: "基礎",
  excerpt: """
  入門、基本資料型別和操作。
  """
}
---

## 入門

### 安裝 Elixir

有關每個作業系統的安裝說明，請參見 elixir-lang.org 網站中的 [Installing Elixir](http://elixir-lang.org/install.html) 指南。

在安裝 Elixir 後，您可以簡便確認安裝的版本。

    % elixir -v
    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Elixir {{ site.elixir.version }}

### 試用互動模式

Elixir 自帶 IEx，一個互動模式 shell，可以讓我們隨時計算 Elixir 表達式。

輸入 `iex` 開始使用：

    Erlang/OTP {{ site.erlang.OTP }} [erts-{{ site.erlang.erts }}] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

    Interactive Elixir ({{ site.elixir.version }}) - press Ctrl+C to exit (type h() ENTER for help)
    iex>

讓我們繼續嘗試，現在輸入幾個簡單的表達式：

```elixir
iex> 2+3
5
iex> 2+3 == 5
true
iex> String.length("The quick brown fox jumps over the lazy dog")
43
```

如果你不了解每一個式子，不用擔心，但希望你有些概念了。

## 基本資料型別

### 整數

```elixir
iex> 255
255
```

內建支援二進位、八進位和十六進位：

```elixir
iex> 0b0110
6
iex> 0o644
420
iex> 0x1F
31
```

### 浮點數

Elixir 中，浮點數的小數點前至少需要一位數字；浮點數具有64位元雙精度，並支援以科學記號 `e` 表示指數值：

```elixir
iex> 3.14
3.14
iex> .14
** (SyntaxError) iex:2: syntax error before: '.'
iex> 1.0e-10
1.0e-10
```

### 布林

Elixir 支援 `true` 和 `false` 做為布林的值；除了 `false` 和 `nil`，一切為真。

```elixir
iex> true
true
iex> false
false
```

### Atoms

Atom 是一個常數，其名稱是它的值。
如果你熟悉 Ruby，這與 Ruby 的符號 (Symbols) 是同義詞：

```elixir
iex> :foo
:foo
iex> :foo == :bar
false
```

布林的 `true` 和 `false`  在 atoms 中也分別是 `:true` 和 `:false`。

```elixir
iex> is_atom(true)
true
iex> is_boolean(:true)
true
iex> :true === true
true
```

Elixir 中的模組名稱也是 atoms。 `MyApp.MyModule` 是一個有效的 atom， 即使這樣的模組沒有被宣告過。

```elixir
iex> is_atom(MyApp.MyModule)
true
```

Atoms 也用於引用來自 Erlang 函式庫的模組，其包括內建的模組。

```elixir
iex> :crypto.strong_rand_bytes 3
<<23, 104, 108>>
```

### 字串

Elixir 中的字串為 UTF-8 編碼，並以雙引號圍繞。

```elixir
iex> "Hello"
"Hello"
iex> "dziękuję"
"dziękuję"
```

字串支援換行和轉義序列：

```elixir
iex> "foo
...> bar"
"foo\nbar"
iex> "foo\nbar"
"foo\nbar"
```

Elixir 還包括更複雜的資料型別。
當學習 [群集](../collections/) 和 [函數](../functions/) 時將進一步了解這些。

## 基本運算

### 算術運算 (Arithmetic)

Elixir 如你所料支援基本運算子 `+` 、 `-` 、 `*` 和 `/`。
重要的是記住 `/` 將永遠回傳一個浮點數：

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

如果您需要整數除法或除法餘數（即模數），Elixir 以兩個有用的功能來實現：

```elixir
iex> div(10, 5)
2
iex> rem(10, 3)
1
```

### 布林運算 (Boolean)

Elixir 提供 `||` 、 `&&` 和 `!` 布林運算子。
這些支援任何型別：

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

有三個運算子的第一個引數 (argument) _必須_ 為布林型別 (`true` 或 `false`)：

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

註：Elixir 的 `and` 和 `or` 實際上映射到 Erlang 中的 `andalso` 和 `orelse`。

### 比較運算 (Comparison)

Elixir 帶有我們習慣的所有比較運算子： `==` 、 `!=` 、 `===` 、 `!==` 、 `<=` 、 `>=` 、 `<` 和 `>`。

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

為了嚴謹比較整數和浮點數，請使用 `===`：

```elixir
iex> 2 == 2.0
true
iex> 2 === 2.0
false
```

Elixir 的一個重要特點是可以比較任意兩種型別；這在排序中特別有用。我們不需要記住排序順序，但還是要注意它的重要性:

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

這個特點可能會導致一些詭異但合乎語法，而您在其他語言中找不到的的比較運算：

```elixir
iex> :hello > 999
true
iex> {:hello, :world} > [1, 2, 3]
false
```

### 字串插值 (String Interpolation)

如果您使用 Ruby，Elixir 中的字串插值方法將會很熟悉：

```elixir
iex> name = "Sean"
iex> "Hello #{name}"
"Hello Sean"
```

### 字串串接 (String Concatenation)

字串串接使用 `<>` 運算子：

```elixir
iex> name = "Sean"
iex> "Hello " <> name
"Hello Sean"
```