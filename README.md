# Elixir School

> Elixir School is the premier destination for people looking to learn and master the Elixir programming language.

Lessons can now be viewed at [ElixirSchool.com](https://elixirschool.com).

_Feedback and participation is strongly encouraged! Please see [Contributing](CONTRIBUTING.md) for more details on how to get involved._

### Running

[ElixirSchool.com](https://elixirschool.com) is generated using [Jekyll](https://github.com/jekyll/jekyll).
To run locally you need both Ruby and Bundler installed.

1. Install dependencies:

	```shell
	$ bundle install
	```

1. Run Jekyll:

	```shell
	$ bundle exec jekyll s
	```

1. Read it at [http://localhost:4000](http://localhost:4000)

### Translating

In addition to the steps above there are a few addition steps required for translation.

#### New Language

1. Create a folder using the ISO language code (e.g. ja, zh-hans, es, et al) with lesson subfolders.
Not sure which language code to use?
Check [here](https://www.loc.gov/standards/iso639-2/php/English_list.php) for the official list.

  ```shell
  $ cd elixirschool
  $ mkdir -p ja/lessons/{basics,advanced,specifics,libraries}
  $ touch ja/lessons/{basics,advanced,specifics,libraries}/.gitkeep
  ```

1. Add your language code to `_data/interlang.yml` and translate the language names:

  ```yaml
  ja:
   ar: アラビア語
   bg: ブルガリア語
   bn: ベンガル語
   cn: 中国語
   de: ドイツ語
   en: 英語
   es: スペイン語
   fr: フランス語
   gr: ギリシャ語
   id: インドネシア語
   it: イタリア語
   ja: 日本語
   ko: 韓国語
   ms: マレーシア語
   "no": ノルウェー語
   pl: ポーランド語
   pt: ポルトガル語
   ru: ロシア語
   sk: スロバキア語
   ta: ターミル語
   tr: トルコ語
   uk: ウクライナ語
   vi: ベトナム語
   th: タイ語
  ```

1. Create a locale file for your new language using `_data/locales/en.yml` as a guide:

  ```shell
  $ touch _data/locales/ja.yml
  ```

1. If the new language is RTL (right-to-left) it should be added to the `rtl_languages` list in `config.yml`:

  ```yaml
  script_direction: rtl
  ```

#### Translated Lesson

1. Translated lessons must include the page metadata.
   * `title` should be a translation of the original lesson's `title`.
   * `version` should consist of three digits: `major.minor.patch`, so:
     * if this is a initial lesson translation, the version should be set to `1.0.0`;
     * if you apply the original lesson updates to the translation, the version should be copied from the corresponding state of the original lesson;
     * else bump one of the version numbers depending on how important is your change.

   For example `/ja/lessons/basics/basics.md`:

  ```yaml
  ---
  title: 基本
  version: 1.0.0
  ---
  ```

## New Lessons

Contributing a new lesson?
Wonderful!
In addition to creating the new lesson be sure to add it to `_data/contents.yml`.
