# Elixir School [![License](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

> Lessons about the Elixir programming language, inspired by Twitter's [Scala School](http://twitter.github.io/scala_school/).

Lessons can now be viewed on [ElixirSchool.com](https://elixirschool.com).

_Feedback and participation is welcome. Please see [Contributing](CONTRIBUTING.md) for more details on how to get involved._

### Running

[ElixirSchool.com](https://elixirschool.com) is generated using [Jekyll](https://github.com/jekyll/jekyll).  To run locally you need both Ruby and Bundler installed.

1. Install dependencies:

	```shell
	$ bundle install
	```

1. Update `url` in `_config.yml` to match your machine:

  ```md
  title: Elixir School
  description: Lessons about the Elixir programming language
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
  $ touch jp/lessons/{basics,advanced,specifics}/.gitignore
  ```

1. Update `_config.yml` by including the 2 character code in `languages` and adding translations to `sections`, `description` and `toc`:

  ```yaml
  languages: ['en', 'jp']
  default_lang: en
  exclude_from_localization: []
  sections:
    - tag: basics
      label:
        en: Basics
        jp: 基本

  description:
    en: Lessons about the Elixir programming language
    jp: プログラミング言語Elixirのレッスン

  toc:
    en: Table of Contents
    jp: 目次
  ```

1. If the new language is RTL (right-to-left) it should also be added to the `rtl_languages` list:

  ```yaml
  rtl_languages: ['ar']
  ```

1. Add it to list in `index.md`:

  ```markdown
  Available in [Việt ngữ][vi], [汉语][cn], [Español][es], [Slovenčina][sk], [日本語][jp], [Polski][pl] [Português][pt], [Русском][ru] and [Bahasa Melayu][my] and other.
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
