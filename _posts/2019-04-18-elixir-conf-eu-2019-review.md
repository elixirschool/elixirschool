---
author: George Mantzouranis
author_link: https://github.com/gemantzu
categories: review
date:   2019-04-18
layout: post
title:  Reviewing Elixir Conf EU 2019
excerpt: >
  ElixirSchool was invited to participated in a conference for the first time! Our own @gemantzu was there, and has a lot to say!
---

Last year, it was my first time ever participating in conference. I wanted to go off and see what this community has to offer for me, as Elixir is the first language I have seriously considered working on as a professional. So, year for year, I can provide a direct comparison on how things have fared in our European join.

## Sponsored Ticket

From the beginning, we would like to thank ElixirConfEU, Erlang Solutions and Lawrence Ansell in specific for giving us the opportunity to write a review on the conference, by providing us with a two day free ticket. Just as an FYI, we were never asked to be biased towards writing only good stuff about the conference, and as always, I will try to make it as much objective as I can.

## Whova application

As last year, the conference organizers and attendees made heavy use of the Whova application in our phones, where you can go and organize or take part in conversations and events for the days during the conference. Some examples of the app's usage, were sharing of cabs from and to the airport, evening walks to the city, a dinner for vegeterians, lost and found items etc.

## City

This year, the conference was held in the magnificent city of Prague, the Czech Republic capital. The city is marvelous, one of the most complete experiences I have ever had visiting a city. It was nothing compared to Warsaw, which due to the WWII destruction, had a much more modern look. Prague is an orgasm of big old buildings, with a ton of marvels to invest your time in.

You can enjoy old time experiences, from the Old Town Square, to the Royal Castle, and newer ones, from the Lego Museum to the Gallery of Steel Figures.

The metro of the city helped a lot, as you can jump in and find your way pretty easily around the city, which is relatively spread.

## Venue

The conference took place in Prague Congress Centre, located south of the town centre, in Praha 4. The metro station was right outside, which was very convenient, and the view from outside the centre was wonderful.

## Halls

The organizers had booked two halls from the congress centre, the Forum Hall and South Hall.

Forum hall is a huge ass atrium hall, who could easily house all of us in one sitting. It had great visibility of both the speaker, and his notes. It also had great acoustics.

South hall on the other hand, was a step down. It was much smaller, with three medium monitors where you could view the speakers notes. Sadly, it also had some pillars, and it was flat, which made viewing both the speaker and his notes a challenge.

## Visitors :WIP

__NOTE__ get info from Lawrence about visitors this year versus last year

From the beginning of the conference, I got to see some familiar faces from last year, which made me much more comfortable.

## Food

__NOTE__ probably speak with Lawrence about it, but mention nothing. The food was not that good this year, and had quite limited options as well. The snacks were good though.

## Sponsors with a booth

I got to talk with all of the sponsors that had a booth in the venue, it was really fun. Check out Cultivate, solarisBank, coders51, bitcrowd, ScoutAPM Erlang Solutions and Toyota Connected, they are doing some great stuff with Elixir and some of them are hiring as well.

## Presentations - Day 1

### Keynote - announcing Broadway by José Valim

People tend to view the community's presentations, at least the Keynotes that mean something. Sadly, most people I talked with, were saddened by the fact that José did a repeat of this talk, which most had seen already. I think that in this situation, he should have gone for something different, or had let someone else do a keynote. The presentation itself was stellar as always, giving some history information on what lead us to Broadway.

[![Keynote: Announcing Broadway Elixir Conf EU 2019](https://img.youtube.com/vi/IzFmNQGzApQ/0.jpg)](https://www.youtube.com/watch?v=IzFmNQGzApQ)

### Rewriting critical software in Elixir - a case study by Renan Ranelli

This talk was very interesting, and pretty nicely done. Renan gave us some very insightful information on how to rewrite software, while the old codebase is still getting new features and updates, and also some pitfalls of doing that. It went on for the whole process, from convincing the stakeholders, to going live with the new implementation. The most important tidbit I got out of it would be `Duplicate the requests for new and old service, and find the bug when the response is not the same`.

### Building a GameBoy emulator with Elixir and Scenic by Tonći Galić

Ok, I admit it, I am an old geezer, a true fanatic of the first GameBoy and that's why I went to this talk. Tonći gave a great talk, about how to reverse engineer and tinker with the very difficult project of reverse engineering a whole machine architecture. What he strived for, was to open a (owned by him obviously) rom from his project and emulate the original GameBoy behaviour. He provided us with a ton of information on how to check the architecture and the instruction sets, how to display things in the screen with Scenic and how different Scenic is to original GameBoy (Immediate vs Retained mode). Granted, his project is far from done, but it was a very interesting talk anyway.

[![GB Emu Elixir Conf EU 2019](https://img.youtube.com/vi/7WPJDmJJqf0/0.jpg)](https://www.youtube.com/watch?v=7WPJDmJJqf0)

### Let there be light: from nothing to a running application by Michał Muskała

Going in this talk, I knew it would be out of my league. I have never tinkered with Erlang booting process, but I wanted to check a talk from another Elixir Core Team member. I was rewarded with a great talk, and even though I had _very_ little to zero knowledge about, Michał managed to keep my interests up all the time. He talked about the boot process itself and the quirks and weird stuff someone is going to discover going in if they want to contribute to the VM. As the Erlang Ecosystem Foundation grows and more and more developers join in, it would probably be a good opportunity for more advanced developers to touch on the subjects that Michał mentioned in his talk.

### Functional Concepts in Elixir by Wolfgang Loder

Wolfgang is an experienced developer who has remained a developer through his whole career, while having worked on various technologies and projects. He has also written two books. His talk is covering some functional concepts and the way they can be used in Elixir, like Pattern Matching, Higher Order Functions, Recursion, Continuation Passing and Referential Integrity. He has a really nice way to describe things, and he used some real life examples from his work to explain them better.

[![Func Concepts Elixir Conf EU 2019](https://img.youtube.com/vi/Dzi52dTOxT4/0.jpg)](https://www.youtube.com/watch?v=Dzi52dTOxT4)

### Modular design in Elixir by Maciej Kaszubowski



### From zero to Elixir deployment by Philipp Schmieder

This is one of my favorite talks this conference. Philipp introduced deployments, from start to finish. The talk had great content, but his presentation was very good as well, which made the whole package complete. He talked about a range of things, giving examples as well, from initial configuration for distillery, to otp releases and docker.

### Talk: Building resilient systems with stacking by Chris Keathley

Chris gave us a great talk, demonstrating on how to sleep well when the storm comes, a.k.a. how to build a system that can handle a failure gracefully, provide feedback to other systems and give insight to operations. In more detail, he talked about how complex systems run in degraded mode, and that scaling is a problem of handling failure. He suggested that we should use external tools and libraries to help us gain more control over our software during it's lifecycle (a couple of suggestions, his own [vapor lib for dynamic configuration](https://github.com/keathley/vapor) and [fuse, a circuit breaker for erlang](https://github.com/jlouis/fuse)). The talk was presented very well by him as well, making it a nice finish for the first conference day (for the main talks at least).

### Lightning talks

TODO: Ask Lawrence for the lightning talks titles

## Presentations - Day 2

### Keynote - illuminating the darkest of arts: effective library design by Brooklyn Zelenka

On the opening Keynote of the second day, Brooklyn brings up her [Witchcraft](https://github.com/expede/witchcraft) family of libraries to give us some context on how to build and maintain a library. I found the content to be a bit generic on context and specific on her use case, which made the talk a bit duller than expected. She did have some good points though, and her libraries look interesting to say the least, so check them out.

### Lessons From our first trillion messages with Flow by John Mertens

John on his talk give a real life example on how they have used Flow extensively in their company to process a trillion messages. This talk is also connected with the announcement of Broadway, as currently John and his team are converting their Flow pipeline to Broadway. There are some great tips and tricks given (like how to keep your flow simple and organized, how to use it with the SQS visibility window and ACK etc), so if you have a similar use case, check his talk.

### Ecto without SQL by Guilherme de Maio

### Exploiting PostgreSQL's power with Elixir and Ecto applications by José San Gil

José gave a talk on how to move the access management from your code to the database, using Roles and Privileges, which would lead to writing authorization with smaller complexity in your codebase.

### Telemetry ...and metrics for all by Arkadiusz Gil

Arkadiusz's talk was about Telemetry, a dynamic dispatching library used for metrics and instrumentations. He gave some insights on how the library can be injected in an app and help the engineers get various metric data on certain events occuring. Telemetry is already working with Ecto, and is coming to Phoenix in 1.5, so be sure to check this talk when available online!

[![Telemetry Elixir Conf EU 2019](https://img.youtube.com/vi/cOuyOmcDV1U/0.jpg)](https://www.youtube.com/watch?v=c0uy0mcDV1U)

### Elixir down under - how Elixir is driving Australian product innovation by Sophie Troy

Sophie gave a talk about another Elixir success story. She demonstrated how her company incorporated Elixir, GraphQL and React / React Native for their platform [Vamp](https://vamp-brands.com/). Really well performed talk, but not much to take besides the success story.

### A whirlwind tour of testing in Elixir by Daniel Caixinha

Danile gave an all around talk about testing, giving some tips and tricks, initially talking about the different schools of TDD (Detroit and London), going on with some principles on mocking, and also mentioning some external tools like Bypass, Hound and Wallaby.

### Keynote by Chris McCord

This is the talk everyone has been waiting for in this conference. It's LiveView man! Last year, I looked around me and saw that people greeted this lib with a bit of scepticism. I guess one more year of them working on JS, made them think again. As always, Chris did a stellar job on presenting his work, giving us some live demos and examples to make us more excited, and he also showed us a bunch of his own to demonstrate the functionality.

As a personal note of me being so excited though, I have to say this: we should help him with this library as much as we can, we cannot simply offload our JS duties to one person and expect this to end well. So go visit [the LiveView repo](https://github.com/phoenixframework/phoenix_live_view), give him your support, and go help with them issues.

[![Phoenix Live View](https://img.youtube.com/vi/8xJzHq8ru0M/0.jpg)](https://www.youtube.com/watch?v=8xJzHq8ru0M)

## Erlang Ecosystem Foundation

As they did in CODE BEAM SF conference, also here we have the presentation of the Erlang Ecosystem Foundation. They stated again that things are still a little blurry, and we will probably have more information in the following period, but check out the video of the presentation just to know what's coming.

## Conclusion

Overall, year over year, it was a better conference. I gained at least some small fraction of intel from all talks, but letting again Chris close the conference was a wise decision. The talks did have better content than last year, and I honestly enjoyed the lightning talks as well.

TODO: write more here after receiving feedback from lawrence

## R.I.P Joe Armstrong
