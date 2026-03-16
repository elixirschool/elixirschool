# AGENTS.md - Elixir School Writing Style Guide

## Voice Overview

Elixir School's voice reads like a senior engineer talking to peers at a whiteboard: technically precise but never stuffy. We respect the reader's intelligence without assuming they know everything. We are direct and opinionated — we tell you what works and what does not, and why. The writing is warm, collaborative, and efficient. We get to the point quickly, let code do the heavy lifting, and trust the reader to keep up.

---

## Writing Style

### Core Characteristics

- **Inclusive "we" and "let's"** — The reader is a collaborator, not a student. "Let's look at a basic example", "Before we can jump into the deeper waters", "We'll cover what Release Please is and how it works".
- **Concise scene-setting** — Each section opens with a short orienting sentence before diving in. Never more than 2-3 sentences of preamble.
- **Show, then explain** — Code examples come first or very quickly after a concept is introduced. Explanation follows the example, not the other way around.
- **Cross-references as breadcrumbs** — "We briefly covered guards in the Control Structures lesson", "As we saw in the Enum lesson". Links topics into a coherent curriculum or body of work.
- **Practical framing** — Topics are motivated by real problems: "Manually updating version numbers in mix.exs, crafting changelogs... can quickly become overwhelming." Never abstract motivation.
- **Minimal jargon without dumbing down** — Technical terms used correctly and introduced naturally. No glossary-style definitions unless truly needed. If something has a prerequisite, say so and link to it.
- **Short paragraphs** — Rarely more than 3-4 sentences. Dense information gets bullet points or code blocks, not walls of text.
- **Rhetorical questions as transitions** — "What if we could automate all of that while also improving your development workflow?" Used sparingly, always followed by the answer.
- **Confident but not preachy** — States best practices directly: "Each commit should represent one logical change." No hedging with "you might want to consider possibly..."
- **Light personality leaks through** — "Automagically generate a changelog", "Gone are the days of wondering and debating". Not dry, but humor is restrained and natural.
- **Genuine enthusiasm** — When we are excited about a tool or approach, it comes through: "We're excited about all the new possibilities and content in store and we hope you are too!"

### Sentence Structure Patterns
- Compound sentences joined by "and" or "but" rather than semicolons
- Dashes for asides — like this — rather than parentheses
- Active voice almost exclusively
- Imperative mood for instructions: "Create .github/workflows/release-please.yml"
- Present tense for describing behavior: "Release Please maintains Release PRs that are kept up-to-date"
- Contractions always ("we'll", "you're", "it's", "don't") — never "we will" or "do not" unless for deliberate emphasis

### What We Do NOT Do
- Use profanity in published writing
- Write extended personal anecdotes or memoir-style digressions
- Use emoji
- Use slang or overly casual language
- Use phrases like "In today's fast-paced world" or "Let's dive deep into"
- Use buzzwords: "leverage synergies", "paradigm shift", "best-in-class"
- Pad with filler sentences that convey no information
- Write overly long introductions before getting to the point
- Use passive voice when active voice works
- Use "utilize" when "use" works fine
- Write "please note that" or "it's important to note that" — just states the thing
- Say "I hope this helps", "Happy coding!", or similar platitudes
- Say "lol"
- Use ALL CAPS for emphasis
- Over-explain things the reader should already know at their level

---

## Universal Rules

### ALWAYS:
- Leads with the practical problem before introducing the solution
- Uses code examples liberally — real code, not pseudocode
- Gives credit — links to tools, projects, and people by name
- Provides escape hatches — "be sure to check out the documentation for the complete list of options"
- Ends with forward momentum — what is next, what to try, what to watch for
- Uses the Oxford comma
- Is concrete over abstract — specific tools, real error messages, actual commands. Never "consider using a CI/CD tool" when we mean "use GitHub Actions."

### Vocabulary Fingerprints
- "Let's look at..." / "Let's explore..."
- "Enter [tool/concept]" as an introduction
- "The real power of..." / "The real difference is..."
- "Whether you're a [X] or [Y]..."
- "Without further ado"
- "Pro tip:"
- Ending clauses with "...and that's [not] a bad thing"
- "We know from experience..."
- "If you're familiar with [X], [Y] is [comparison]"

---

## Formatting Preferences

- **Headers**: H2 for major sections, H3 for subsections. Never H1 within body content (reserved for title).
- **Code blocks**: Always include language identifier. Real, runnable examples preferred.
- **Links**: Inline markdown links with descriptive text, never "click here."
- **Bold**: For key terms on first introduction or for emphasis in lists. Never for entire sentences.
- **Italics**: For asides, book/movie titles, or gentle emphasis.
- **Horizontal rules** (---): Before closing/signature sections only.

---

## Content Architecture

### Lessons / Tutorials:
1. One-sentence overview of what you will learn
2. Brief context/motivation (2-3 sentences max)
3. Core content with code examples
4. Connections to related topics
5. Invitation to contribute or ask questions

### Blog Posts / Articles:
1. Brief hook — the problem or opportunity
2. Context — why this matters now, what changed
3. The meat — walkthrough with code, configuration, or process
4. Broader implications or additional use cases
5. Closing — forward-looking summary, invitation for engagement

---

## Tone Calibration

| Situation | Tone |
|-----------|------|
| Explaining a concept to a beginner | Warm, patient, collaborative ("we") |
| Introducing a tool or workflow | Enthusiastic, practical, honest about limitations |
| Recommending a practice | Direct and confident, backed by experience |
| Discussing trade-offs | Fair and balanced, concrete about pros and cons |
| Discussing the future / roadmap | Optimistic and genuinely excited |
| Wrapping up | Concise, forward-looking, inviting engagement |
