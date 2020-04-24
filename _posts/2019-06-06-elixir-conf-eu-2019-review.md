---
author: George Mantzouranis
author_link: https://github.com/gemantzu
categories: review
date:   2019-06-06
layout: post
title:  Reviewing Elixir Conf EU 2019
excerpt: >
  ElixirSchool was invited to participate in a conference for the first time! Our own @gemantzu was there, and has a lot to say!
---

Last year, it was my first time ever participating in the conference. I wanted to go off and see what this community had to offer me, as Elixir is the first language I have seriously considered working with as a professional. So, 2019 being my second back-to-back participation, I think can provide a direct comparison on how things have fared in our European join.

## Sponsored Ticket

From the beginning, we would like to thank ElixirConfEU, Erlang Solutions and Lawrence Ansell in particular for giving us the opportunity to write a review on the conference by providing us with a two-day free ticket. Just as an FYI, we were never asked to be biased in our conference review, and as always, I will try to make it as objective as I can.

## The City

This year, the conference was held in the magnificent city of Prague, the capital of the Czech Republic. The city is marvelous, one of the most complete experiences I have ever had visiting a city. It was nothing compared to Warsaw, which due to the WWII destruction and later reconstruction, had a much more modern look. Prague is full of big old buildings, with a ton of marvels to invest your time in. You can enjoy old time experiences, from the Old Town Square, to the Royal Castle, and newer ones, from the Lego Museum to the Gallery of Steel Figures. The metro of the city helped a lot, as you can jump in and find your way pretty easily around the city.

## Conference Logistics

Just like last year, the conference organizers and attendees made heavy use of the Whova app. Whova allows users to organize or take part in conversations and events throughout the conference. People used the app to share cabs from and to the airport, to schedule evening walks to the city, a dinner for vegetarians, lost and found items etc.

The conference took place in the Prague Congress Centre, located south of the town centre, in Praha 4. The metro station was right outside, which was very convenient, and the view from outside the centre was wonderful.

The organizers had booked two halls from the congress centre, the Forum Hall and South Hall.

Forum hall is a huge atrium hall, which could easily house all of us in one sitting. It had great visibility of both the speaker and his notes. It also had great acoustics.

South hall on the other hand, was a step down. It was much smaller, with three medium monitors where you could view the speakers’ notes. Sadly, it also had some pillars installed inside, and it was flat, which made viewing both the speaker and his notes a challenge.

From the beginning of the conference, I got to see some familiar faces from last year, which made me much more comfortable. I think the conference was more crowded this year, but we have to check with the organizers to have official stats on the attendees.

I got to talk with all of the sponsors that had a booth in the venue, which was really fun. Cultivate, solarisBank, coders51, bitcrowd, ScoutAPM, Erlang Solutions and Toyota Connected, they are doing some great stuff with Elixir and some of them are hiring as well. They were kind enough to provide us with some swag, including some very nice t-shirts and a ton of stickers! Check it out:

![IMG_20190421_155525](https://user-images.githubusercontent.com/4966172/58432840-1752fe00-80bd-11e9-83ec-e1626c35bf5a.jpg)


![IMG_20190421_154204](https://user-images.githubusercontent.com/4966172/58432844-1a4dee80-80bd-11e9-962e-8a0eb2db059d.jpg)

## Review

Overall, year over year, it was a better conference. I dare say I learned something from each of the talks and again, letting Chris close the conference was a wise decision as he always gives fantastic talks. The talks did have better content than last year, and I honestly enjoyed the lightning ones at the end of the first day as well.

Was everything perfect? No. We as a community have some work to do on giving presentations, this is a part where we can learn a lot from our Ruby colleagues. I think that many people that stand up there feel like they should bombard us with information––a lot of slides with a ton code. This is the job of a tutorial, or a training session, not a presentation.

If you ask me, this stands in the way of having the best conference possible. What should we do? I think that everyone that is going to stand up there should nail it down to a couple of things that they would want to transfer to the audience, and build around them. What's the magic number? Probably less than five key points should be enough to work on, and not too much to overwhelm the attendees. Remember, over a couple of days a person will watch more than 20 presentations.

We should also find ways to collaborate more during this couple of days. The conference people could dedicate an hour or two to let attendees join small groups and work together on some small open source project, so they can get to know each other as well.

## Presentations

Like last year, the presentations had a very wide variety of content. You could find literally anything.

### Keynote - announcing Broadway by José Valim

As always, José did a fantastic job on his presentation, leading us down the path of Broadway creation.

He started explaining what were his initial goals of the language regarding collections, making them  polymorphic, extensible / open to change, general (in memory and via resources) and tunable. Tunable was the ultimate goal, where he gradually wanted to make Elixir collections go from Eager to Lazy to Concurrent to Distributed. Eager and Lazy were available to us from 1.0 with Enum and Stream modules, while concurrent came later via GenStage and Flow.

After that, instead of going directly for a distributed solution, they waited a while to see where the community would lead them with their use cases. Analyzing those use cases, they came up with Broadway, which is an external library for concurrent and multi-stage data ingestion and processing.

What someone can expect from Broadway is back-pressure and concurrency, automatic ack at the end of the pipeline, fault-tolerance with minimal data loss (for example if a node goes down if you are doing something crazy), graceful shutdowns, batching and partitioning out of the box. There are a couple of available Producers (Amazon SQS and RabbitMQ), which means there is still room for development in that area.

[![Keynote: Announcing Broadway Elixir Conf EU 2019](https://img.youtube.com/vi/IzFmNQGzApQ/0.jpg)](https://www.youtube.com/watch?v=IzFmNQGzApQ)

### Keynote: Phoenix LiveView - Interactive, Real TIme Apps - No need to write Javascript by Chris McCord

Chris is one of my favorite speakers in this community. His presentations are always fun to watch, have great content and often use a live demo to make things more interesting. This year, his LiveView talk was expected from most of the attendees, and he certainly did not leave anyone complaining.

He started off by showing us some demos of LiveView that the community has come up with, some of which are games! He went on describing where the technology shines, which is in an app that requires some simple real time functionality, most of which can be handled by server-rendered HTML. Then, he showed us an example application, a live thermostat, and we got to see how the library actually works.

We were shown how the library gets to be lightweight both on the server and on the client, leveraging the power of Elixir, and also, how every component is supervised and can be brought back up upon crashing.

We also learned that the library is not going to affect SEO, as the initial load of the component is treated as standard HTML. It is also really easy to test LiveView and it is really not necessary to do testing with headless browser launching etc.

[![Phoenix Live View](https://img.youtube.com/vi/8xJzHq8ru0M/0.jpg)](https://www.youtube.com/watch?v=8xJzHq8ru0M)

### Live coding an Escher painting using Scenic by Ju Liu

Ju Liu gave a very good talk about how to draw a simplified version of Escher's fish painting using vectors, a fish image and scenic. The talk had not much to do with Scenic––it was more about Vector theory and how to use small graphic assets to compose more complex structures.

He started showing how to bring a simple screen up with Scenic, then he discussed the basics of Vectorial Algebra and how to draw simple vectors on screen and scale them, moving on to describe how the Box Model works with vectors.

The rest of the talk is all about how, by leveraging the Box Model with a picture of a fish in it, and constantly building more copies of it, rotating it, scaling it and putting it on screen, you can produce a simplified version of that painting.

[![](https://img.youtube.com/vi/sV5ValgY4ck/0.jpg)](https://www.youtube.com/watch?v=sV5ValgY4ck)

### Rewriting critical software in Elixir - a case study by Renan Ranelli

Renan Ranelli gave us some very insightful information on how to rewrite critical software in Elixir while the old system is still a moving target. Renan works in Telnyx, an IP Telephony company, where their old python system was slowing down in development due to tech debt.

He began giving us some small insight on how IP telephony works, and the functionality of their Dialplan service that was up for a rewrite. That service is almost stateless, super latency sensitive and had relatively low throughput for each server. The service produced an xml file, with all the information the switch needs to to operate on a call. 

The first step in the case study was getting buy-in from stakeholders by convincing them that the company needs to slow down feature development to pay technical debt, which they accomplished phrasing all the benefits in business terms. The next step was to commit resources, which is very critical as a rewrite is a huge amount of work when you are chasing a moving target. Another step is to write and deploy continuously.

What Telnyx did was run the new service along the old one, put a proxy in front of them that directed the traffic to both of them and logged the request, and both of their responses to a database. That way, Telnyx was able to make the final step––verifying feature parity–– finding disparities in the responses, fixing them, writing a regression test for that disparity to guard against it in the future, and iterating on those fixes with the help of TDD and rewrite / clean code, in a “TDD-ish” cycle of them that looks really close to the regular TDD one. 

The outcome of this process was near zero incidents after the cutover to the new service, a better runtime with a 100% Elixir codebase, a huge improvement in observability (for example via wobserver), new features shipping faster, and parallelization made ridiculously cheap and simpler all of which led to more happy customers. 

[![](https://img.youtube.com/vi/WocZIc4mPxs/0.jpg)](https://www.youtube.com/watch?v=WocZIc4mPxs)

### Building a GameBoy emulator with Elixir and Scenic by Tonći Galić

Ok, I admit it, I am an old geezer, a true fanatic of the first GameBoy and that's why I went to Tonći Galic's talk.

He gave us some insight on how to reverse engineer and tinker with a dedicated machine architecture. What he strived for, was to open a (owned by him obviously) rom from his project and emulate the original GameBoy behaviour.

He provided us with a ton of information on how to check the architecture and the instruction sets, how to display things in the screen with Scenic and how different Scenic is to original GameBoy (Immediate vs Retained mode).

Granted, his project is far from done, but it was a very interesting presentation anyway.

[![GB Emu Elixir Conf EU 2019](https://img.youtube.com/vi/7WPJDmJJqf0/0.jpg)](https://www.youtube.com/watch?v=7WPJDmJJqf0)

### Let there be light: from nothing to a running application by Michał Muskała

I have never tinkered with Erlang booting process, but I wanted to check a talk from another Elixir Core Team member. I was rewarded with a great talk, and even though I had little to zero knowledge about all the steps an Erlang application takes before it even touches your code, Michał managed to keep my interests up all the time.

He talked about the boot process itself and the quirks and weird stuff someone is going to discover going in if they want to contribute to the VM. As the Erlang Ecosystem Foundation grows and more and more developers join in, it would probably be a good opportunity for more advanced developers to touch on the subjects that Michał mentioned in his talk.

[![From nothing to a running app Elixir Conf EU 2019](https://img.youtube.com/vi/_AgmxltiV9I/0.jpg](https://www.youtube.com/watch?v=_AqmxltiV9I)

### Functional Concepts in Elixir by Wolfgang Loder

Wolfgang is an experienced developer who has worked on a variety of technologies and projects. He has also written two books. His talk covered some functional concepts and the way they can be used in Elixir, like Pattern Matching, Higher Order Functions, Recursion, Continuation Passing and Referential Integrity. He has a really nice way of describing things, and he used some real life examples from his work to explain them well.

[![Func Concepts Elixir Conf EU 2019](https://img.youtube.com/vi/Dzi52dTOxT4/0.jpg)](https://www.youtube.com/watch?v=Dzi52dTOxT4)

### Building resilient systems with stacking by Chris Keathley

Chris, a developer that currently works on Bleacher Report, closed the first day (besides lightning talks), demonstrating on how to sleep well when the storm comes, a.k.a. how to build a robust system that can handle a failure gracefully, provide feedback to other systems and give insight to operations.

He began his talk saying complex systems run in degraded mode, and that scaling is a problem of handling failure. The cogs of the stacked design mentioned in the title, were all part of things you can do before your application starts: booting the runtime and configuration, starting dependencies, connecting to external systems, having alarms setup and showing feedback to us, and communicating with services we don’t control. 

About booting, he talks about how we should avoid having runtime configuration done via Mix, and how to configure our application via a Config module that is supervised and starts with our app.

Regarding starting dependencies, he showcased how we can have a load balancer in front of our application, and our application can have an `UpController` where the balancer can check if the application has everything booted up completely or not.

Then, regarding connections to external systems, he demonstrated how our database connections should always start in disconnected mode, as `Supervisors are about guarantees - Fred Hebert`, meaning that when we start our application, the database might for some reason be unavailable or loaded, so we should use a module which would check if the database is available, and then start having real traffic.

Regarding alarms, in case for example the previous issue occurs where we can’t control to the database, the system should provide feedback to the operators, by raising an alarm. This can work by having a watchdog process which constantly monitors the database status and toggle an alarm based on it. 

Lastly, he talked about how our system should handle failure with external services by using circuit breakers (like [Fuse, a circuit breaker for erlang](https://github.com/jlouis/fuse)). This can depend on a per application basis, but we could always have a write-through cache, which means that you can write the last good external service response to an ETS table, which in case the downstream service is down, we can provide to the end user. 

He closed his talk by saying that, by solving all those potential issues before hand, we can prevent a ton of issues happening in the future, that we have really powerful tools in our runtime, and we should take advantage of them to build more robust systems.

[![](https://img.youtube.com/vi/lg7M0h9eoug/0.jpg)](https://www.youtube.com/watch?v=lg7M0h9eoug)

### Lessons From our first trillion messages with Flow by John Mertens

John on his talk give a real life example on how they use Flow in Change.org to process a ton of messages stored in SQS. They have a Ruby/JS website where people’s actions produce and store messages in SQS, which are then processed by their Elixir / Flow system. 

The 3 lessons they have learned, are the following:

1) Let Flow do the work
2) Organize your Flow
3) Tune your Flow

In Lesson 1, we learn about GenStage / Flow and how their amazing features can help with a big long running system like that. Parallelism is made easy, and by using Flow, you are protected from DDoSing yourself, because instead of pushing from one system to another via stream, now you pull as many messages as you can get.

In Lesson 2, John talked about how one should know their system pretty well, so that they can provide the correct configuration to it. For example, by using SQS, you are limited to receiving batches of 10 messages each time, so you have to build around that. Another useful tip is to use a token, meaning a struct that gets pushed down through the whole system, changed at each step, which makes processing and pattern matching on messages really easy (it’s the same thing that Plug uses with it’s Conn struct). Errors are supposed to be passed through the whole flow, and left out of acknowledgement, so SQS will resend them, and you can process them again.

In Lesson 3, he spoke about how every system is different and there is no magic solution to fine tuning your app, how under the hood Flow breaks a flow into 3 sections of GenStages, producers, producers_consumers and consumers  and how one can toy with :max_demand argument in all these different sections to get a better result.

As a bonus, we get to see how they have been already playing with Broadway, and how easy to swap it in instead of Flow, along the differences that they have as systems.

[![flow](https://img.youtube.com/vi/t46L9RKmlNo/0.jpg)](https://www.youtube.com/watch?v=t46L9RKmlNo)

### Telemetry ...and metrics for all - ElixirConf EU 2019 by Arkadiusz Gil

Arkadiusz Gil's talk was about Telemetry, a dynamic dispatching library used for metrics and instrumentations.

He started by talking about monitoring, and how crucial it is to improving performance. The goal is to use monitoring early on in the lifecycle of our project (as we have done already with testing and deployment), so we can use it as another form of verification. Next, he showed us how we can do metrics today, using custom functions (like the number of requests, the number of successful responses, how big a load we are pushing to external systems like the the database, how to track memory or cpu usage from the vm etc). 

But as we add more and more, this custom set up becomes repetitive. Telemetry uses events emitted from various parts of our systems, and then attaches to those events by using handlers, which are in turn pushed to a reporter system like statsd. 

A Telemetry event consists for three parts, the event name, the measurements (measurable properties like payload) and some metadata. Various libraries are beginning to add support for Telemetry emitting events in them, like Ecto from v3.1, Phoenix from v1.5 and Plug from 1.8. Arkadiusz also showed us `Telemetry.Poller` which every couple of seconds picks some metrics from the BEAM and emits them as Telemetry events and `Telemetry.Metrics` which allows us to specify how telemetry events are aggregated over time. Some examples of metrics is `last_value`, `sum`, `counter` and `distribution` which gives us some insight into statistics. 

Lastly, he demonstrated the way you can plug Telemetry into a project by using the Rumble application from the Phoenix Programming book. It is as simple as adding the dependencies in `mix.exs`, making a custom module that defines which metrics we want, supervising it in `application.ex` and we are good to go from the application standpoint. The difficult part is setting up the reporter, like statsd, but there is going to be one included in Phoenix as well, where we will be able to access it from a route.

[![](https://img.youtube.com/vi/cOuyOmcDV1U/0.jpg)](https://www.youtube.com/watch?v=cOuyOmcDV1U)

## Erlang Ecosystem Foundation

As they did in CODE BEAM SF conference, we were given the presentation on the new [Erlang Ecosystem Foundation](https://erlef.org/). They stated again that things are still a little blurry, and we will probably have more information in the coming months, but check out the video of the presentation just to know what's coming.

## Not nearly done

These were not all the talks of the conference, there were a few more, which you can check out on the [Code Sync](https://www.youtube.com/channel/UC47eUBNO8KBH_V8AfowOWOw) Youtube channel. Kudos to them for organizing a great conference, if you are located in Europe you can check all the other conferences they host in [their website](https://codesync.global/).
