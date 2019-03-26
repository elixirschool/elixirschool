# Elixir School

> Elixir School is the premier destination for people looking to learn and master the Elixir programming language.

You can access lessons at [ElixirSchool.com](https://elixirschool.com).

_Feedback and participation are strongly encouraged! Please see [Contributing](CONTRIBUTING.md) for more details on how to get involved._

### Running locally

[ElixirSchool.com](https://elixirschool.com) is generated using [Jekyll](https://github.com/jekyll/jekyll).
To run locally, you need both Ruby and Bundler installed.

1. Install dependencies:

  ```shell
  $ bundle install
  ```

2. Run Jekyll:

  ```shell
  $ bundle exec jekyll s
  ```

3. Access it at [http://localhost:4000](http://localhost:4000)

### Translating a Lesson

1. Each of the languages has a folder in root this repo. To start translating you need to copy a file from the English language to the corresponding folder in your language and start translating.

2. Translated lessons must include page metadata.
   * `title` should be a translation of the original lesson's `title`.
   * `version` should be set to the original English `version`.

   For example `/ja/lessons/basics/basics.md`:

  ```yaml
  ---
  title: 基本
  version: 1.0.0
  ---
  ```
  
3. Send a PR with the new translated lesson and join [https://elixirschool.com/contributors/](contributors).


