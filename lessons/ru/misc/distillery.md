%{
  version: "2.0.4",
  title: "Distillery (Basics)",
  excerpt: """
  Distillery - это менеджер релизов, написанный на чистом Elixir.
  Он позволяет создавать релизы, которые можно развернуть в другом месте, практически без настройки.
  """
}
---

## Что такое релиз?

Релиз - это пакет, содержащий ваш скомпилированный Erlang/Elixir код (например, [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)) [байт-код] (<https://ru.wikipedia.org/wiki/%D0%91%D0%B0%D0%B9%D1%82-%D0%BA%D0%BE%D0%B4>)).
Он также предоставляет любые скрипты, необходимые для запуска вашего приложения.

После создания одного или нескольких приложений у вас может возникнуть желание создать полноценный набор программного обеспечения, включающий эти приложения и набор других приложений Erlang/OTP. Это и называется релизом. - [Erlang documentation](http://erlang.org/doc/design_principles/release_structure.html)

Релизы дают возможность упрощённой доставки ПО: они не требуют никаких сторонних зависимостей и предоставляют всё необходимое для своего запуска. Ими легко управлять при помощи поставляемых вместе с ними shell-скриптов: запуск удалённого терминала, пуск/останов/перезапуск релиза, запуск в фоновом режиме, отправление дистанционных команд и многое другое. Релизы — это архивируемые артефакты сборки, что означает, что вы, имея его исходный архив (tarball), можете восстановить старый релиз в любое время, если возникнут проблемы совместимости с ОС или системными библиотеками. Использование релизов открывает вам доступ к одной из самых мощных особенностей Erlang VM: установка/откат обновления (апгрейд/даунгрейд) на горячую. - [Distillery Documentation](https://hexdocs.pm/distillery/introduction/understanding_releases.html)

Релиз будет содержать следующее:

* папка /bin
  * Содержит сценарий, который является отправной точкой для запуска всего вашего приложения.
* папка /lib
  * Содержит скомпилированный байт-код приложения вместе с любыми зависимостями.
* папка /Release
  * Содержит метаданные о выпуске, а также хуки и пользовательские команды.
* a /erts-VERSION
  * Содержит среду выполнения Erlang, которая позволит машине запускать ваше приложение без установленного Erlang или Elixir.

### Начало работы/установка

Для того чтобы добавить менеджер релизов Distillery в ваш проект, укажите его в качестве зависимости в файле `mix.exs`.
*Примечание* - если вы работаете с зонтичным проектом, то это должен быть файл mix.exs в корневом каталоге вашего проекта.

```elixir
defp deps do
  [{:distillery, "~> 2.0"}]
end
```

Затем в терминале выполните:

```shell
mix deps.get
mix compile
```

### Создание релиза

В терминале выполните

```shell
mix release.init
```

Эта команда создаст директорию `rel` с файлами конфигурации в ней.

Чтобы сгенерировать релиз в вашем терминале, запустите `mix release`.

После того как релиз будет собран, вы должны увидеть некоторые инструкции в своём терминале.

```
==> Assembling release..
==> Building release book_app:0.1.0 using environment dev
==> You have set dev_mode to true, skipping archival phase
Релиз успешно собран!
Чтобы запустить собранный релиз, используйте одну из следующих команд:

    # start a shell, like 'iex -S mix'
    > _build/dev/rel/book_app/bin/book_app console

    # start in the foreground, like 'mix run --no-halt'
    > _build/dev/rel/book_app/bin/book_app foreground

    # start in the background, must be stopped with the 'stop' command
    > _build/dev/rel/book_app/bin/book_app start

Если это дистанционный релиз, и вы хотите к нему подключиться:

    # connects a local shell to the running node
    > _build/dev/rel/book_app/bin/book_app remote_console

    # connects directly to the running node's console
    > _build/dev/rel/book_app/bin/book_app attach

Для получения полного перечня команд:

    > _build/dev/rel/book_app/bin/book_app help
```

Для запуска приложения введите это в терминале: `_build/dev/rel/MYAPP/bin/MYAPP foreground`
Замените MYAPP на имя вашего проекта.
Теперь мы работаем с релизной сборкой нашего приложения.

## Использование Distillery вместе с Phoenix

Если вы собираетесь использовать менеджер релизов Distillery вместе с фреймворком Phoenix, то для этого нужно выполнить несколько следующих шагов.

Сперва нам нужно отредактировать файл `config/prod.exs`.

Измените следующие строки с этого:

```elixir
config :book_app, BookAppWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
```

на это:

```elixir
config :book_app, BookAppWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:book_app, :vsn)
```

Здесь мы выполнили несколько вещей:

* `server` - при старте приложения мы запускаем приложение Cowboy, которое обрабатывает http endpoint;
* `root` - задаёт корневой каталог приложения, в котором хранятся все статические файлы;
* `version` - принудительно обновляет кеш приложения при горячем обновлении версии приложения;
* `port` - установка порта через переменную окружения позволяет нам передавать номер порта при запуске приложения;
Например, мы можем задать порт, запуская `PORT=4001 _build/prod/rel/book_app/bin/book_app foreground`

Если вы выполнили приведенную выше команду, то вы могли заметить, что приложение прекратило работу, потому что оно неспособно соединиться с базой данных, так как никакой базы данных ещё не существует.
Это может быть исправлено запуском команды `mix`.
В терминале введите следующее:

```shell
MIX_ENV=prod mix ecto.create
```

Эта команда создаст для вас базу данных.
После перезапуска приложения должно успешно запуститься.
Однако, вы можете заметить, что миграции для базы данных не были запущены.
Обычно в разработке мы запускаем все миграции вручную вызовом `mix ecto.migrate`.
В случае релиза нам придется настроить его так, чтобы он запускал все миграции самостоятельно.

## Запуск миграций в Production

Менеджер релизов Distillery предоставляет нам возможность исполнения заданного кода в разные моменты выполнения релиза.
Эти разные моменты известны как [хуки запуска](https://hexdocs.pm/distillery/1.5.2/boot-hooks.html).
Хуки запуска, предоставляемые Distillery, включают в себя:

* pre_start
* post_start
* pre/post_configure
* pre/post_stop
* pre/post_upgrade

Мы будем использовать хук `post_start` для запуска наших миграций в production.
Сначала создадим задачу релиза, названную `migrate`.
Задача релиза это модульная функция, которую мы вызовем из терминала, и эта функция содержит код, который отделён от внутренней работы нашего приложения.
Такой код полезен для задач, которые само приложение вряд ли будет запускать.

```elixir
defmodule BookAppWeb.ReleaseTasks do
  def migrate do
    {:ok, _} = Application.ensure_all_started(:book_app)

    path = Application.app_dir(:book_app, "priv/repo/migrations")

    Ecto.Migrator.run(BookApp.Repo, path, :up, all: true)
  end
end
```

*Примечание* Неплохо будет убедиться, что ваши приложения запущены и корректно работают, перед тем, как запускать эти миграции.
[Ecto.Migrator](https://hexdocs.pm/ecto/2.2.8/Ecto.Migrator.html) позволяет нам запустить наши миграции с подключенной базой данных.

Далее, создадим новый файл - `rel/hooks/post_start/migrate.sh` - и добавим следующий код:

```bash
echo "Running migrations"

bin/book_app rpc "Elixir.BookApp.ReleaseTasks.migrate"

```

Для того чтобы этот код корректно отработал, мы используем модуль `rpc` языка Erlang, и этот модуль позволяет нам использовать удалённый вызов процедур (Remote Procedure Call).
Это позволяет нам вызвать функцию на дистанционном узле и получить ответ.
При работе в режиме production наше приложение, скорее всего, будет выполняться на нескольких разных узлах.

И, наконец, в файле `rel/config.exs` мы добавим хук для настройки нашего prod.

Заменим

```elixir
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
end
```

на

```elixir
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"TkJuF,3nc4)OWPBpPxPDb6mz$>)>a>/v/,l2}W*sUFaz<)bG,v*3pPESE,`XOk{,"
  set vm_args: "rel/vm.args"
  set post_start_hooks: "rel/hooks/post_start"
end
```

*Примечание* - этот хук доступен только для production релиза нашего приложения.
При использовании релиза по умолчанию этот хук не запустится.

## Пользовательские команды

Иногда, работая с релизом, у вас может не быть доступа к `mix` командам, потому что модуль `mix` не установлен на той машине, куда был доставлен релиз.
Эта проблема может быть решена введением пользовательских команд.

> Пользовательские команды это расширения загрузочного скрипта, и они используются так же, как вы бы использовали команды foreground или remote_console. То есть они выглядят как часть загрузочного скрипта. Подобно хукам, у них есть доступ к среде окружения и к вспомогательным функциям загрузочных скриптов - [Distillery Docs](https://hexdocs.pm/distillery/1.5.2/custom-commands.html).

Пользовательские команды похожи на задачи релиза в том смысле, что и те, и другие это функции, но они отличаются от задач релиза тем, что выполняются через терминал, в то время, как задачи релиза запускаются скриптом релиза.

Теперь мы можем запустить наши миграции, и нам может потребоваться наполнить нашу базу данных информацией, переданной запуском команды.
Для начала добавим новый метод в наши задачи релиза.
В раздел `BookAppWeb.ReleaseTasks` добавим следующее:

```elixir
def seed do
  seed_path = Application.app_dir(:book_app_web, "priv/repo/seeds.exs")
  Code.eval_file(seed_path)
end
```

Затем создайте новый файл `rel/commands/seed.sh` и добавьте следующий код:

```bash
#!/bin/sh

release_ctl eval "BookAppWeb.ReleaseTasks.seed/0"
```

*Примечание* - `release_ctl()` это cценарий командной строки (shell-скрипт), предоставляемый менеджером релизов Distillery, он позволяет нам выполнять команды локально или в чистом узле.
Если нам нужно выполнить команду в уже работающем узле, то можно запустить `release_remote_ctl()`

Больше о shell-скриптах, предоставляемых Distillery, можно узнать [здесь](https://hexdocs.pm/distillery/extensibility/shell_scripts.html)

Наконец, добавим следующий код в файл `rel/config.exs`:

```elixir
release :book_app do
  ...
  set commands: [
    seed: "rel/commands/seed.sh"
  ]
end

```

Не забудьте пересоздать релиз, запустив `MIX_ENV=prod mix release`.
После выполнения команды вы можете запустить в терминале `PORT=4001 _build/prod/rel/book_app/bin/book_app seed`.
