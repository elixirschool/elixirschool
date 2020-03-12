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

1. Each of the languages has a folder in root of this repo. To start translating you need to copy a file from the English language to the corresponding folder in your language and start translating.

2. Check the [translation report](https://elixirschool.com/pt/report/) for pages that haven't been translated yet, or for pages which need to have their translations updated in the corresponding language you want to work with.

3. Translated lessons must include page metadata.
   * `title` should be a translation of the original lesson's `title`.
   * `version` should be set to the original English `version`.

   For example `/ja/lessons/basics/basics.md`:

  ```yaml
  ---
  title: 基本
  version: 1.0.0
  ---
  ```

4. Send a PR with the new translated lesson and join [https://elixirschool.com/contributors/](_data/contributors.yml).

### Posting an article

1. Create your article file in the `_posts/` directory, in the form of `YYYY-MM-DD-name-seperated-with-hiphens.md`.

2. Write your article headings like so on the file you just created:
```
---
author: Author Name
author_link: https://github.com/author_github_account (or website)
categories: article_category (find them or add a new one in _data/blog_meta.yml)
tags: ['phoenix'] (find them or create a new one in _data/blog_meta.yml)
date: YYYY-MM-DD for the post date
layout: post
title: Full Article Title
excerpt: >
 Article short preview text
---
```

Then continue with your article body

3. Add your details in the `_data/contributors.yml` file if they are not already there.
