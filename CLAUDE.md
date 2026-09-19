# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A content-only repository for [ElixirSchool.com](https://elixirschool.com). It contains lessons, blog posts, and translations. There is no Elixir application here — the website itself lives in the separate [school_house](https://github.com/elixirschool/school_house) repo.

## Useful Commands

Check translation status across languages:

```shell
elixir bin/version_report.exs
elixir bin/version_report.exs --lang ru,ja
elixir bin/version_report.exs --severity major,missing
```

## Content Structure

- `lessons/<lang>/<category>/<lesson>.md` — lesson files by language code (e.g., `en`, `ru`, `ja`)
- `posts/YYYY-MM-DD-name-separated-with-hyphens.md` — blog posts
- English lessons under `lessons/en/` are the source of truth; all other languages are translations

### Lesson categories (under each language)

`basics`, `intermediate`, `advanced`, `ecto`, `misc`, `storage`, `testing`, `data_processing`, `phoenix`

## Front Matter Format

All lessons require front matter in this format:

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

Translations set `version` to match the English source version. The version is used programmatically to detect stale translations.

**Version bump rules:**
- MAJOR — rewrote most of the lesson (translators will need to update)
- MINOR — added or removed sentences/paragraphs
- PATCH — spelling/typo fixes only

Blog post front matter includes `author`, `author_link`, `tags`, `date` (`~D[YYYY-MM-DD]`), `title`, and `excerpt`.

## Writing Style

See `AGENTS.md` for the full style guide. Key points:

- Use inclusive "we" — the reader is a collaborator, not a student
- Show code first, then explain — examples precede explanation
- Short paragraphs; dense info gets bullet points or code blocks
- Active voice, contractions always ("we'll", "don't", never "we will")
- No emoji, no platitudes, no filler sentences
- Oxford comma
- Headers: H2 for major sections, H3 for subsections; never H1 in body content
- Code blocks always include a language identifier

Content structure for lessons: brief overview → motivation (2-3 sentences max) → core content with code → connections to related topics.

## Translation Style Guides

Language-specific translation conventions are documented alongside the lessons:

- Russian (`ru`): [`.claude/locales/ru.md`](.claude/locales/ru.md)

## Adding New Content

**New lesson:** create `lessons/en/<category>/<lesson>.md` with front matter. A corresponding change in `school_house` may be needed to register it on the website.

**New translation:** copy the English file to `lessons/<lang>/`, translate it, keep `version` matching the English source.

**New language:** create `lessons/<iso-code>/{basics,advanced,intermediate,ecto,misc,storage,testing,data_processing,phoenix}/` and update `school_house` to register the language.
