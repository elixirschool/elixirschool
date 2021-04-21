---
author: George Mantzouranis
author_link: https://github.com/gemantzu
categories: review
date:   2018-06-18
layout: post
title:  Reviewing Elixir in Action, Second Edition
excerpt: >
 The first installment in our new series looking at, and reviewing, different learning materials available to the Elixir community.
---

Welcome to the first post in our new series reviewing various learning material available for Elixir.
Of course you're probably thinking "Elixir School is the best!" and we agree, but as we explore other material to improve our own we want to share it with you along with our thoughts.
To get us started, we're going to kick off our series with a review of Saša Jurić's newest book _Elixir in Action, Second Edition._

_Note 2018-06-18: The book is in beta (MEAP - Manning Early Access Program), very close to production according to the Manning website (September 2018).
You can find more details about it [here](https://www.manning.com/books/elixir-in-action-second-edition)._

## Author

Saša Jurić is a software developer with over a decade of professional experience in programming.
Over the years Saša has worked with languages such as Elixir, Erlang, Ruby, JavaScript, C# and C++ giving him a range of experiences.

## Target

What is the target audience of the book?  There is no better place to look than the book's introduction:

> This is an intermediate level book that teaches about Elixir, Erlang, and how they assist
the development of highly-available server side systems. To fully take advantage of the
material, you should be an experienced software developer. It is not expected that you know
anything about Elixir, Erlang, or functional programming, but you should be skillful in at
least one programming language, such as Java, C#, Ruby, JavaScript.

## Review

Writing a book about a programming language is hard.
It's even harder when that book needs to encompass not only the language but the platform on which it runs as well.
As is often the case with technical books, authors usually choose one of two paths: "tutorial" authors who have readers follow along and build an application from start to finish and "documentation" authors who focus on theory, function definitions, and other technical tidbits.

With this book Saša Jurić has taken another approach: there is a very small project, a ToDoList application, that exists solely to reinforce the readers understanding of each chapter's topics.

He begins every section explaining the language feature, introducing how and why it is used in the sample project, and lastly finishing the section discussing his experiences and perspective with the particular topics. This is done in a quite natural way, each section is (almost) never broken, making our brain focus at one thing at any given time. This allows us to experience the ups and downs and explore the content alongside Saša.

## Chapter Analysis

In total the book has 13 chapters.

In Chapters 1 to 4, we are introduced to the platform, the language and the basics that we can use and find in almost any language (even more on functional ones). We can find details about variables, operators, control flow, data abstractions and protocols (Elixir version of polymorphism). In this section, we begin working on our ToDoList application, and by the end of it, we have a module that contains the CRUD functionality of a ToDoList entity.

Chapters 5 to 11 are probably the most awesome part of the book (and what I believe made the first edition of it so popular amongst Elixir developers), a very thorough explanation about OTP and its counterparts (GenServer, Supervision, ETS Tables, OTP Applications) and the toolkit (Observer, Mix, Plug). In this section a lot of features are added to the ToDoList app: 
* add a custom server process to maintain state
* migrate state to a GenServer
* add a cache so that we start supporting multiple to-do lists
* add basic data persistence
* add a supervision tree and introduce a basic pool of workers
Additionally, we are introduced to ETS tables, OTP Applications and configuration, dependencies and Plug. In this section, I got the feeling that I am pair programming as a junior with the author, sitting beside him while he designs the application. When he finds a hole in his design, he questions himself "What part of the OTP can cover this hole, and how?". Then, he turns to me and gives me a detailed explanation on what we are doing, proceeds with the implementation on the todo-list app, and finally turns to me again and discusses on alternatives and ups and downs of the chosen path. I like this aproach, and I want to see it in more language learning books. 

In the last two chapters, we can see how to make our app run on a cluster, release it using Distillery, and maintain it (Debug, Log etc). The author follows the same approach here as well, albeit not in that much detail, as the topics discussed in this section are very broad (clustering, data replication, network partitions, releases) and would need way too much detail to cover in a language introduction book.

## Conclusion

Lately books are being pushed to the side when it comes to learning new technology and not without good reason, reading and understanding a book requires dedication and a lot of time.
These days most people don't seem to have the time for books, so instead videos and brief tutorials are used to jump start learning.

Another factor working against books is that many authors omit important steps of their thinking process, which ultimately leaves us, the readers, unable to produce a similar solution ourselves.
We're left to wonder: "How the heck did we come up with this solution?  What was the mindset that lead us to this point?".
Fortunately, Saša is excellent at helping the reader understand his reasoning, he explains each step of the process while exploring alternatives when he thinks it's due.

So is Saša Jurić's newest book _Elixir in Action, Second Edition._ worth the investment of your time?

If you're an experienced developer looking to advance your understanding of Elixir and the underlying BEAM: yes.

This IS NOT a beginner's book.
This IS NOT a simple book.
This IS an excellent resource highlighting the potential and shortcomings of Elixir and the BEAM.

If you give it your attention you'll finish the book with a solid understanding of the platform and how best to leverage it at all stages of the development lifecycle.

Look for more reviews to come soon!

## Giveaway

To kick off our new series we are giving away free copies of Saša Jurić's _Elixir in Action, Second Edition._!

Want your chance to win a free copy?
Follow us on [Twitter](https://twitter.com/elixirschool) and retweet this blog post announcement!
We'll be picking winners at the end of the month, don't miss your chance!

Look for more reviews to come soon!
