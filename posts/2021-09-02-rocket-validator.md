%{
  author: "Jaime Iniesta",
  author_link: "https://github.com/jaimeiniesta",
  tags: ["Announcement"],
  date: ~D[2021-09-02],
  title: "Validating Accessibility and HTML with Rocket Validator",
  excerpt: """
  Learn how we're checking and monitoring the new Elixir School site to detect and fix accessibility and HTML issues using Rocket Validator.
  """
}
---

## Intro

One of the core principles of Elixir School is to be an inclusive community. We want to help people from all over the world learn to code using Elixir. To facilitate that, we provide translations of the lessons to many languages, maintained by volunteers worldwide. By removing the language barrier, we're helping more people get into the Elixir community.

Apart from the language barrier, there are other barriers that we're aware of - [web accessibility barriers](https://www.w3.org/WAI/people-use-web/abilities-barriers/) are everywhere on the World Wide Web, making it harder for people to access content that is often taken for granted.

Low vision may make a web page unreadable if the text has low contrast or the font size cannot be adapted easily. Unsighted people can use screen readers to hear the page content, but it won't work well if it is poorly structured and can't be properly interpreted by the screen reader software. People with reduced mobility may prefer to navigate through the lessons using the keyboard instead of the mouse, but this won't work if the document is not laid out correctly.

The good news is that we can make Elixir School accessible for everyone. It requires that we're aware of those barriers and follow the web standards to provide well-structured web pages.

## How to find accessibility and HTML issues

The World Wide Web Consortium (W3C) is an international community that defines and develops [Web standards](https://www.w3.org/standards/), HTML being probably the most used -and abused- of those standards. At the end of 1997, the [W3C launched](https://www.webdesignmuseum.org/web-design-history/w3c-html-validator-1997) the [W3C HTML Validator](https://validator.w3.org/), a service to check any web page and find issues in its HTML structure. More than two decades later, this service is still in good health, and many tools have been built around its [open source validator](https://github.com/validator/validator).

HTML is the basis of web pages, but a perfectly valid HTML page can still have accessibility issues. For example, a web page may have a bad combination of colors that results in low contrast: a light color text over a light background may lead to unreadable text by people with low vision. If a video has no captions, deaf users won't understand what it's talking about. Sections of the document may not be accessible for users that don't employ a mouse to move through the document. Zooming and scaling may be disabled, making it impossible for the users to enlarge the web page to see it better. Many known issues are easily detected using automated accessibility checkers like [axe-core](https://github.com/dequelabs/axe-core).

## The power of automated site validation

It's great that we have tools that help in detecting issues on web pages. Both the W3C HTML validator and axe-core are open source and can be incorporated into our web development flow. But, there's an important limitation: they can only check one URL at a time. So, when you have a small website with just a few web pages, it might be an option to do manual checks using these tools. But, what can we do with a large site like Elixir School? According to the latest reports, Elixir School has more than 1,000 web pages. If we want to check them all with the W3C Validator and axe-core, we would need to run 2,000 manual checks!

## 🚀 Rocket Validator to the rescue

[Rocket Validator](https://rocketvalidator.com) is an online service that performs site-wide validation of large websites. It's an automated web crawler that will find the internal web pages of a site and validate each web page found using the W3C Validator and axe-core, producing detailed reports on the issues found, within seconds.

This service, also powered by Elixir, Phoenix, LiveView, and Oban, is a subscription-based service for web agencies and freelance developers. But, it's free for open source projects like [Elixir School](https://github.com/elixirschool/school_house/pulls?q=is%3Apr+label%3A%22rocket+validator%22+is%3Aclosed) and [Docusaurus](https://github.com/facebook/docusaurus/pulls?q=is%3Apr+rocket+validator)! We're using Rocket Validator to run reports on the new Elixir School and monitor the site via weekly-scheduled and deploy-triggered validations.

## Running a site validation report

To run a site-wide validation report, we need to enter a starting URL. This URL is usually the front page of the site we're going to validate, but it can be any internal URL, or an XML or TXT sitemap containing the web pages to validate. Rocket Validator will visit this initial URL and discover the internal web pages, adding them to the report.

![Rocket Validator new site validation report](https://www.dropbox.com/s/amt7ilhw3b0sdh2/rocket-validator-new-report.png?raw=1)

We can also define the validation speed as a rate limit of requests per second and define the options:

* **Check HTML**. Will run the W3C HTML Validator on each page found.
* **Check Accessibility**. Will run axe-core on each page found.
* **Deep Crawl**. Will find more web pages on the site by following recursively the internal links found.

Once we click on **Start Validation**, results will appear within seconds as the web pages are validated. We can browse the Summary Report to see a global overview including the most important issues (so you know what to fix first), as well as reports that group the common issues on the site and detailed reports per each web page.

![Rocket Validator summary report](https://www.dropbox.com/s/z611nr8ofpikawx/rocket-validator-summary-report.png?raw=1)

## Validating light / dark modes for contrast issues

Elixir School has a light / dark mode switch which is great to choose the UI you prefer, but this also means all of our URLs need to be validated in light mode and dark mode to ensure there are no low contrast issues for each theme.

![Light and Dark modes on Elixir School](https://www.dropbox.com/s/yzzj595vteqdi69/rocket-validator-contrast.png?raw=1)

To validate accessibility on both the light and dark modes, we came up with the idea of adding an optional parameter `?ui=dark` on the URLs that, when present, enables dark mode. So, we can run reports for the light mode using the default [light mode XML sitemap](https://beta.elixirschool.com/sitemap.xml) and reports for the dark mode using the [dark mode XML sitemap](https://beta.elixirschool.com/sitemap_dark_mode.xml) that adds this parameter to the URLs.

With these XML sitemaps in place, we generate two kinds of reports:

* One report for the light mode, checking for HTML and accessibility issues.
* An additional report for the dark mode, checking only for accessibility issues, to monitor possible contrast issues. HTML checking is not needed for these URLs as the HTML markup is the same as the light mode.

## Scheduling site validations and deploy hooks

Site validation reports can also be [scheduled](https://docs.rocketvalidator.com/scheduling/) to run daily, weekly or monthly, thus providing constant monitoring on your sites. For Elixir School we've set a weekly schedule on the site, which is sometimes changed to daily when we're working intensively on fixing the site.

We're also using [deploy hooks](https://docs.rocketvalidator.com/deploy-hooks/) - so a new deploy triggers a site validation report. This was very easy to integrate into Heroku with the [Heroku post-hook add-on](https://devcenter.heroku.com/articles/deploy-hooks#http-post-hook).

## Muting issues we won't fix

Validating a site means checking that the web pages adhere to the current web standards, but there are times when a site can't fully meet the strictest standards.

For example, some of the generated code may be out of your scope. In our case, some HTML generated by Phoenix is not standard HTML (for example, properties like `phx-click` or `phx-track-static` are not valid HTML). We're also using Alpine, which makes use of non-standard properties like `x-data` or `x-cloak`.

Once you're aware of those issues and you've considered if a standard alternative is possible, you can decide to just mute those issues. Rocket Validator lets you mute selected issues and prompts you to document the reason for muting them.

## Beyond automated validation

Automated site validation is a powerful tool to find well-known issues on large sites, and it can quickly point to a lot of typical issues with known solutions. Think of it as a scanner that will find "low-hanging fruit" issues on your site - Rocket Validator can detect [almost 100 typical accessibility issues](https://rocketvalidator.com/accessibility-validation) via axe-core, while the [HTML validator](https://rocketvalidator.com/html-validation) can detect many more possible misuses of web standards.

However, manual checking and common sense will always be required in web development. A site may follow the strictest web standards but still not be accessible. Think, for example, of `alt` descriptions in images - they're not useful at all unless they really provide a [meaningful description](https://duckduckgo.com/?q=meaningful+alt+image+description&t=opera&ia=web).

Apart from automated tests, you also need to do manual checks on your site using a screen reader, turning the screen off, navigating using the keyboard instead of the mouse, etc. We're aware of that and have already a list of [issues discovered via manual testing](https://github.com/elixirschool/school_house/issues/114) that will soon be addressed.

## Conclusion

Web page validation is an important step in web development that is often skipped because manually checking each web page is a cumbersome task.

Fortunately, there are ways to automate large site validation, so we can quickly detect and fix HTML and accessibility issues, smashing many accessibility barriers on our sites and making them reachable by a larger number of people.

## Thanks

This article was written by [Jaime Iniesta](https://jaimeiniesta.com), a freelance web developer who has created [Rocket Validator](https://rocketvalidator.com) using Elixir.

Try Rocket Validator on your sites by creating a [Free Rocket Validator Account](https://rocketvalidator.com/registration/new).

If you want to upgrade after that, use the **[ELIXIR](https://rocketvalidator.com/pricing?coupon=ELIXIR) coupon code to get a 50% discount** on the first month of your Rocket Validator Pro subscription plan.
