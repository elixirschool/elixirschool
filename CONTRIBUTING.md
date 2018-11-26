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

Thank you for your contributions!
