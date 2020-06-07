---
version: 2.0.1
title: Distillery（基礎）
---

Distillery 是純粹使用 Elixir 編寫的發布版本管理工具。它可以生成幾乎不需要配置就可以部署到其他地方的發布版本。

## 什麼是一個發布版本？

一個發布版本是一個包含已編譯的 Erlang/Elixir 程式碼套件（例如 [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) [位元組碼](https://en.wikipedia.org/wiki/Bytecode)）。它還提供了啟動應用程式所需的所有腳本。

> 編寫一個或多個應用程式後，可能會希望使用這些應用程式與 Erlang/OTP 應用程式子集來建立一個完整系統。這稱為一個發布版本。ー [Erlang 文件](http://erlang.org/doc/design_principles/release_structure.html)

> 發布版本可以簡化部署：它們是獨立（self-contained）的，並提供啟動套件所需的一切；可通過其提供的殼層腳本打開在背景啟動的遠端控制台來輕鬆管理，像是啟動/停止/重新啟動套件或是發送遠端指令等。此外，它們是可封存的加工品，這表示可以在將來的任何時候從其壓縮檔中還原舊發布版本（除非與基礎 OS 或系統函式庫不相容）使用發布版本也是執行熱升級和熱降級的前置作業，而熱升級和熱降級是 Erlang VM 最強大的功能之一。 ー [Distillery 文件](https://hexdocs.pm/distillery/introduction/understanding_releases.html)

一個發布版本將包含以下內容：
* /bin 資料夾
  * 含有一個腳本，該腳本是執行整個應用程式的起點。
* /lib 資料夾
  * 含有應用程式已編譯的位元組碼以及所有相依性。
* /releases 資料夾
  * 含有有關該發布版本的後設資料以及鉤子和自定指令。
* /erts-VERSION
  * 含有 Erlang 執行期環境，機器無需安裝 Erlang 或 Elixir 即可執行應用程式。


### 入門/安裝

要將 Distillery 加入到專案中，請將其作為相依性加入到 `mix.exs` 中。*註* ㄧ 如果是在保護傘程式上作業，則應該新增到專案根目錄裡的 mix.exs

```elixir
defp deps do
  [{:distillery, "~> 2.0"}]
end
```

接著在終端機中呼用：

```
mix deps.get
```

```
mix compile
```


### 建立你的發布版本

在終端機中，執行

```
mix release.init
```

這個指令會產生一個帶有一些配置檔案的 `rel` 目錄。

要在終端機中產生一個發布版本請執行 `mix release`

一旦建立發布版本後，應該會在終端機中看到一些說明

```
==> Assembling release..
==> Building release book_app:0.1.0 using environment dev
==> You have set dev_mode to true, skipping archival phase
Release successfully built!
To start the release you have built, you can use one of the following tasks:

    # start a shell, like 'iex -S mix'
    > _build/dev/rel/book_app/bin/book_app console

    # start in the foreground, like 'mix run --no-halt'
    > _build/dev/rel/book_app/bin/book_app foreground

    # start in the background, must be stopped with the 'stop' command
    > _build/dev/rel/book_app/bin/book_app start

If you started a release elsewhere, and wish to connect to it:

    # connects a local shell to the running node
    > _build/dev/rel/book_app/bin/book_app remote_console

    # connects directly to the running node's console
    > _build/dev/rel/book_app/bin/book_app attach

For a complete listing of commands and their use:

    > _build/dev/rel/book_app/bin/book_app help
```

要執行應用程式，請在終端機中輸入以下內容 `_build/dev/rel/MYAPP/bin/MYAPP foreground` 
在你的情況用你的專案名稱替換 MYAPP。現在是正在執行應用程式的發布版本！


## 在 Phoenix 中使用 Distillery 

如果你是 Distillery 與 Phoenix 配合著使用，會需要執行一些額外的步驟，然後才能起作用。

首先需要編輯 `config/prod.exs` 檔案。

修改以下行數，從：

```elixir
config :book_app, BookAppWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
```
改為：

```elixir
config :book_app, BookApp.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:book_app, :vsn)
```

此時己經完成的事項是：
- `server` - 在應用程式啟動時啟動 Cowboy 應用程式的 http 端點服務。
- `root` - 設定應用程式根目錄，該目錄是靜態文件存取位置。
- `version` - 熱升級應用程式版本時，將清除應用程式快取。
- `port` - 藉由設定 ENV 變數可以在啟動應用程式時傳入連接埠號碼來改變連接埠設定。當啟動應用程式時，可以通過執行 `PORT=4001 _build/prod/rel/book_app/bin/book_app foreground` 來提供連接埠。

如果執行上述指令，可能會發現應用程試當機了，因為當前不存在資料庫而無法與其連接。這可以通過執行 Ecto `mix` 指令來修正。在終端機中，輸入以下內容：

```
MIX_ENV=prod mix ecto.create
```

這個指令會建立資料庫。現在嘗試重新執行應用程式，它會成功啟動。但是，你同時會注意到，資料庫遷移尚未執行。通常在開發時，會通過呼用 `mix.ecto migrate` 來手動執行這些遷移。但對於發布版本，必須對其進行配置，以便它可以獨立執行遷移。


## 在正式環境執行遷移

Distillery 能夠在發布版本生命週期的不同時間點之間執行程式碼。這些點稱為 [boot-hooks](https://hexdocs.pm/distillery/1.5.2/boot-hooks.html)。 Distillery 提供的鉤子包括

* pre_start
* post_start
* pre/post_configure
* pre/post_stop
* pre/post_upgrade


因著目的，將使用 `post_start` 鉤子在正式環境中執行應用程式遷移。首先，建立一個名為 `migrate` 的新發布版本工作。發布版本工作是一個模組函數，可以從終端機上呼用它，其中包含與應用程式內部運作分離的程式碼。對於特別是應用程式本身不需要執行的工作而言，這很有用。

```elixir
defmodule BookAppWeb.ReleaseTasks do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:book_app)

    path = Application.app_dir(:book_app, "priv/repo/migrations")

    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)
  end
end
```

*註* ー 好的做法是在執行這些遷移之前，確保所有應用程式都已正確啟動。 [Ecto.Migrator](https://hexdocs.pm/ecto/2.2.8/Ecto.Migrator.html) 允許對已連接的資料庫執行遷移。

接下來，建立一個新檔案 - `rel/hooks/post_start/migrate.sh` 並加入以下程式碼：


```
echo "Running migrations"

bin/book_app rpc "Elixir.BookApp.ReleaseTasks.migrate"

```

為了使這些程式碼正常執行，使用了 Erlang 的 `rpc` 模組，該模組允許使用遠端程式呼叫 （Remote Produce Call ）服務。基本上，這可以在遠端節點上呼用函數並獲得應答。當在正式環境中執行時，應用程式可能會執行在多個不同的節點上。

最後，在 `rel/config.exs` 檔案中，將鉤子加入到正式環境的配置上。

現在將以下

```elixir
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
end
```

取代為

```elixir
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
  set post_start_hooks: "rel/hooks/post_start"
end
```

*註* - 此鉤子僅存在於此應用程式的正式發布版本中。如果使用預設的開發環境發布版本，它將無法執行。

## 自訂指令

在使用發布版本時，有可能無法使用 `mix` 指令，因為 `mix` 可能未安裝到部署該發布版本的機器上。不過可以通過建立自訂指令來解決此問題。

> 自訂指令是啟動腳本的擴充，並且與在前景或 remote_console 的相同方式來使用，換句話說，它們看起來像是啟動腳本的一部分。像鉤子一樣，它們可以存取啟動腳本的輔助函數和環境 - [Distillery 文件](https://hexdocs.pm/distillery/1.5.2/custom-commands.html)

其指令與發布版本的工作相似，因為它們都是做為方法的函數，但與指令不同處為，它們是通過終端機，而不是發布版本的腳本來執行。

現在能夠執行遷移了，或許也希望可以通過執行指令為資料庫播種初始資訊。因此，首先為發布版本的工作加入一個新方法。在 `BookAppWeb.ReleaseTasks` 中，加入以下內容

```elixir
def seed do
  seed_path = Application.app_dir(:book_app_web, "priv/repo/seeds.exs")
  Code.eval_file(seed_path)
end
```

接著，建立一個新檔案 `rel/commands/seed.sh` 並加入以下程式碼：

```
#!/bin/sh

release_ctl eval "BookAppWeb.ReleaseTasks.seed/0"
```


*註* - `release_ctl()` 是 Distillery 提供的殼層腳本，它允許在本機或乾淨的節點中執行指令。如果需要在正在執行的節點上使用此指令，則可以執行 `release_remote_ctl()`

在 [這裡](https://hexdocs.pm/distillery/extensibility/shell_scripts.html)查看更多有關 Distillery 的 shell_scripts 資訊。

最後，將以下內容加入到 `rel/config.exs` 檔案中。
```elixir
release :book_app do
  ...
  set commands: [
    seed: "rel/commands/seed.sh"
  ]
end

```

要確定是通過執行 `MIX_ENV=prod mix release` 來重新建立發布版本。一旦完成此動作後，就可以在終端機中執行 `PORT=4001 _build/prod/rel/book_app/bin/book_app seed`。
