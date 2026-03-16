# Contribution Guidelines

## General

Please ensure your pull request adheres to the following guidelines:

* New lessons or improvements to existing lessons are welcome.
* Please check your spelling and grammar.
* Please adhere to our [style guide](https://github.com/elixirschool/elixirschool/wiki/Lesson-Styleguide)

## A Note on Lesson Versions

All lessons should include the following front matter:

```elixir
%{
  version: "2.0.0",
  title: "Ecto"
}
---
```

Change the `version` attribute according to the following rules:

* MAJOR — You (re)wrote the whole thing. Your new content will need some translation.
* MINOR — Added or removed some content, few sentences, etc.
* PATCH — Spelling, typos. Probably not translated stuff.

Fun fact! The version changes are necessary because we use that to programmatically determine and inform translators of new content that requires translation.

Each language has a generated [Translation Report](https://elixirschool.com/es/report/)

## Adding a New Lesson

Lesson content is managed in this repository while the website is powered by the [school_house](https://github.com/elixirschool/school_house) repository.

To add a new lesson, create the file under the appropriate directory in `lessons/en/` (or `lessons/<language_code>/` if you are not writing your new lesson in English).

Your new lesson file should include the required front matter:

```elixir
%{
  version: "1.0.0",
  title: "Lesson Title",
  excerpt: """
  A short description of the lesson.
  """
}
---
```

Once the lesson content has been added here, a corresponding change may be needed in the [school_house](https://github.com/elixirschool/school_house) repository to register the new lesson for display on the website.

Thank you for your contributions!

## Adding a New Translation

1. Each of the languages has a folder in `lessons/` directory of this repo. To start translating you need to copy a file from the English language to the corresponding folder in your language and start translating it.

2. Check the [translation report](https://elixirschool.com/pt/report/) for pages that haven't been translated yet, or for pages which need to have their translations updated in the corresponding language you want to work with.

3. Translated lessons must include page metadata.
   * `title` should be a translation of the original lesson's `title`.
   * `version` should be set to the original English `version`.

   For example `lessons/ja/basics/basics.md`:

   ```elixir
   %{
     version: "1.0.0",
     title: "基本"
   }
   ---
   ```

4. Submit a PR with the new translated lesson :tada:

## Adding a New Language

1. Create a folder using the ISO language code (e.g. ja, zh-hans, es, et al) with lesson subfolders.
Not sure which language code to use?
Check [here](https://www.loc.gov/standards/iso639-2/php/English_list.php) for the official list.

  ```shell
  cd elixirschool
  mkdir -p lessons/ja/{basics,advanced,intermediate,ecto,misc,storage,testing,data_processing,phoenix}
  ```

2. A corresponding update will be needed in the [school_house](https://github.com/elixirschool/school_house) repository to register the new language for the website.

3. Submit a PR with the new language folder and translated lessons :tada:

## Posting an Article

Elixir School is powered by Phoenix and [NimblePublisher](https://github.com/dashbitco/nimble_publisher), a publishing engine that supports Markdown formatting. If you're familiar with Phoenix & NimblePublisher then you're ready to go, if you aren't don't fret we're here to help!

1. We need to create the file for our article. Blog posts live in the `posts/` directory. Our filename will need to conform to the `YYYY-MM-DD-name-separated-with-hyphens.md` pattern.

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
