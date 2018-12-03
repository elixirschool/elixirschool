# Contribution Guidelines

## General
Please ensure your pull request adheres to the following guidelines:

* New lessons or improvements to existing lessons are welcome.
* Please check your spelling and grammar.
* Open an issue to handle translations if adding a new lesson or modifying an existing one. An example can be found [here](https://github.com/elixirschool/elixirschool/issues/529)
* Please adhere to our [style guide](https://github.com/elixirschool/elixirschool/wiki/Lesson-Styleguide)

## A Note on Lesson Versions

All lessons should include the follow front matter:

```markdown
---
version: 2.0.0
title: Ecto
---
```

Change the `version` attribute according to the following rules:

* MAJOR — You (re)wrote the whole thing. Your new content will need some translation.
* MINOR — Added or removed some content, few sentences, etc.
* PATCH — Spelling, typos. Probably not translated stuff.

Fun fact! The version changes are important because we use that to programmatically determine and inform translators of new content that requires translation.

## Adding a New Lesson
To add a new lesson, create the file under the appropriate directory in `en/lessons` (or `<language_code>/lessons`) if you are not writing your new lesson in English).

Then, update `_data/content.yml` with the name of your new lesson under the appropriate section.

If you've added a new section (i.e. a new directory under `/lessons`), add the section name under the `sections` key of `_data/locales/en.yml` or `_data/locales/<language_code>.yml` if the section + lesson you added are not in English.

Thank you for your contributions!

## Gotcha

Look out for Liquid templating weirdness!

If you have a code snippet that includes the following syntax: `{%{message: "error message"}, :error}`, i.e. if you have a tuple where the first element is a map, WATCH OUT! That set of characters, `{%` is actually the start of a liquid tag! Instead, wrap your backticked code block in `{% raw % }` `{% endraw %}`

## Before You Push
Check that Jekyll can build:

*You need to have Ruby installed on your machine to do this*

```shell
$ bundle install
$ bundle exec jekyll s
```
