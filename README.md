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

1. Add your language code to `interlang` in `_data/locales/en.yml`:

  ```yaml
  interlang:
   ja: Japanese
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
   * `version` should be set to the original English `version`

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
