%{
  version: "1.1.0",
  title: "Mix",
  excerpt: """
  在能夠潛入 Elixir 的深處之前，首先需要了解 Mix。
如果你熟悉 Ruby，Mix 就是 Bundler、RubyGems 和 Rake 的綜合。
這是任何 Elixir 專案的關鍵組成部分，在本課中，我們將會探索其幾個重要功能。
在目前環境中要查找 Mix 提供的所有功能，請執行 `mix help`。

到現在為止，我們一直在 `iex` 裡面工作，這有其局限性。
為了構建一些實質性的東西，我們需要把程式碼分成許多資料夾來有效地管理它們；Mix 讓我們在一個專案中能夠做到這一點。
  """
}
---

## 新增專案 (New Projects)

當我們準備創建一個新的 Elixir 專案時，Mix 可以通過 `mix new` 指令來輕鬆實現。
這將產生專案資料夾結構和所需模板。
這異常的簡單，所以現在開始吧：

```bash
$ mix new example
```

從輸出訊息中可以看到 Mix 產生的目錄和一些樣板檔案：

```bash
* creating README.md
* creating .gitignore
* creating .formatter.exs
* creating mix.exs
* creating lib
* creating lib/example.ex
* creating test
* creating test/test_helper.exs
* creating test/example_test.exs
```

在本課中，我們將把注意力集中在 `mix.exs` 上。
在這裡我們將設置我們的應用程式、耦合性、系統環境和版本。
在你最喜歡的文字編輯器中打開這個檔案，你將會看到類似這樣的內容 (簡潔起見刪除註解)：

```elixir
defmodule Example.Mix do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
```

我們要看的第一部分是 `project`。
在這裡，我們定義了應用程式的名字 (`app`) 和指定了使用版本 (`version`)。我們同時也指定 Elixir 的版本 (`elixir`) 以及耦合性 (`deps`)。

應用程式檔案的生成過程中將使用部分的 `application` ，我們將在下面介紹。

## 互動 (Interactive)

在應用程式中可能需要用到 `iex`。
謝天謝地，Mix 讓一切變得簡單，
可以用以下的方式開始一個新的 `iex` 對話：

```bash
$ cd example
$ iex -S mix
```

以這種方式啟動的  `iex` 會將您的應用程式和耦合性載入到當前的運行環境裡。

## 編譯 (Compilation)

Mix 是有智慧的，當需要時會自動編譯你所改變的部份，不過有時仍必須手動指定要編譯的專案。
在本節中，將介紹如何編譯專案以及被編譯的內容。

要編譯一個 Mix 專案，只需在的根目錄下執行 `mix compile` ：
**註：一個專案的 Mix 工作只能從其根目錄中使用，否則只有全域的 Mix 工作可用。**

```bash
$ mix compile
```

現在專案中沒有太多的東西，所以沒什麼太令人興奮的輸出，但是它應該能夠成功編譯完成：

```bash
Compiled lib/example.ex
Generated example app
```

當編譯一個專案時 Mix 會創設一個 `_build`。
如果這時候查看 `_build` 目錄內部，會看到編譯好的應用程式：`example.app`。

## 管理耦合性 (Dependencies)

我們的專案目前沒有任何耦合性，但很快就會有了，所以我們將繼續說明如何定義耦合性並存取它們。

要加入一個新的耦合性，我們首先需要將它加入到 `deps` 的 `mix.exs` 中。
耦合性列表是由具有兩個必需值和一個選項的 tuples 組成：耦合性 package 的名字以一個 atom 表示，接在後面的是代表版本數的字串，最後是其它可選的選項。

對於這個例子，讓我們看一下具有耦合性的專案，像是 [phoenix_slim](https://github.com/doomspork/phoenix_slim)：

```elixir
def deps do
  [
    {:phoenix, "~> 1.1 or ~> 1.2"},
    {:phoenix_html, "~> 2.3"},
    {:cowboy, "~> 1.0", only: [:dev, :test]},
    {:slime, "~> 0.14"}
  ]
end
```

正如你從上面的耦合性中可以看出的那樣，只有在開發和測試時才需要 `cowboy` 耦合性。

一旦我們定義好耦合性，就只剩最後一步：獲取那些耦合性。
這與 `bundle install` 的功用類似：

```bash
$ mix deps.get
```

完成了！我們已經定義並獲取專案需要的耦合性。
現在已經準備好隨時都能加入新的耦合性。

## 系統環境 (Environments)

Mix 和 Bundler 很像，支援不同的使用環境 (environments)。
mix 具有以下三種立即可用的環境：

+ `:dev` — 預設的使用環境。
+ `:test` — 在 `mix test` 中使用。下一課中會進一步討論。
+ `:prod` — 用於將應用程式送交到 production。

想存取目前使用環境可以使用 `Mix.env`。
且正如所預料的，環境可以經由環境變數 `MIX_ENV` 來改變：

```bash
$ MIX_ENV=prod mix compile
```
