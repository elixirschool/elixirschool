# Elixir School

> Elixir School is the premier destination for people seeking to learn and master the Elixir programming language.

You can access lessons at [ElixirSchool.com](https://elixirschool.com).

_Feedback and participation are strongly encouraged! Please see [Contributing](CONTRIBUTING.md) for more details on how to get involved._

### Running Locally

This repository only contains the lessons and blog posts hosted on Elixir School. To run the Elixir School website locally, find the code and setup instructions in the [school_house](https://github.com/elixirschool/school_house) repository.

### Translating a Lesson

1. Each of the languages has a folder in `lessons/` directory of this repo. To start translating you need to copy a file from the English language to the corresponding folder in your language and start translating it.

2. Check the [translation report](https://elixirschool.com/pt/report/) for pages that haven't been translated yet, or for pages which need to have their translations updated in the corresponding language you want to work with.

3. Translated lessons must include page metadata.
   * `title` should be a translation of the original lesson's `title`.
   * `version` should be set to the original English `version`.

   For example `lessons/ja/basics/basics.md`:

  ```yaml
  ---
  title: 基本
  version: 1.0.0
  ---
  ```

4. Submit a PR with the new translated lesson :tada:

### Posting an Article

Elixir School is powered by Phoenix and [NimblePublisher](https://github.com/dashbitco/nimble_publisher), a publishing engine that supports Markdown formatting. If you're familiar with Phoenix & NimblePublisher then you're ready to go, if you aren't don't fret we're here to help!

1. We need to create the file for our article. Blog posts live in the `posts/` directory. Our filename will need to confirm to the `YYYY-MM-DD-name-separated-with-hyphens.md` pattern.

2. After opening the new file in our favorite editor we need to add some metadata to the top of it:

```elixir
%{
  author: "Author Name",
  author_link: "https://github.com/author_github_account",
  tags: ["phoenix"],
  date: ~D[YYYY-MM-DD],
  title: "Full Article Title",
  excerpt: """
  Article short preview text
  """
}
---
```

3. Once we've completed writing our post submit a pull request to have it reviewed before it is published.
