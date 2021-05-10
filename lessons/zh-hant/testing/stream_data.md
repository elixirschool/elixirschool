%{
  version: "1.1.0",
  title: "StreamData",
  excerpt: """
  基於案例（example-based）的單元測試函式庫，例如 [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html)，是個極佳的工具來協助驗證程式碼是否以如你預期的方式工作。
但是，基於案例的單元測試有一些缺點：

* 由於並非測試所有輸入情境，因此容易遺漏邊界案例。
* 可以編寫這些測試案例而無需仔細考慮需求。
* 想以多個案例測試單一函數時，這些測試可能會非常冗長。

在本課程中，將探討 [StreamData](https://github.com/whatyouhide/stream_data) 如何幫助我們克服上述一些缺點。
  """
}
---

## 什麼是 StreamData?

[StreamData](https://github.com/whatyouhide/stream_data) 是一個基於屬性（property-based）執行無狀態測試的函式庫。

StreamData 函式庫將執行每個測試 [預設情況下 100 次](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1-options)，每次都使用隨機資料。
如果測試失敗，則 StreamData 會嘗試將輸入[縮小](https://hexdocs.pm/stream_data/StreamData.html#module-shrinking)到導致測試失敗的最小值。
當需要除錯程式碼時，這會很有用的！
如果包含 50 個元素的串列導致函數中斷，並並僅僅其中一個串列元素存在問題，則 StreamData 可以協助辦識有問題的元素。

這個測式函式庫有兩個主要模組。
[`StreamData`](https://hexdocs.pm/stream_data/StreamData.html) 產生隨機資料流；而 
[`ExUnitProperties`](https://hexdocs.pm/stream_data/ExUnitProperties.html) 可以讓你使用產生的資料作為輸入來針對函數執行測試。

你可能會問，不知道實際的輸入內容時，該如何斷定函數的測試是有意義的。繼續往下讀！

## 安裝 StreamData

首先，建立一個新的 Mix 專案
如果需要一些協助，請參考 [新專案](https://elixirschool.com/en/lessons/basics/mix/#new-projects)。

再來，將 StreamData 作為相依性加進 `mix.exs` 檔案中：

```elixir
defp deps do
  [{:stream_data, "~> x.y", only: :test}]
end
```

只需用該函式庫 [安裝指示](https://github.com/whatyouhide/stream_data#installation) 中顯示的 StreamData 版本替換 `x` 和 `y`。

最後，從終端機的命令列執行以下指令：

```
mix deps.get
```

## 使用 StreamData

為了說明 StreamData 的功能，將編寫一些會不斷重複值的簡單公用函數。
假設想要一個類似 [`String.duplicate/2`](https://hexdocs.pm/elixir/String.html#duplicate/2)的函數，只是這個函數能夠複製字串、串列或元組。

### 字串

首先，來編寫一個複製字串的函數。
我們對該函數有哪些需求？

1. 第一個引數應該是一個字串。
這是一個拿來複製用的字串。
2. 第二個引數應該是一個非負值整數。
它顯示將會複製第一個引數多少次。
3. 函數應該回傳一個字串。
新字串只會是不重覆或是重覆多次的原始字串。
4. 如果原始字串是空字串，那傳回的字串應該也是空字串。
5. 如果第二個引數是 `0`，那傳回的字串應該也是空字串。

當執行函數時，會希望它看起來像這樣：

```elixir
Repeater.duplicate("a", 4)
# "aaaa"
```

Elixir 有個函數 `String.duplicate/2`，它可以幫忙處理。
新的 `duplicate/2` 將只會委派給這個函數

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end
end
```

正常情境（happy path）應該很容易用 [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) 進行測試。

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicate/2" do
    test "creates a new string, with the first argument duplicated a specified number of times" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end
  end
end
```

但是，這並不是一個全面的測試。
當第二個引數是 `0` 時應該會發生什麼？
當第一個引數為空字串時，輸出又應該是什麼？
甚至重複一個空字串代表著什麼？
函數應如何使用 UTF-8 字元？
輸入大型字串時函數仍然可以用嗎？

我們還可以編寫更多範例來測試邊界案例和大型字串。
但是，來看看是否能夠用 StreamData 在沒有更多程式碼的情況下更嚴格地測試該函數。


```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do

        assert ??? == Repeater.duplicate(str, times)
      end
    end
  end
end
```

以上程式碼做了什麼？

* 以 [`property`](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109) 取代了 `test`。
這可以記錄正在測試的屬性。
* [`check/1`](https://hexdocs.pm/stream_data/ExUnitProperties.html#check/1) 是一個巨集，它可以設定在測試中使用的資料。
* [`StreamData.string/2`](https://hexdocs.pm/stream_data/StreamData.html#string/2) 產生隨機字串。
可以在呼用 `string/2` 時省略模組名稱，因為 `use ExUnitProperties` 會 [導入 StreamData 函數](https://github.com/whatyouhide/stream_data/blob/v0.4.2/lib/ex_unit_properties.ex#L109)。
* `StreamData.integer/0` 產生隨機整數。
* `times >= 0` 有點像監視子句。
它可以確保在測試中使用的隨機整數大於或等於零。
[`SreamData.positive_integer/0`](https://hexdocs.pm/stream_data/StreamData.html#positive_integer/0) 存在，但這並不是我們想要的，因為 `0` 是函數中可接受的值。

而 `???` 只是一些虛擬碼。
那到底應該要斷言什麼？
我們 _能夠_ 這樣寫：

```elixir
assert String.duplicate(str, times) == Repeater.duplicate(str, times)
```
...但這只是使用實際函數的實現，不是很有用。
還是可以藉由僅驗證字串的長度來放寬斷言條件：

```elixir
expected_length = String.length(str) * times
actual_length =
  str
  |> Repeater.duplicate(times)
  |> String.length()

assert actual_length == expected_length
```

但這樣做總比什麼都沒有好，雖然並不理想。
如果函數產生長度正確的隨機字串，則測試仍會通過。

而有兩個情境是我們確實想驗證的：

1. 函數產生正確長度的字串。
2. 最終輸出的字串內容是一遍又一遍地重複的原始字串。

這只是 [重新定義屬性](https://www.propertesting.com/book_what_is_a_property.html#_alternate_wording_of_properties) 的另一種方法。
現在已經有一些程式碼來驗證情境 1。
為了要驗證情境 2，現在將最終輸出的字串除以原始字串，並確認在串列中剩餘的是零個或多個的空字串。

```elixir
list =
  str
  |> Repeater.duplicate(times)
  |> String.split(str)

assert Enum.all?(list, &(&1 == ""))
```

接著來合併這些斷言：

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end
  end
end
```

當將它與原始測試進行比較時，發現 StreamData 版本的長度是原本的兩倍。
但是，當更多測試案例加入到原始測試中時…

```elixir
defmodule RepeaterTest do
  use ExUnit.Case

  describe "duplicating a string" do
    test "duplicates the first argument a number of times equal to the second argument" do
      assert "aaaa" == Repeater.duplicate("a", 4)
    end

    test "returns an empty string if the first argument is an empty string" do
      assert "" == Repeater.duplicate("", 4)
    end

    test "returns an empty string if the second argument is zero" do
      assert "" == Repeater.duplicate("a", 0)
    end

    test "works with longer strings" do
      alphabet = "abcdefghijklmnopqrstuvwxyz"

      assert "#{alphabet}#{alphabet}" == Repeater.duplicate(alphabet, 2)
    end
  end
end
```

…實際上會發現，StreamData 版本是比較短的。
而且 StreamData 還涵蓋了開發者可能忘記測試的邊界案例。

### 串例

現在，來設計一個重複串例的函數。
並希望函數像這樣運作：

```elixir
Repeater.duplicate([1, 2, 3], 3)
# [1, 2, 3, 1, 2, 3, 1, 2, 3]
```

以下是一個正確的但效率不高的實作：

```elixir
defmodule Repeater do
  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end
end
```

在 StreamData 中的測試可能像下面這樣：

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end
  end
end
```

使用 `StreamData.list_of/1` 和 `StreamData.term/0` 建立隨機長度的串列，其元素可以是任何型別。

像基於屬性的重複字串測試一樣，將新串列的長度與來源串列與其 `times` 的乘積進行比較。
第二個斷言需要解釋一下：

1. 我們將新串列分為多個串列，每個串列與 `list` 具有相同數量的元素。
2. 然後，驗證每段串列是否等於 `list`。

換句話說，我們確保原始串列以正確的次數出現在最終輸出的串列中，並且沒有 _其它_ 元素出現在最終輸出串列中。

為什麼使用條件式？
第一個斷言和條件組合告訴我們原始串列和最終串列都是空的，因此無需進行任何串列比較。
此外，`Enum.chunk_every/2` 要求第二個引數為正數。

### 元組

最後，來實作一個重複元組元素的函數。
該函數應該像這樣運作：

```elixir
Repeater.duplicate({:a, :b, :c}, 3)
# {:a, :b, :c, :a, :b, :c, :a, :b, :c}
```

一種可以採用的方法是將元組轉換為串列，複製串列，然後將資料結構轉換回元組。

```elixir
defmodule Repeater do
  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

那將如何測試呢？
與之前的相比，現在的解決方案會有點不同。
對於字串和串列，可以斷言與最終資料有關長度的部分，同時也斷言有關資料內容的部分。
可以對元組嘗試相同的方法，但是測試用的程式碼也許無法這麼直接地編寫。

思考可以對元組執行的兩種序列操作：

1. 在元組上呼用 `Repeater.duplicate/2` 並將結果轉換為串列。
2. 將元組轉換為串列，然後將串列傳給 `Repeater.duplicate/2`。

這是 Scott Wlaschin 稱為[「不同路徑，相同終點」](https://fsharpforfunandprofit.com/posts/property-based-testing-2/#different-paths-same-destination) 模式的應用。
預期這兩種序列的操作都能產生相同的結果。
現在在測試中使用該方法。

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

## 總結

現在，有了三個函數子句，它們重複字串、串列元素和元組元素。
擁有這些基於屬性的測試，這些測試給我們實作是正確的高度信心。

以下是最終應用程式內的程式碼：

```elixir
defmodule Repeater do
  def duplicate(string, times) when is_binary(string) do
    String.duplicate(string, times)
  end

  def duplicate(list, 0) when is_list(list) do
    []
  end

  def duplicate(list, times) when is_list(list) do
    list ++ duplicate(list, times - 1)
  end

  def duplicate(tuple, times) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Repeater.duplicate(times)
    |> List.to_tuple()
  end
end
```

而這邊是基於屬性的測試：

```elixir
defmodule RepeaterTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "duplicate/2" do
    property "creates a new string, with the first argument duplicated a specified number of times" do
      check all str <- string(:printable),
                times <- integer(),
                times >= 0 do
        new_string = Repeater.duplicate(str, times)

        assert String.length(new_string) == String.length(str) * times
        assert Enum.all?(String.split(new_string, str), &(&1 == ""))
      end
    end

    property "creates a new list, with the elements of the original list repeated a specified number or times" do
      check all list <- list_of(term()),
                times <- integer(),
                times >= 0 do
        new_list = Repeater.duplicate(list, times)

        assert length(new_list) == length(list) * times

        if length(list) > 0 do
          assert Enum.all?(Enum.chunk_every(new_list, length(list)), &(&1 == list))
        end
      end
    end

    property "creates a new tuple, with the elements of the original tuple repeated a specified number of times" do
      check all t <- tuple({term()}),
                times <- integer(),
                times >= 0 do
        result_1 =
          t
          |> Repeater.duplicate(times)
          |> Tuple.to_list()

        result_2 =
          t
          |> Tuple.to_list()
          |> Repeater.duplicate(times)

        assert result_1 == result_2
      end
    end
  end
end
```

可以藉由在終端機的命令列中輸入以下內容來執行測試：

```
mix test
```

請記住，預設情況下，每個所編寫的 StreamData 測試會執行 100 次。
此外，某些 StreamData 產生所需要隨機資料的時間會比其他資料更久。
這些累積而成的影響是，這種類型的測試會比基於案例的單元測試執行得更慢。

即使如此，基於屬性的測試仍是對基於案例的單元測試很好的配套。
它使我們能夠編寫涵蓋各種輸入的簡練測試。
如果不需要在測試執行之間維持狀態，則 StreamData 提供了一種不錯的語法來編寫基於屬性的測試。