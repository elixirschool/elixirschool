%{
  author: "Sophie DeBenedetto",
  author_link: "https://github.com/sophiedebenedetto",
  date: ~D[2019-09-08],
  tags: ["conferences", "general"],
  title: "Dispatch From ElixirConf 2019",
  excerpt: """
  We had a great time at ElixirConf 2019! Hear about Elixir School's two workshops, along with the highlight talks and activities that we enjoyed this year.
  """
}

---

This year's ElixirConf, in Colorado, really reflected the growing and thriving nature of the Elixir community. It was a jam-packed two days of workshops and two days of multi-track talks that showcased the increasingly diverse and innovative people and technologies that Elixir has to offer.

## The Workshops

This year, Elixir School was thrilled to be offering two days of ElixirConf workshops. The goal of both workshops was to guide participants through building their very own real-time app––a ticket estimation tool we're calling Pointing Party––using Phoenix's real-time offerings. On day one, we built out Pointing Party with the help of Phoenix Channels and Presence, and learned how Phoenix leverages WebSockets along the way. On day two we built out the same set of features, this time using Phoenix LiveView, PubSub and Presence. We capped it all off with a look at property-based testing with StreamData.

It was truly a pleasure to work with such a curious, dedicated and friendly group of students over the course of these two days. Thanks to everyone who signed up and participated! We had a great time teaching and we were challenged in turn by the interesting questions and approaches of everyone involved. A special shout out to our handful of participants who were brand new to Elixir and dove right into complex Phoenix concepts––successfully building out our application features by the end of the day and pushing and supporting the people around them with their open attitudes and fresh perspectives.

If you'd like to learn more about these workshops, you can check out the code and slide deck for day one, as well as the code and slide deck for day two below.

* Day 1: Harnessing the Real-Time Web with Phoenix, Channels, and Presence
  * [Slide deck](https://speakerdeck.com/sophiedebenedetto/harnessing-the-real-time-web-with-phoenix-channels-plus-presence)
  * Complete code
* Day 2: Building Bulletproof Real-Time Applications with Phoenix, LiveView, and StreamData
  * [Slide deck](https://speakerdeck.com/sophiedebenedetto/building-bulletproof-real-time-apps-with-phoenix-liveview-plus-stream-data)
  * [Complete code for LiveView features](https://github.com/elixirschool/pointing-party/tree/live-view-js-hooks)
  * [Complete code for Property-based testing features](https://github.com/elixirschool/pointing-party/tree/test-vote-calculation-with-stream-data)


## Talks We Enjoyed

There were so many exciting talks to check out, but with a multi-track schedule, we sadly couldn't catch them all. Here are a few that stood out to us in particular.

### Jose Valim's Thursday Evening Keynote

Just because Elixir is now feature-complete doesn't mean that the core team doesn't have some exciting and ambitious goals for the next year! Jose discussed the present and future of `Mix.Config`, including some thoughts on build time vs. run time configuration. He also made an exciting announcement--Phoenix 1.5 will ship with a native Telemetry module that makes it easy to configure your app's Telemetry metrics and report them to the third party service of your choosing (New Relic, Statsd, etc.). The Elixir community can expect a new version of Elixir released every six months. One feature that we're excited for is ExUnit pattern diffing––making it easy to see exactly *what* doesn't match when ExUnit tells you that your match failed. Learn more about the future of Elixir by checking out the full talk [here](https://www.youtube.com/watch?v=oUZC1s1N42Q).

### Chris McCord's Friday Evening Keynote: LiveView in the Wild

This past year, Chris McCord and other core Phoenix maintainers gave us LiveView––a technology for writing rich, real-time UX with server-rendered HTML. Here, Chris walks us through the powerful features of LiveView and gives us a look at how it behaves "in the wild", especially compared to traditional SPAs (Single Page Applications). LiveView's first release contains a set of exciting and powerful features––including JavaScript hooks, Live navigation and LiveView test. Learn more about this incredibly powerful set of tooling by checking out the full talk [here](https://www.youtube.com/watch?v=XhNv1ikZNLs).  

### Contracts for Building Reliable Systems - Chris Keathley

Chris Keathley's talk asked the question: "How can we build systems that withstand change?", and answered it with his new library, [Norm](https://github.com/keathley/norm). Norm was developed in response to the challenges that many of us face coordinating across teams and services and ensuring that we don't break APIs while encouraging and allowing for growth. By embracing contract-driven design with the help of the [ExContract](https://hexdocs.pm/ex_contract/readme.html) testing library, and by leveraging Norm to enforce data specification, we can embrace change and mitigate breakage. Learn more about how Elixir tooling helps us promote contract-driven design for distributed architecture by checking out the full talk [here](https://www.youtube.com/watch?v=tpo3JUyVIjQ).

### Elixir + CQRS - Architecting for Availability, Operability, and Maintainability At PagerDuty - Jon Grieman

Learn about how Pager Duty builds systems that are more reliable than your most reliable app with the help of CQRS patterns. Jon Grieman talks us through Pager Duty's refactor of a Rails monolith into an Elixir umbrella app backed by Kafka and lays out why Elixir and CQRS are such a good fit. Check out the full talk [here](https://www.youtube.com/watch?v=-d2NPc8cEnw).


## Activity Highlights

We also had a great time getting to know other conference participants through the official and unofficial activities planned over the course of the four days. Participants where encouraged to use the Whova app to coordinate meetups. Some people organized morning runs and walks around the sprawling hotel and others planned everything from meetup discussions on scaling Elixir apps to evening wine tastings. The hotel itself, The Gaylord Rockies Resort and Convention Center, offered several different restaurants and cafes, walking paths and an indoor/outdoor pool with a lazy river. Conference attendees took full advantage of all the hotel had to offer and more––with the Elixir Outlaws podcast organizers setting up a lazy river meet-and-greet, Smart Logic's happy hour with ClusterTruck at a nearby brewery and EMPEX's Friday evening get-together.

Overall, the conference was well-organized, ran smoothly and was fun, welcoming and full of exciting things to learn and people to meet. Hope to see you there next year!
