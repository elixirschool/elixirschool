%{
  author: "George Mantzouranis",
  author_link: "https://github.com/gemantzu",
  date: ~D[2018-08-22],
  tags: ["phoenix", "review"],
  title: "Reviewing Functional Web Development with Elixir, OTP, and Phoenix",
  excerpt: """
  Lance Halvorsen shows us how to build our a guessing video game from the ground up using Elixir and OTP. In the end, he shows us how to build a fully working UI experience with Phoenix, Presence and Channels.
  """
}

---

Our first review was quite popular and the feedback we received has been wonderful!
We want to thank everyone for their support and take a moment to congratulate our [raffle winners](https://twitter.com/elixirschool/status/1013961507221073920).

As part of our review series we hope to release at least one review per month.
Along with these reviews, we're hoping to be able to offer additional discounts and giveaways.

For the next part of this series, we are reviewing [_Functional Web Development with Elixir, OTP, and Phoenix_](https://pragprog.com/book/lhelph/functional-web-development-with-elixir-otp-and-phoenix) by [Lance Halvorsen](https://twitter.com/lance_halvorsen).


## Author

Lance has been developing software for the web professionally for two decades. He's worked with a number of languages, frameworks, and approaches during that time. All of those experiences feed into his current thoughts on web development, which are captured in this book.

Lance is also the original author of the Phoenix Guides, and is a Phoenix core team alumnus.

If you want to have an idea about the author and the content of the book, check out [this awesome video](https://www.youtube.com/watch?v=lDKCSheBc-8)

## Target

What is the target audience of the book? There is no better place to look than the book's introduction:

> On a practical level, this book is for people who have some familiarity with Elixir and Phoenix, and who want to take that knowledge further. But there’s a wider list for whom the ideas in this book will resonate.
>
> For people who view OTP with a little trepidation, or for those who haven’t quite mastered OTP Behaviours, this book will give you the confidence to use OTP in any application.
>
> For people who have felt the sting of tight coupling between business logic and web frameworks, this book will show you a way out of that pain forever. For people who feel constrained by traditional web development, you will learn new techniques and new ways to structure apps that will spark your imagination.
>
> For people who are wondering what all the fuss is about with Elixir and Phoenix, you’ll get a great taste of what makes people so excited. You just might become a convert!

This book is certainly not for beginners and Lance doesn't mince words when saying as much:

> Readers looking for an introduction to Elixir or Phoenix would do well to begin with other resources.
>
> We won’t cover the basics of Elixir. I’ll assume you know them before you begin.
>
> If you need to get up to speed first, don’t worry—we’ll be here when you’re ready. In the meantime, Dave Thomas’s book, Programming Elixir 1.3 [Tho16], is a great place to start.
>
> The same is true for Phoenix. We will take a close look at channels and Presence, but you won’t learn the rest of Phoenix here. You should be able to follow along in this book without that information, but if you want to fill in the gaps, Programming Phoenix [TV16] by Chris McCord, Bruce Tate, and José Valim is the book to reach for.

## Review

This book is quite small at only 214 pages, a tutorial covering the development of a game from the beginning to the end, explaining step by step what we are doing and the technology included.

The focus of the book on building a game had me quite interested so I purchased it while still in early beta.
This is a standard 2-player position guessing game called Islands (it looks like Battleship). Each player sets up a handful of islands on their boards, and then starts guessing on the opponent island coordinates. When all islands are found, the game ends.

If you took the time to watch the author's video above, you have an idea of what to expect in the book.
Something that might surprise many readers: **Phoenix is not your application**, it's simply a presentation layer for our underlying logic.
In this book Lance attempts to help readers understand how to properly develop an application from the ground up starting with our business logic and growing from there.
Data persistance and UI are details that come later, as they become necessary to support features.

The content is quite nicely paced which makes understanding the topics easy and enjoyable.

## Chapter Analysis

The book has 7 chapters divided into 3 main parts: our business logic, implementing OTP behaviours, and finally adding a UI.

Chapter 1 is an introduction, a roadmap of the adventure that lies ahead of us.

In Part 1 we focus on the business logic as a game engine.
We begin designing the entities of our game in Chapter 2 and add a custom State Machine to handle our game rules in Chapter 3.

It goes without saying that the first part is the most important one in the book.
Lance seeks to force us to rewire our brains on how to kick start an app, without the use of a framework or the database strangling us from the get-go.
This is the [red pill](https://en.wikipedia.org/wiki/Red_pill_and_blue_pill), our way out of the complacency that `mix phx.new` and other frameworks have lulled us into.

In the second part of the book we add some important OTP behaviours in our system, a GenServer in Chapter 4 and a Supervision Tree in Chapter 5.

In the final part we introduce our presentation layer: a web-based UI.
Here we'll create a new Phoenix application and add our game engine as a dependency in Chapter 6.
In Chapter 7 we explore Channels and Presence to finish implementing our working game.

The structure of the book is based on _scalable knowledge_, you begin with nothing in your hands, just a miniature elixir app, and start designing around your needs, piece by piece. Not a single chapter feels forced, that it is there just to add some pages or just to introduce something the author wanted to say.

## Conclusion

I thoroughly enjoyed the book and my view of our craft in general changed a lot because of it. I started looking for ways to implement this way of programming in other languages / frameworks (mostly in vain, but what can you do?). The design technique described in this book can be applied to every app you can imagine, and it actually makes it easier to build it, because you stop thinking about your app in detail-land (UI, database). It also leads to more maintainable code, as your logic being outside the framework, helps you work on the core of your app and the interface independently, without changes on one having side effects on the other that easily.

That said there are two things that I think would have made it a grand slam: testing and the presentation implementation.

The use of testing, would have been a welcomed addition. Relying on `iex` to execute and valuate the code felt time consuming and didn't drive home the best practices the book encourages elsewhere. While I understand the author's goal with using `iex` I am not entirely sold on this idea. I think an opportunity to demonstrate how to properly test our code was lost. There was a talk with the author in the Pragmatic Bookshelf at the time of development of the book and when asked about this, he responded that he _did_ start working on the book using tests, but the tests started taking over the book.

The second improvement would be on how we implement our presentation layer for two reasons:

Firstly, as with `iex` testing above I did not care for relying on the in-browser console to execute and test my JavaScript code.
Through the course of the final section we write a significant amount of JavaScript.
When we go to test our game in another browser, we have to code this JavaScript and run it again via our console.
Correctly building and testing JavaScript applications isn't the focus on this book but I feel there could have been a better approach.

Finally, the book ends when you are supposed to start building the UI, and provides us with some files to copy paste inside our existing codebase so we can see the final result.
We've spent over 180 pages understanding why we're doing what we are and it ends unceremoniously with us copying the majority of our front end code from elsewhere.
I know that this book is about Elixir and OTP mostly but in my opinion the author could have written a final part that relied on writing down some code and explaining more along the way.
It would have resulted an additional chapter or two but would have provided better closure to those who need it (like myself) while allowing others to skip it. Having said that, I feel I can justify the authors choice on this, as our community's attitude towards JS tends to be aggressive, but this is a theme for another post.

## Giveaway

We are giving away 3 free **physical** copies of Lance Halvorsen's _Functional Web Development with Elixir, OTP, and Phoenix_.
Want your chance to win a free copy?
Follow us on [Twitter](https://twitter.com/elixirschool) and retweet [this blog post announcement](https://twitter.com/elixirschool/status/1032385564119523329)!
We'll be picking winners on September 15th, don't miss your chance!

Look for more reviews to come soon!
