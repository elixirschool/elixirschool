%{
  author: "Sean Callan",
  author_link: "https://github.com/doomspork",
  date: ~D[2025-07-31],
  tags: ["automation", "releases", "software design"],
  title: "Automating Elixir Releases with Release Please",
  excerpt: """
  Discover how to streamline your Elixir project releases using Google's Release Please.
  Learn to automate changelog generation, version bumping, and GitHub releases while embracing conventional commits for better project management.
  """
}

---

Managing releases can be one of the most tedious aspects of maintaining an Elixir project (or any project). Manually updating version numbers in `mix.exs`, crafting changelogs, creating GitHub releases, and ensuring consistency across your project can quickly become overwhelming as your project grows. What if we could automate all of that while also improving your development workflow? 

Enter [Release Please](https://github.com/googleapis/release-please), Google's open-source tool that automates the entire release process by parsing Git history and generating releases based on conventional commit messages. In this this post we'll cover what Release Please is and how it works and work through how you can fully automate the release pipeline for your Elixir project. The end result will be professional changelogs, automatic semantic versioning, and published GitHub releases with zero manual intervention.

## What is Release Please?

Release Please is an automation tool developed by Google that generates release Pull Requests containing changelogs and version bumps for your projects. Instead of continuously releasing every commit, Release Please maintains "Release PRs" that are kept up-to-date as additional work is merged. When you're ready to create a release simply merge the Release PR.

The magic happens through conventional commit messages allowing Release Please to analyze your Git history and use it to:

- Automagically generate a changelog organized by sections for features, fixes, and breaking changes.

- Determine the next version using semantic versioning ([SemVer](https://semver.org)) and update version references in your `mix.exs` and documentation. Gone are the days of wondering and debating whether to bump the patch or minor version, Release Please does that for you based on the commits in a release!

- Create and maintain release Pull Requests that stay current with your changes. As commits are merged to `main` Release Please will update the release PR to include changelog and version updates.

- Generate GitHub releases with release notes based on your changes.

All that's left is to handle your deployment, or package publishing, when new releases are created on merge of the Release Please PR.

## Understanding Conventional Commits

Before diving into Release Please configuration let's look at what makes it possible: [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/). This lightweight specification provides structure to commit messages, making them human and machine-readable. At first it may feel like extra work but once you get used to using conventional commits you'll really appreciate the consistency, git history cleanliness, and the automation that comes from their adoption.

### The Basic Format

Conventional commits follow this structure:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Essential Commit Types for Releases

Release Please recognizes several commit types but by default three are critical for triggering releases:

**feat**: Introduces a new feature (triggers a MINOR version bump)
```bash
git commit -m "feat: add user authentication module"
git commit -m "feat(accounts): implement password reset functionality"
```

**fix**: Patches a bug (triggers a PATCH version bump)  
```bash
git commit -m "fix: resolve connection timeout in HTTP client"
git commit -m "fix(database): handle nil values in user queries"
```

**BREAKING CHANGE**: Introduces breaking changes (triggers a MAJOR version bump)
```bash
git commit -m "feat!: redesign user API with new authentication flow

BREAKING CHANGE: The previous authentication endpoints are no longer supported.
Users must migrate to the new /auth/v2 endpoints."
```

### Additional Helpful Types

While these don't trigger releases by default they improve changelog organization:

| Type      | Description                                   |
|-----------|-----------------------------------------------|
| **docs**      | Documentation changes                         |
| **chore**     | Maintenance tasks, dependency updates          |
| **refactor**  | Code restructuring without functional changes  |
| **test**      | Adding or updating tests                      |
| **ci**        | Changes to CI/CD configuration                |

### Real-World Examples

Let's look at some commit messages you might write for an Elixir project:

```bash
# New feature - triggers minor version bump
git commit -m "feat(auth): add JWT token validation middleware"

# Bug fix - triggers patch version bump  
git commit -m "fix(database): resolve race condition in connection pool"

# Breaking change - triggers major version bump
git commit -m "feat!: migrate to Phoenix 1.7 LiveView syntax

BREAKING CHANGE: All LiveView components updated to use
the new ~H sigil syntax. See migration guide for details."

# Non-release commits - no version bump by default
git commit -m "docs: update README with new installation instructions"
git commit -m "chore: upgrade Credo to latest version"
git commit -m "test: add property-based tests for user validation"
```

To learn more about conventional commits be sure to review the specification on [conventionalcommits.org](https://www.conventionalcommits.org/en/v1.0.0/).

## Setting Up Release Please for Your Elixir Project

Now that we've covered conventional commits let's jump into configuring Release Please for an Elixir project. We'll walk through the complete setup process step by step.

Release Please offers two configuration approaches: Simple CLI-based for simple projects and Manifest-driven configuration for fine-grained control.

Let's look at both approaches, starting with the simpler method and progressing to the more powerful manifest-driven configuration.

### Simple Configuration Approach

For straightforward Elixir projects, we can use Release Please without configuration files. This approach works well for single-package repositories with standard requirements.

Create `.github/workflows/release-please.yml` in your repository:

```yaml
name: Release Please

on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          release-type: elixir
          package-name: example_app
```

This basic GitHub Action tells Release Please to monitor pushes to the `main` branch, use the `elixir` release type (which understands `mix.exs` files), and name the package `example_app` (you'll need to replace this with your actual project name)

### Advanced Manifest-Driven Configuration

For more control over the release process we can use manifest-driven configuration. This approach is particularly valuable for monorepos or when you want customization.

First, create `release-please-config.json` in your project root:

```json
{
  "release-type": "elixir",
  "separate-pull-requests": false,
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "changelog-sections": [
    {"type": "feat", "section": "Features"},
    {"type": "fix", "section": "Bug Fixes"},
    {"type": "perf", "section": "Performance Improvements"},
    {"type": "deps", "section": "Dependencies"},
    {"type": "chore", "section": "Miscellaneous", "hidden": true}
  ],
  "pull-request-title-pattern": "chore: release ${version}",
  "pull-request-header": ":robot: I have created a release *beep* *boop*",
  "extra-files": [
    {
      "type": "elixir",
      "path": "README.md",
      "glob": true
    }
  ]
}
```

Next, create `.release-please-manifest.json`:

```json
{
  ".": "0.1.0"
}
```

This manifest file tracks the current version of your project. The `"."` key represents the root of your repository. 

**Note**: If you're introducing Release Please into an existing project make sure `.release-please-manifest.json` is set to the current released version, not `0.1.0`.

Now update your GitHub Actions workflow to use manifest configuration:

```yaml
name: Release Please

on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          command: manifest
          token: ${{ secrets.GITHUB_TOKEN }}

  # Optional: Run additional jobs after release
  publish-hex:
    runs-on: ubuntu-latest
    if: ${{ needs.release-please.outputs.release_created }}
    needs: release-please
    steps:
      - uses: actions/checkout@v4
      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
      - name: Install dependencies
        run: mix deps.get
      - name: Publish to Hex.pm
        run: mix hex.publish --yes
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

## Customizing Your Release Process

We can cutomize Release Please in many ways to fix our specific needs. Let's explore the most useful configurations for Elixir projects, but be sure to check out the [Release Please documentation](https://github.com/googleapis/release-please/tree/main/docs) for the complete list of options.

### Changelog Customization

Customizing the look and feel of your changelog can be done by configuring the sections and their visibility:

```json
{
  "changelog-sections": [
    {"type": "feat", "section": "🎉 New Features"},
    {"type": "fix", "section": "🐛 Bug Fixes"},
    {"type": "perf", "section": "⚡ Performance Improvements"},
    {"type": "deps", "section": "📦 Dependency Updates"},
    {"type": "docs", "section": "📚 Documentation", "hidden": false},
    {"type": "chore", "section": "🔧 Maintenance", "hidden": true},
    {"type": "test", "section": "✅ Tests", "hidden": true}
  ]
}
```

### Version Bump Strategy

It's possible to tweak how versions are handled in Release Please. For example, in projects that haven't reached version 1.0.0 you might want different versioning behavior:

```json
{
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "prerelease-type": "alpha"
}
```

With this configuration, breaking changes bump the minor version (0.1.0 → 0.2.0) instead of major, features bump the patch version (0.1.0 → 0.1.1) instead of minor, and prerelease versions will be marked as "alpha".

### Pull Request Customization

It's possible to customize the appearance of the release Pull Requests too:

```json
{
  "pull-request-title-pattern": "chore: release ${component} ${version}",
  "pull-request-header": "🚀 **Release Time!** This PR contains the next release for our project.",
  "pull-request-footer": "---\n\nThis PR was generated automatically by Release Please. 🤖"
}
```

### Extra Files

With the `extra-files` configuration you can include additional files during releases (like README badges or documentation):

```json
{
  "extra-files": [
    {
      "type": "generic",
      "path": "README.md",
      "glob": false
    },
    {
      "type": "generic", 
      "path": "docs/installation.md",
      "glob": false
    }
  ]
}
```

## Working with Release Please in Practice

Now that Release Please is configured, let's see how it works in a real development workflow.

### The Development Cycle

1. Write code with conventional commits:
   ```bash
   git add lib/example_app/user.ex
   git commit -m "feat(user): add email validation with custom patterns"
   
   git add test/example_app/user_test.exs  
   git commit -m "test(user): add comprehensive email validation tests"
   
   git add lib/example_app/auth.ex
   git commit -m "fix(auth): resolve token expiration edge case"
   ```

2. Push to your main branch:
   ```bash
   git push origin main
   ```

3. Release Please automatically creates/updates a release PR:
   
   Within minutes of your push, Release Please will either create a new release PR or update an existing one. The PR will contain an updated `mix.exs` with the new version number, the generated `CHANGELOG.md` with organized sections, and release notes summarizing the changes.

### Understanding the Generated Changelog

Here's an example Release Please generated changelog:

```markdown
# Changelog

## [2.5.0](https://github.com/beam-community/bamboo/compare/v2.4.0...v2.5.0) (2025-07-25)


### Features

* Add support for all Mailgun `o:` options ([#718](https://github.com/beam-community/bamboo/issues/718)) ([22e231d](https://github.com/beam-community/bamboo/commit/22e231dc7da03cd942f1249241031d5a5e7e887e))

## [2.4.0](https://github.com/beam-community/bamboo/compare/v2.3.1...v2.4.0) (2025-03-05)


### Features

* Print email metadata on preview without body ([6ad48f7](https://github.com/beam-community/bamboo/commit/6ad48f7834d8b70ff892de0e3c983560dbb13433))
* SendGrid `subscription_tracking` setting ([#655](https://github.com/beam-community/bamboo/issues/655)) ([381d257](https://github.com/beam-community/bamboo/commit/381d25740cdf5f52caf991e3da02ead85056f68d))
* sendgrid support for content_id  ([#691](https://github.com/beam-community/bamboo/issues/691)) ([7a878f4](https://github.com/beam-community/bamboo/commit/7a878f4e4d3f988e6ee2e81623d796d3cc8700ac))

## [2.3.1](https://github.com/beam-community/bamboo/compare/v2.3.0...v2.3.1) (2024-09-26)


### Bug Fixes

* Fix Elixir 1.17 warning about function call without parens ([1c1d002](https://github.com/beam-community/bamboo/commit/1c1d002a5ef74e4494e777aa64ad4068a234ccd0))
* fix invalid typespec ([7b5d99d](https://github.com/beam-community/bamboo/commit/7b5d99dd46b5466e5e4f857c2403a76114212e3e))
* README badge and broken links ([c0ea19b](https://github.com/beam-community/bamboo/commit/c0ea19b54f1ca95c7718d3288b8f67a724c07ee2))

```

Our generated changelogs include links to GitHub comparisons between versions, commits organized by type (Features, Bug Fixes, etc.), and a link for each entry to the specific commit.

## Advanced Scenarios and Troubleshooting

As you use Release Please more extensively, you may encounter some advanced scenarios. Let's address the most common ones for Elixir projects.

### Managing Pre-release Versions

For alpha, beta, or release candidate versions, configure prerelease settings:

```json
{
  "prerelease": true,
  "prerelease-type": "beta"
}
```

This generates versions like `1.2.0-beta.1`, `1.2.0-beta.2`, etc.

### Bootstrapping an Existing Project

If you're adding Release Please to an existing project with a complex history:

1. Use the bootstrap command to create initial configuration:
   ```bash
   npx release-please bootstrap \
     --repo-url=elixirschool/example_app \
     --release-type=elixir \
     --initial-version=1.0.0
   ```

2. Set a bootstrap SHA in your configuration to start from a specific commit:
   ```json
   {
     "bootstrap-sha": "abc123def456...",
     "release-type": "elixir"
   }
   ```

### Handling Multiple Applications

Release Please makes it easy to manage releases in a monorepos even when we're using multiple languages:

```json
{
  "separate-pull-requests": true,
  "packages": {
    "backend": {
      "release-type": "elixir",
      "package-name": "example_backend"
    },
    "ui": {
      "release-type": "node", 
      "package-name": "example_ui"
    }
  }
}
```

With this configuration we'll have a changelog and release PR for each project!

## Integration with the Broader Ecosystem

Since Release Please is doing all the heavy lifting for us and creates releases in GitHub we can use that event trigger our push to Hex, publish a new docker image, or deploy our changes to Fly.io.

### Hex.pm Publishing

Automatically publish packages to Hex.pm when releases are created:

```yaml
publish-hex:
  runs-on: ubuntu-latest
  if: ${{ needs.release-please.outputs.release_created }}
  needs: release-please
  steps:
    - uses: actions/checkout@v4
    - name: Set up Elixir
      uses: erlef/setup-beam@v1
      with:
        elixir-version: '1.17'
        otp-version: '27'
    - name: Install dependencies
      run: mix deps.get
    - name: Run tests
      run: mix test
    - name: Publish to Hex
      run: mix hex.publish --yes
      env:
        HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

### Docker Image Publishing

Build and publish Docker images for releases:

```yaml
build-docker:
  runs-on: ubuntu-latest
  if: ${{ needs.release-please.outputs.release_created }}
  needs: release-please
  steps:
    - uses: actions/checkout@v4
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        push: true
        tags: |
          elixirschool/example-app:latest
          elixirschool/example-app:${{ needs.release-please.outputs.tag_name }}
```

### Documentation Generation

Update documentation sites automatically:

```yaml
update-docs:
  runs-on: ubuntu-latest
  if: ${{ needs.release-please.outputs.release_created }}
  needs: release-please
  steps:
    - uses: actions/checkout@v4
    - name: Generate docs
      run: mix docs
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./doc
```

## Conclusion

Release Please turns the tedious work of managing releases into an automated workflow that eases the burden of maintaining projects and releases. With conventional commits and Release Please you're not just automating busywork, you're achieving a cleaner and more communicative git history, along with a consistent release process, all of which translates into a better experience for your team and users. 

Starting with Release Please and conventional commits might feel like extra overhead at first but you'll quickly see the investment pay off. The combination of conventional commits and automated releases creates a sustainable release workflow that scales.

As you experience the benefits firsthand I'm confident you'll find yourself wanting to implement these changes across all your projects.

Have you implemented Release Please in your Elixir projects? What challenges did you encounter, and how did you overcome them? We'd love to hear about your experiences and learn from your insights!

---

*Want to see Release Please in action? Check out some of the Elixir projects already using it: [ExMachina](https://github.com/beam-community/ex_machina), [Bamboo](https://github.com/beam-community/bamboo), and [Tesla](https://github.com/elixir-tesla/tesla). The future of automated releases is here, and it's more accessible than ever.*