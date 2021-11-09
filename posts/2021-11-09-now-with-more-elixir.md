# Now With More Elixir!

If you follow us on Twitter then you may have gotten a sneak peek at the new site before today's big launch but for those who haven't followed along we thought we'd cover this exciting new chapter in our history.

## TL;DR The History

The very first commit for Elixir School took place the day after my birthday many moons ago now: May 31, 2015. Since then the project as evolved from me to over 500 individuals who've contributed new content, translations, and other improvements. As things grew it became clear we needed to migrate from markdown in a repo, and given the lack of options in the Elixir space at the time, we selected Jekyll. Jekyll got us online and continues to serve us well provide a static site that handles 10s of thousands of weekly users all across the globe.

But there's something about the place to go for learning Elixir to be built on a Ruby tool. Not to mention the simplicity to a static site is great but hampers some of the cooler ideas we've had.

Fast forward six years later and there's a vibrant community around Elixir and with this wealth of experience, perspective, and background has come some really wonderful tooling.

Without further ado let's look at how we got from Jekyll to Phoenix!

## Jekyll to Phoenix

### Nimble Publisher

The single biggest hurdle in our journey from Jekyll to Phoenix has been figuring out the best way to migrate the existing content without rewriting it, losing contributor history, or adding additional burdens on contributors. Enter Dashbit's NimblePublisher library!

We'll be covering our usage of NimblePublisher in follow-on blog posts.

### Custom mix Tasks

Custom mix tasks are employed for two main purposes today: sitemap generation and the rss feed. These two tasks leverage the content module we built with NimblePublisher.

Of the two tasks the RSS feed is the most straight forward, we enumerate our list of blog posts and build up an XML document:

```elixir
defmodule Mix.Tasks.SchoolHouse.Gen.Rss do
  use Mix.Task

  alias SchoolHouse.Posts
  alias SchoolHouseWeb.{Endpoint, Router.Helpers}

  @destination "assets/static/feed.xml"

  def run(_args) do
    Mix.Task.run("app.start")

    items =
      0..(Posts.pages() - 1)
      |> Enum.flat_map(&Posts.page/1)
      |> Enum.map(&link_xml/1)
      |> Enum.join()

    document = """
    <?xml version="1.0" encoding="UTF-8" ?>
    <rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
      <channel>
        #{items}
      </channel>
    </rss>
    """

    File.write!(@destination, document)
  end

  defp link_xml(post) do
    link = Helpers.post_url(Endpoint, :show, post.slug)

    """
    <item>
      <title>#{post.title}</title>
      <description>#{post.excerpt}</description>
      <pubDate>#{Calendar.strftime(post.date, "%a, %d %B %Y 00:00:00 +0000")}</pubDate>
      <link>#{link}</link>
      <guid isPermaLink="true">#{link}</guid>
    </item>
    """
  end
end
```

The sitemap generator follows a similar format but the value of content and it's structure makes the task a bit more complicated. We break down the generation into a couple steps:

1. Add the blog index and our privacy policy

   ```elixir
   defp all_links do
     [
       Helpers.post_url(Endpoint, :index),
       Helpers.page_url(Endpoint, :privacy)
     ] ++ post_links() ++ Enum.flat_map(supported_locales(), &locale_links/1)
   end
   ```

2. Create a collection of blog post links

   ```elixir
   defp post_links do
     0..(Posts.pages() - 1)
     |> Enum.flat_map(&Posts.page/1)
     |> Enum.map(&Helpers.post_url(Endpoint, :show, &1.slug))
   end
   ```

3. Build up the links for each locale. This includes all lessons and pages such as conferences, podcasts, "Why Elixir?", and others.

   ```elixir
   defp locale_links(locale), do: page_links(locale) ++ lesson_links(locale)

   defp page_links(locale) do
     [
       Helpers.page_url(Endpoint, :conferences, locale),
       Helpers.page_url(Endpoint, :index, locale),
       Helpers.page_url(Endpoint, :podcasts, locale),
       Helpers.page_url(Endpoint, :why, locale),
       Helpers.report_url(Endpoint, :index, locale)
     ]
   end

   defp lesson_links(locale) do
     config = Application.get_env(:school_house, :lessons)

     translated_lesson_links =
       for {section, lessons} <- config, lesson <- lessons, translated_lesson?(section, lesson, locale) do
       Helpers.lesson_url(Endpoint, :lesson, section, lesson, locale)
       end

     section_indexes =
       for section <- Keyword.keys(config) do
       Helpers.lesson_url(Endpoint, :index, section, locale)
       end

     section_indexes ++ translated_lesson_links
   end

   defp translated_lesson?(section, lesson, locale) do
     case Lessons.get(section, lesson, locale) do
     {:ok, _} -> true
     _ -> false
     end
   end

   defp supported_locales do
     :school_house
     |> Application.get_env(SchoolHouseWeb.Gettext)
     |> Keyword.get(:locales)
   end
   ```


Both tasks are run in our release process and stored in the static directory to be served alongside things like `robots.txt`:

```elixir
plug Plug.Static,
  at: "/",
  from: :school_house,
  gzip: false,
  only: ~w(css fonts images js favicon.ico robots.txt feed.xml sitemap.xml)
```

### Roadmap Forward

#### New Content

With this launch we also restructured our content into new sections! This paves the way for much more content and a more managable way to organize and consume it. Some of the new content you can be on the look out for:

1. **Advanced Content**

   1. Dedicated meta programming lesson that explores this powerful functionality
   2. Greatly expanding on our Specifications and Type content

2. **Data Processing**

   1. New Leson: Broadway library by Dashbit
   2. New Lesson: Flow

   Together these give us coverage of the data trifect: GenStage, Flow, and Broadway.

3. **Ecto**

   1. Expanding existing Ecto content
   2. New Lesson: Advanced Ecto querying techniques

4. **Storage**

   1. New Lesson: Redix library
   2. New Lesson: Cachex library

5. **Fundamentals**

   1. New Lesson: Functional Programming 101
   2. New Lesson: Functional Programming 102
   3. New Lesson: Data structures

We continue to discuss the possibility and value of expanding into Phoenix and Erlang content more heavily. We'd love your feedback! Interested in contributing to some of these lessons? Have suggestions for content? Don't hesitate to reach out or get involved!

Our lessons aren't all! We've got a lot of exciting blog content in mind for the coming months:

1. We plan to resume our book, course, and conference reviews to continue to provide the community with an unbiased resource on which learning materials available to them are worth the expense.
2. In conjunction with Elixir Companies we're going to be kicking off a new blog series on companies using Elixir. Some of the questions you've been asking we aim to answer: Who's using Elixir? How did they end up selecting Elixir? How has the onboarding been? What is Elixir used for?
3. Community Spotlights! There's **alot** of amazing people in the community many of which don't get the recoginition they deserve. We want to fix that by selecting and highlighting those who're giving back to the community and moving us all forward. There's some terrific people involved in Elixir overshadowed by a smaller louder group and we want to change that!


