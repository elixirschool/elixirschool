# Elixir School [![License](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

> Lessons in the Fundamentals of Elixir, inspired by Twitter's [Scala School](http://twitter.github.io/scala_school/).

Lessons can now be views on [ElixirSchool.com](https://elixirschool.com).

_Feedback and participation is welcome. Please see [Contributing](CONTRIBUTIING.md) for more details on how to get involved._

### Running

[ElixirSchool.com](https://elixirschool.com) is generated using [Jekyll](https://github.com/jekyll/jekyll).  To run locally you need both Ruby and Bundler installed.

1. Install dependencies:

	```shell
	$ bundle install
	```

1. Update `url` in `_config.yml` to match your machine:

  ```md
  title: Elixir School
  description: Lessons in the Fundamentals of Elixir
  baseurl: /
  url: http://localhost:4000
  ```

1. Run Jekyll:

	```shell
	$ bundle exec jekyll s
	```

1. Read it at [http://localhost:4000](http://localhost:4000)

### Translating

In addition to the steps above there are a few addition steps required for translation.

#### New Language

1. Create a folder using the 2 character code (e.g. jp, en, es, etc) with lesson subfolders:

  ```shell
  $ cd elixir_school
  $ mkdir -p jp/lessons/{basics,advanced,specifics}
  ```

1. Update `_config.yml` by including the 2 character code in `languages` and adding translations to `sections`:

  ```md
  languages: ['en', 'jp']
  default_lang: en
  exclude_from_localization: []
  sections:
    - tag: basics
      label:
        en: Basics
        jp: 基本
  ```

#### Translated Lesson

1. Translated lessons must include `lang: XX` in the page meta data.  For example `/jp/lessons/basics/basics.md`:

  ```md
  ---
  layout: page
  title: 基本
  category: basics
  order: 1
  lang: jp
  ---
  ```
